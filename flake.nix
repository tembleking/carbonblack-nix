{
  description = "Carbon Black Cloud Sensor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      overlays.default = final: prev: {
        cbagentd-unwrapped = prev.callPackage ./unwrapped.nix { };
        cbagentd = prev.callPackage ./package.nix { };
      };

      packages.${system} = {
        inherit (pkgs) cbagentd cbagentd-unwrapped;
        default = pkgs.cbagentd;
      };

      nixosModules.cbagentd = pkgs.callPackage ./module.nix { };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
