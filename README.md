# Carbon Black Cloud Sensor Flake

This repository contains a Nix flake for installing and running the Carbon Black Cloud Sensor on NixOS. The Carbon Black Cloud Sensor is an endpoint agent that provides security and monitoring capabilities.
This flake uses an existing Debian package, applies necessary patches, and sets up a systemd service to manage the sensor.

## Installation

### Add the flake to your NixOS configuration

Add the flake to your `flake.nix` configuration file in the inputs and the config:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cbagentd = {
      url = "github:tembleking/carbonblack-nix";  # <- Add this input
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, cbagentd }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          cbagentd.nixosModules.cbagentd   # <- Add this module config
        ];
      };
    };
  };
}
```

### Configure the service

Add the following to your NixOS configuration file (usually `configuration.nix`):

```nix
{
  services.cbagentd = {
    enable = true;
    code = "your-registration-code";
  };
}
```

Replace `"your-registration-code"` with your actual registration code.

### Rebuild your NixOS system:

```bash
sudo nixos-rebuild switch
```

This command will rebuild your system configuration and start the Carbon Black Cloud Sensor service.

