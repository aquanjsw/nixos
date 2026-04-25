{ config, lib, inputs, ... }: {

  imports = [
    inputs.agenix.nixosModules.default 
    ./hardware-configuration.nix
  ];

  config = {

    zramSwap.memoryPercent = 100;
    
    tunnel.server.enable = true;

    caddy.baseDomain = config.age.secrets.bwh-domain.path;

    networking.hostName = "bwh";

    nix.settings.substituters = [ "https://cache.nixos.org" ];

    boot.loader.grub.device = "/dev/sda";
    boot.loader.grub.enable = true;

    system.stateVersion = "25.11";
  };
}

# vim: sts=2 sw=2 et ai
