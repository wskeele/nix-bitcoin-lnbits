{
  description = "A very basic flake";

  inputs = {
    lnbits.url = "github:lnbits/lnbits";
    nix-bitcoin.url = "github:fort-nix/nix-bitcoin";
  };

  outputs = { self, lnbits, nix-bitcoin }:
    let
      inherit (nix-bitcoin.inputs) nixpkgs flake-utils;
      mkLnbits = pkgs: lnbits.packages.${pkgs.stdenv.hostPlatform.system}.lnbits;
    in
    {
      lib = {
        inherit nix-bitcoin;
      };

      nixosModules.default = { pkgs, ... }: {
        imports = [
          "${lnbits}/nix/modules/lnbits-service.nix"
          ./modules/lnbits.nix
        ];
        nix-bitcoin.pkgOverlays = (super: self: {
          lnbits = mkLnbits pkgs;
        });
      };
    } // (flake-utils.lib.eachSystem nix-bitcoin.lib.supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nbPkgs = nix-bitcoin.legacyPackages.${system};
      in
      {
        checks = import ./tests/tests.nix { inherit self nix-bitcoin nbPkgs pkgs; };
        packages.lnbits = mkLnbits pkgs;
      }
    ));
}
