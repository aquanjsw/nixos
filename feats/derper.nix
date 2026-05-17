{
  lib,
  config,
  ...
}: lib.mkIf config.services.tailscale.derper.enable (let
  domain = "derper.${config.domain}";
  extraConfig = ''
    reverse_proxy 127.0.0.1:${builtins.toString config.services.tailscale.derper.port} {
      transport http {
        read_timeout 3600s
      }
      flush_interval -1
    }
  '';
in {
  services.tailscale.derper = {
    inherit domain;
    configureNginx = false;
  };

  services.caddy.virtualHosts = {
    "http://${domain}" = {
      listenAddresses = [ "::0" ];
      inherit extraConfig;
    };
    "https://${domain}" = {
      listenAddresses = [ "::1" ];
      inherit extraConfig;
    };
  };

  assertions = [
    {
      assertion = config.services.caddy.enable;
      message = "Caddy must be enabled to use derper.";
    }
  ];
})
