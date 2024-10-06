nix-bitcoin lnbits extension
---
This repo contains an extension for the [nix-bitcoin](https://github.com/fort-nix/nix-bitcoin) project, adding support for hosting an lnbits instance with support for several backend wallets.

Status
---

This repository is a work in progress, for current todo list see, [TODO.md](https://github.com/wskeele/nix-bitcoin-lnbits/blob/master/TODO.md)

Currently supports the following backends:
- clightning
- lnd
- lndrest

Installation
---

At the moment, installation is only supported via flakes. See [nix-bitcoin documentation](https://github.com/fort-nix/nix-bitcoin/blob/master/README.md) for information on setting up a flake-based node with nix-bitcoin.

To add the nix-bitcoin-lnbits extension:

1. Add the following input into your flake.nix:

```nix
nix-bitcoin-lnbits = {
    url = "github:wskeele/nix-bitcoin-lnbits";
    inputs.nix-bitcoin.follows = "nix-bitcoin";
};
```

2. Include the default modules into the system configuration:

```nix
nix-bitcoin-lnbits.nixosModules.default
```

3. Enable lnbits in configuration.nix.

Example configuration:

```nix
  services.lnbits = {
    enable = true;
    backend = "clightning";
    adminUI.enable = true;
    nodeUI.enable = true;
    nodeUI.enableTransactions = true;
    tor.proxy = true;
    tor.enforce = true;
  };
```
