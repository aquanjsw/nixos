{ config, lib, inputs, ... }: {

  imports = [
    inputs.agenix.nixosModules.default 
    inputs.web-server.nixosModules.default
    ./hardware-configuration.nix
  ];

  config = {

    limited.enable = true;
    oversea.enable = true;
    tunnel.server.enable = true;

    services.web-server.enable = true;
    services.web-server.subscriptionPath = config.tunnel.subscriptionPath;
    services.web-server.envFile = config.age.secrets.django-env.path;

    zramSwap.memoryPercent = 100;
    
    networking.hostName = "bwh";
    networking.sits.ip6net = {
      local = "138.128.193.71";
      remote = "45.32.66.87";
      ttl = 255;
    };
    # networking.defaultGateway6.interface = "ip6net";
    # networking.defaultGateway6.address = "2607:8700:5500:5b28::2/64";
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
