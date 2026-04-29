{ config, pkgs, lib, ... }: {

  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  tunnel.client.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  nix.settings.substituters = [ "https://cache.nixos-cuda.org" ];
  nix.settings.trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];

  fileSystems."/data" = {
    device = lib.mkForce "/dev/bcache0";
    fsType = "xfs";
    options = [ "nofail" ];
  };
  boot.initrd.services.lvm.enable = true;
  boot.initrd.availableKernelModules = [ "bcache" ];

  networking.hostName = "lib5";

  system.stateVersion = "25.11";
}

# vim: sts=2 sw=2 et ai
