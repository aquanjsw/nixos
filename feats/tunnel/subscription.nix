{
  utils,
  pkgs,
  config,
  lib,
  ...
}: let

  runtimeDirectory = "tunnel-subscriptions";

  subscriptionType = lib.types.submodule ({ name, ... }: {
    options = {
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
      };
      path = lib.mkOption {
        default = "/run/${runtimeDirectory}/${name}.json";
        readOnly = true;
      };
    };
  });
in {

  options.tunnel.subscription = lib.mkOption {
    type = lib.types.attrsOf subscriptionType;
    default = {};
  };

  config = lib.mkIf config.tunnel.server.enable {

    systemd.services.tunnelSubscriptionDeployer = {
      description = "Generate Tunnel Subscriptions";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = runtimeDirectory;
        RuntimeDirectoryPreserve = "yes";
        ExecStart = let
          script = pkgs.writeShellScript "tunnelSubscriptionsGenerator" ''
            ${lib.concatStringsSep "\n" (map (subscription:
              utils.genJqSecretsReplacementSnippet
              subscription.settings
              subscription.path
            ) (lib.attrValues config.tunnel.subscription))}
          '';
        in "+${script}";
      };
    };

    services.caddy.virtualHosts."subscription.${config.domain}".extraConfig = ''
      basic_auth {
        rag {$HASHED_PASSWORD}
      }
      reverse_proxy 127.0.0.1:${builtins.toString config.web-app.port}
    '';

    assertions = [
      {
        assertion = config.web-app.enable;
        message = "Tunnel subscription requires web app to be enabled.";
      }
    ];
  };
}
