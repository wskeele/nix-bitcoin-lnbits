{ pkgs, config, lib, ... }@args:
let
  cfg = config.services.lnbits;
  lnd = config.services.lnd;
in
{
  config = lib.mkIf
    (
      cfg.enable &&
      (
        cfg.backend == "LndWallet" ||
        cfg.backend == "LndRestWallet"
      )
    )
    {
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
    };
}
