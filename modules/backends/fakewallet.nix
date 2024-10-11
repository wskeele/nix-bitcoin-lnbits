{ pkgs, config, lib, ... }@args:
let
  inherit (lib) mkOption mkIf types;
  cfg = config.services.lnbits;
in
{
  options.services.lnbits.FakeWallet = {
    secretFile = mkOption {
      type = types.path;
      description = "Path to file containing FakeWallet secret";
      example = ''
        # This is very insecure
        builtins.toFile "fakeWalletSecret" "ToTheMoon";
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "FakeWallet") {
    systemd.services.lnbits = {
      serviceConfig.LoadCredential = [
        "fakeWalletSecret:${cfg.FakeWallet.secretFile}"
      ];
      environment.FAKE_WALLET_SECRET = "%d/fakeWalletSecret";
    };
  };
}
