{
  description = "Rag's NixOS Flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    web-server.url = ./web-server;
    web-server.inputs.nixpkgs.follows = "nixpkgs";

    ssh-keys.url = "https://github.com/aquanjsw.keys";
    ssh-keys.flake = false;
  };

  outputs = inputs@{
    self,
    nixpkgs,
    disko,
    ...
  }: {
    nixosConfigurations = {

      minimal = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./common
          ./hosts/minimal/configuration.nix
        ];
      };

      bwh = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./common
          ./hosts/bwh/configuration.nix
        ];
      };

      lib5 = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          ./common
          ./hosts/lib5/configuration.nix
        ];
      };

    };
  };
}

# vim: sts=2 sw=2 et ai
