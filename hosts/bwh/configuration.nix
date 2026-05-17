{ ... }:
{

  imports = [
    ./hardware-configuration.nix
  ];

  config = {

    isLimited = true;
    isOversea = true;
    tunnel.server.enable = true;
    frps.enable = true;
    web-app.enable = true;

    services.tailscale.derper.enable = true;
    services.beszel.hub.enable = true;
    services.caddy.enable = true;

    networking.hostName = "bwh";
    networking.sits.ip6net = {
      local = "138.128.193.71";
      remote = "45.32.66.87";
      ttl = 255;
    };
    networking.interfaces.ip6net.ipv6 = {
      addresses = [
        {
          address = "2607:8700:5500:5b28::2";
          prefixLength = 64;
        }
      ];
      routes = [
        {
          address = "::";
          prefixLength = 0;
        }
      ];
    };

    boot.loader.grub.device = "/dev/sda";
    boot.loader.grub.enable = true;

    system.stateVersion = "25.11";
  };
}

# vim: sts=2 sw=2 et ai
