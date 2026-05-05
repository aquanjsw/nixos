{
  description = "Rag's Nix Config";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    ssh-keys.url = "https://github.com/aquanjsw.keys";
    ssh-keys.flake = false;

    web-server.url = ./web-server;
    web-server.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = inputs@{
    self,
    nixpkgs,
    ...
  }: let

    commonModule = {
      lib,
      ...
    }: {

      options = {

        user = lib.mkOption {
          default = "rag";
          readOnly = true;
        };

        paths = lib.mkOption {
          default = {
            secrets = ./secrets;
          };
          readOnly = true;
        };

        limited.enable = lib.mkOption {
          default = false;
          description = "Whether the system is limited in resources.";
        };

        domain = lib.mkOption {
          default = "zaelggk.com";
          readOnly = true;
        };

      };

      config.nixpkgs.overlays = import ./overlays.nix;
      config.nixpkgs.config.allowUnfree = true;

    };

    hosts = [
      "bwh"
      "lib5"
      "minimal"
    ];

    mkNixos = host: nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        inputs.web-server.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        commonModule
        ./home-nixos.nix
        ./modifiedOfficialModules
        ./nixosCommonModule
        ./hosts/${host}/configuration.nix
      ];
    };

    mkHome = system: inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = { inherit inputs; args = {}; };
      modules = [
        commonModule
        ./home.nix
      ];
    };

  in {

    nixosConfigurations = nixpkgs.lib.genAttrs hosts (host: mkNixos host);

    homeConfigurations = {
      agx = mkHome "aarch64-linux";
    };

  };
}

# vim: sts=2 sw=2 et ai
