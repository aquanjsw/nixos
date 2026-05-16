{
  config,
  lib,
  pkgs,
  ...
}: lib.mkIf config.services.caddy.enable (let
  site = pkgs.stdenv.mkDerivation {
    name = "site";
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./index.html
      ];
    };
    installPhase = ''
      mkdir -p $out
      cp -r index.html $out
    '';
  };
in {

  services.caddy = {
    environmentFile = config.age.secrets.caddy-env.path;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-J0HWjCPoOoARAxDpG2bS9c0x5Wv4Q23qWZbTjd8nW84=";
    };
    globalConfig = ''
      acme_dns cloudflare {$CF_API_TOKEN}
    '';
    virtualHosts = lib.mkMerge [
      (lib.mkIf config.frps.enable (builtins.listToAttrs (
        lib.flatten (
          lib.mapAttrsToList (host: services:
            lib.mapAttrsToList (service: settings: {
              name = "${service}-${host}.${config.domain}";
              value.extraConfig = ''
                reverse_proxy 127.0.0.1:${builtins.toString settings.port}
              '';
            }) services
          ) config.frpProxies
        )
      )))
      (lib.mkIf config.services.beszel.hub.enable {
        "beszel.${config.domain}".extraConfig = ''
          reverse_proxy 127.0.0.1:${builtins.toString config.services.beszel.hub.port}
        '';
      })
      ({
        "${config.domain}".extraConfig = ''
          root * ${site}
          file_server
        '';
      })
    ];
  };

  age.secrets.caddy-env.file = config.paths.secrets + "/caddy-env.age";

  systemd.services.caddy.serviceConfig = {
    ReadOnlyPaths = [
      site
    ];
  };

})
