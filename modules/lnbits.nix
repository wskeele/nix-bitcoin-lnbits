{ pkgs, config, lib, ... }@args:
let
  cfg = config.services.lnbits;
  nbPkgs = config.nix-bitcoin.pkgs;
  nbLib = config.nix-bitcoin.lib;
  torSocket = config.services.tor.client.socksListenAddress;
  torEnvs = (import lib/torsocks.nix { inherit pkgs torSocket; }).systemdEnvs;
in
{
  imports = [
    ./backends/clightning.nix
    ./backends/lnd.nix
    ./backends/fakewallet.nix
  ];

  options.services.lnbits = {
    tor = nbLib.tor;

    backend = lib.mkOption {
      type = with lib.types; nullOr (enum [
        "VoidWallet"
        "FakeWallet"
        "CoreLightningWallet"
        "CoreLightningRestWallet"
        "LndWallet"
        "LndRestWallet"
      ]);
      default = "VoidWallet";
      description = ''
        Lightning backend to use.
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
    (lib.mkIf (cfg.enable) {
      services.lnbits = {
        package = lib.mkOverride 900 nbPkgs.lnbits;
        env = {
          LNBITS_ADMIN_UI = lib.boolToString cfg.adminUI.enable;
          LNBITS_NODE_UI = lib.boolToString cfg.nodeUI.enable;
          LNBITS_PUBLIC_NODE_UI = lib.boolToString cfg.nodeUI.public.enable;
          LNBITS_NODE_UI_TRANSACTIONS = lib.boolToString cfg.nodeUI.enableTransactions;
          LNBITS_BACKEND_WALLET_CLASS = cfg.backend;
        } //
        (lib.optionalAttrs (cfg.tor.proxy) torEnvs);
      };
      systemd.services.lnbits = {
        serviceConfig =
          nbLib.defaultHardening //
          nbLib.allowedIPAddresses cfg.tor.enforce // {
            MemoryDenyWriteExecute = false; # Causes FFI to crash with pynostr if enabled
            ReadWritePaths = [ cfg.stateDir ];
          };
      };
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
