{ pkgs, config, lib, ... }@args:
let
  cfg = config.services.lnbits;
  clightning = config.services.clightning;
in
{
  config = lib.mkIf (cfg.backend == "clightning") {
    services.lnbits.env = {
      LNBITS_BACKEND_WALLET_CLASS = "CoreLightningWallet";
      CORELIGHTNING_RPC = "${clightning.dataDir}/bitcoin/lightning-rpc";
    };
    users.users.lnbits.extraGroups = [ "clightning" ];
    nix-bitcoin.netns-isolation.services.lnbits.connections = [ "clightning" ];
    systemd.services.lnbits.after = [ "clightning.service" ];
  };
}
