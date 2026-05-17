{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  age.secrets.rpc-secret = config.path.secrets + "/rpc-secret.age";

  tunnel.client.sing-box.enable = true;

  services.jellyfin.enable = true;
  services.aria2 = {
    enable = true;
    serviceUMask = "0002";
    rpcSecretFile = config.age.secrets.rpc-secret.path;
    settings = {
      continue = true;
      max-connection-per-server = 8;
      split = 8;
      rpc-allow-origin-all = true;
      optimize-concurrent-downloads = true;
      input-file = "/var/lib/aria2/aria2.session";
      save-session = "/var/lib/aria2/aria2.session";
    };
  };
  services.frp.instances.default = {
    enable = true;
    role = "client";
    settings = {
      serverAddr = config.domain;
      serverPort = 7000;
      user = config.networking.hostName;
      proxies = [
        {
          name = "aria2-rpc";
          type = "tcp";
          localPort = config.services.aria2.settings.rpc-listen-port;
          remotePort = config.frpProxies.lib5.aria2-rpc.port;
        }
      ];
    };
  };

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  nix.settings.substituters = [ "https://cache.nixos-cuda.org" ];
  nix.settings.trusted-public-keys = [
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];

  users.users.${config.user} = {
    packages = with pkgs; [
      nix-index
      python313Packages.django
      nil
    ];
  };

  environment.systemPackages = with pkgs; [
    usbutils
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.services.lvm.enable = true;
  boot.initrd.availableKernelModules = [ "bcache" ];
  fileSystems."/data" = {
    device = lib.mkForce "/dev/bcache0";
    fsType = "xfs";
    options = [ "nofail" ];
  };

  networking.hostName = "lib5";

  system.stateVersion = "25.11";
}

# vim: sts=2 sw=2 et ai
