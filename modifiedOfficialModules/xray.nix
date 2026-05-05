{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

with lib;

{
  options = {

    services.xray = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to run xray server.
        '';
      };

      package = mkPackageOption pkgs "xray" { };

      settings = mkOption {
        type = types.nullOr (types.attrsOf types.unspecified);
        default = null;
        example = {
          inbounds = [
            {
              port = 1080;
              listen = "127.0.0.1";
              protocol = "http";
            }
          ];
          outbounds = [
            {
              protocol = "freedom";
            }
          ];
        };
        description = ''
          The configuration object.

          See <https://www.v2fly.org/en_US/config/overview.html>.
        '';
      };
    };

  };

  config =
    let
      cfg = config.services.xray;
    in
    mkIf cfg.enable {
      systemd.services.xray = {
        description = "xray Daemon";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = true;
          CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          NoNewPrivileges = true;
          RuntimeDirectory = "xray";
          ExecStartPre =
            let
              script = pkgs.writeShellScript "xray-pre-start" ''
                ${utils.genJqSecretsReplacementSnippet
                  config.services.xray.settings
                  "/run/xray/config.json"}
                  chown --reference=/run/xray /run/xray/config.json
              '';
            in
              "+${script}";
          ExecStart = [
            ""
            "${cfg.package}/bin/xray -config \${RUNTIME_DIRECTORY}/config.json"
          ];
          Restart = "always";
          RestartSec = "10s";
        };
      };
    };
}