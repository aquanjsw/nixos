{
  utils,
  config,
  pkgs,
  lib,
  ...
}: lib.mkIf config.tunnel.server.enable {

  services.caddy = {
    environmentFile = config.age.secrets.caddy-env.path;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-J0HWjCPoOoARAxDpG2bS9c0x5Wv4Q23qWZbTjd8nW84=";
    };
    virtualHosts.${config.domain}.extraConfig = ''
      root * ${config.services.caddy.dataDir}
      route /${config.tunnel.subscription.name} {
        basic_auth {
          rag {$HASHED_PASSWORD}
        }
        reverse_proxy 127.0.0.1:${builtins.toString config.services.web-server.port}
      }
      file_server
    '';
    httpsPort = 1443;
    globalConfig = ''
      default_bind 127.0.0.1
      acme_dns cloudflare {$CF_API_TOKEN}
    '';
  };
}
