{ self, nix-bitcoin, nbPkgs, pkgs }:
let
  inherit (nbPkgs) makeTest;
  nbScenarios = nix-bitcoin.lib.test.scenarios;

  modules.base = ({ pkgs, lib, ... }: {
    imports = [ self.nixosModules.default ];
    services.lnbits = {
      enable = true;
      nodeUI.enable = true;
      nodeUI.public.enable = true;
    };
    tests.lnbits = true;
    test.extraTestScript = builtins.readFile ./tests.py;
  });
  modules.fakeWallet = ({ pkgs, lib, ... }: {
    services.lnbits = {
      backend = "FakeWallet";
      FakeWallet.secretFile = builtins.toFile "fakeWalletSecret" "ToTheMoon";
    };
  });
  modules.clightning = ({ pkgs, lib, ... }: {
    services.clightning = {
      extraConfig = ''
        alias=clntest
        rgb=123456
      '';
      enable = true;
    };
    services.lnbits.backend = "CoreLightningWallet";
    tests.lnbits-clightning = true;
  });
  modules.lnd = ({ pkgs, lib, ... }: {
    services.lnd.enable = true;
    services.lnbits.backend = "LndWallet";
    tests.lnbits-lnd = true;
  });
  modules.lndrest = ({ pkgs, lib, ... }: {
    services.lnd.enable = true;
    services.lnd.extraConfig = ''
      alias=lndtest
      color=#123456
    '';
    services.lnbits.backend = "LndRestWallet";
    tests.lnbits-lndrest = true;
  });
in
{
  default = makeTest {
    name = "lnbits-default";
    config.imports = [
      modules.base
    ];
  };

  fakeWallet = makeTest {
    name = "lnbits-fakeWallet";
    config.imports = [
      modules.base
      modules.fakeWallet
    ];
  };

  clightning = makeTest {
    name = "lnbits-clightning";
    config.imports = [
      modules.base
      modules.clightning
    ];
  };

  clightning-netns = makeTest {
    name = "lnbits-clightning-netns";
    config.imports = [
      modules.base
      modules.clightning
      nbScenarios.netnsBase
    ];

    config.nix-bitcoin.nodeinfo.enable = true;
  };

  lnd = makeTest {
    name = "lnbits-lnd";
    config.imports = [
      modules.base
      modules.lnd
    ];
  };

  lnd-netns = makeTest {
    name = "lnbits-lnd";
    config.imports = [
      modules.base
      modules.lnd
      nbScenarios.netnsBase
    ];
    config.nix-bitcoin.nodeinfo.enable = true;
  };

  lndrest = makeTest {
    name = "lnbits-lndrest";
    config.imports = [
      modules.base
      modules.lndrest
    ];
  };

  lndrest-netns = makeTest {
    name = "lnbits-lndrest";
    config.imports = [
      modules.base
      modules.lndrest
      nbScenarios.netnsBase
    ];
    config.nix-bitcoin.nodeinfo.enable = true;
  };

  netnsRegtest = makeTest {
    name = "lnbits-netns-regtest";
    config = {
      imports = [
        modules.base
        nbScenarios.regtestBase
        nbScenarios.netnsBase
      ];

      nix-bitcoin.nodeinfo.enable = true;
    };
  };
}
