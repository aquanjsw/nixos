{ 
  utils,
  config,
  pkgs,
  lib,
  ...
}: lib.mkIf config.tunnel.server.enable {

  services.caddy = {
    enable = true;
    environmentFile = config.age.secrets.caddy-env.path;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-Olz4W84Kiyldy+JtbIicVCL7dAYl4zq+2rxEOUTObxA=";
    };
    extraConfig = ''
      zaelggk.com {
        root * ${config.services.caddy.dataDir}
        route /config.json {
          basic_auth {
            rag {$HASHED_PASSWORD}
          }
          reverse_proxy 127.0.0.1:${builtins.toString config.services.web-server.port}
        }
        file_server
      }
    '';
    globalConfig = ''
      https_port 1443
      default_bind 127.0.0.1
      acme_dns cloudflare {$CF_API_TOKEN}
    '';
  };
}
