{ pkgs, config, lib, ... }@args:
let
  cfg = config.services.lnbits;
  nbPkgs = config.nix-bitcoin.pkgs;
  nbLib = config.nix-bitcoin.lib;
  torSocket = config.services.tor.client.socksListenAddress;
  torEnvs = (import lib/torsocks.nix { inherit pkgs torSocket; }).systemdEnvs;
  lnd = config.services.lnd;
  clightning = config.services.clightning;
in
{
  options.services.lnbits = {
    tor = nbLib.tor;

    backend = lib.mkOption {
      type = with lib.types; nullOr (enum [
        "clightning"
        "lnd"
        "lndrest"
      ]);
      default = null;
      description = ''
        Lightning backend to use. Currently only clighting via rpc is supported.
      '';
    };

    adminUI.enable = lib.mkEnableOption "Lnbits Admin UI";
    nodeUI.enable = lib.mkEnableOption "Lnbits Node UI";
    nodeUI.public.enable = lib.mkEnableOption "Lnbits Public Node UI";
    nodeUI.enableTransactions = lib.mkEnableOption "Lnbits Node UI";

    # Internal alias used by onionServices and nodeinfo
    address = lib.mkOption {
      default = cfg.host;
      internal = true;
      readOnly = true;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.lnbits = {
        package = lib.mkOverride 900 nbPkgs.lnbits;
        env = {
          LNBITS_ADMIN_UI = lib.boolToString cfg.adminUI.enable;
          LNBITS_NODE_UI = lib.boolToString cfg.nodeUI.enable;
          LNBITS_PUBLIC_NODE_UI = lib.boolToString cfg.nodeUI.public.enable;
          LNBITS_NODE_UI_TRANSACTIONS = lib.boolToString cfg.nodeUI.enableTransactions;
        } //
        (lib.optionalAttrs (cfg.tor.proxy) torEnvs);
      };
      systemd.services.lnbits = {
        serviceConfig =
          nbLib.defaultHardening //
          nbLib.allowedIPAddresses cfg.tor.enforce // {
            ReadWritePaths = [ cfg.stateDir ];
          };
      };
    })

    (lib.mkIf (cfg.backend == "clightning") {
      services.lnbits.env = {
        LNBITS_BACKEND_WALLET_CLASS = "CoreLightningWallet";
        CORELIGHTNING_RPC = "${clightning.dataDir}/bitcoin/lightning-rpc";
      };
      users.users.lnbits.extraGroups = [ "clightning" ];
      nix-bitcoin.netns-isolation.services.lnbits.connections = [ "clightning" ];
      systemd.services.lnbits.after = [ "clightning.service" ];
    })

    (lib.mkIf (cfg.backend == "lnd") {
      services.lnbits.env = {
        LNBITS_BACKEND_WALLET_CLASS = "LndWallet";
      };
    })

    (lib.mkIf (cfg.backend == "lndrest") {
      services.lnbits.env = {
        LNBITS_BACKEND_WALLET_CLASS = "LndRestWallet";
      };
    })

    (lib.mkIf (cfg.backend == "lndrest" || cfg.backend == "lnd") {
      services.lnbits.env =
        let
          cert = "${cfg.stateDir}/lnd/tls.cert";
          macaroon = "${cfg.stateDir}/lnd/lnbits.macaroon";
        in
        {
          LND_REST_ENDPOINT = "https://${lnd.restAddress}:${toString lnd.restPort}";
          LND_REST_CERT = cert;
          LND_REST_MACAROON = macaroon;
          LND_GRPC_ENDPOINT = lnd.rpcAddress;
          LND_GRPC_PORT = builtins.toString lnd.rpcPort;
          LND_GRPC_CERT = cert;
          LND_GRPC_MACAROON = macaroon;
        };
      systemd.services.lnbits.preStart = ''
        lndDir=${cfg.stateDir}/lnd
        mkdir -p $lndDir
        ln -sf /run/lnd/lnbits.macaroon $lndDir
        ln -sf ${lnd.certPath} ${cfg.stateDir}/lnd/tls.cert
      '';
      services.lnd.macaroons.lnbits = {
        user = cfg.user;
        permissions = lib.concatStringsSep "," ([
          ''{"entity":"info","action":"read"}''
          ''{"entity":"offchain","action":"read"}''
          ''{"entity":"offchain","action":"write"}''
          ''{"entity":"invoices","action":"read"}''
          ''{"entity":"invoices","action":"write"}''
          ''{"entity":"address","action":"read"}''
        ] ++ (if cfg.nodeUI.enable then [
          ''{"entity":"peers","action":"read"}''
          ''{"entity":"peers","action":"write"}''
          ''{"entity":"onchain","action":"read"}''
        ] else [ ]));
      };
      nix-bitcoin.netns-isolation.services.lnbits.connections = [ "lnd" ];
      systemd.services.lnbits.after = [ "lnd.service" ];
    })

    (lib.optionalAttrs (args.options.nix-bitcoin ? onionServices) {
      nix-bitcoin.onionServices = {
        lnbits.externalPort = 80;
      };
    })

    (lib.optionalAttrs (args.options.nix-bitcoin ? nodeinfo) {
      nix-bitcoin.nodeinfo.services = with config.nix-bitcoin.nodeinfo.lib; {
        lnbits = name: cfg: mkInfoLong {
          inherit name cfg;
          systemdServiceName = "lnbits";
          extraCode = "";
        };
      };
    })

    (lib.optionalAttrs (args.options.nix-bitcoin ? netns-isolation) (
      let
        nnsCfg = config.nix-bitcoin.netns-isolation;
      in
      lib.mkIf nnsCfg.enable {
        nix-bitcoin.netns-isolation.services = {
          lnbits = {
            id = 33;
            connections = [ ];
          };
        };

        services.lnbits.host = nnsCfg.netns.lnbits.address;
      }
    ))
  ];
}
