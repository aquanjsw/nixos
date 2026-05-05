{ config, lib, inputs, ... }: {

  imports = [
    ./hardware-configuration.nix
  ];

  options.domain = lib.mkOption {
    type = lib.types.str;
  };

  config = {

    age.secrets = let
      path = config.paths.secrets;
    in {
      caddy-env.file = path + "/caddy-env.age";
      django-env.file = path + "/django-env.age";
    };

    limited.enable = true;
    oversea.enable = true;
    tunnel.server.enable = true;

    services.caddy.enable = true;
    services.web-server.enable = true;
    services.web-server.subscription.path = config.tunnel.subscription.path;
    services.web-server.subscription.name = config.tunnel.subscription.name;
    services.web-server.envFile = config.age.secrets.django-env.path;

    services.beszel.hub.enable = true;
    services.caddy.virtualHosts."beszel.${config.domain}".extraConfig = ''
      reverse_proxy 127.0.0.1:${builtins.toString config.services.beszel.hub.port}
    '';

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
