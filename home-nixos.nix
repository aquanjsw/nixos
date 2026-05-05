{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    inherit inputs;
    args = { inherit (config) user limited; };
  };
  home-manager.users.${config.user} = ./home.nix;
}
