{
  description = "Django web app";

  inputs = {
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      pyproject-nix,
      ...
    }:
    let

      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      project = pyproject-nix.lib.project.loadPyproject {
        projectRoot = ./.;
      };
      python = pkgs.python3;
      pythonEnv = python.withPackages (project.renderers.withPackages { inherit python; });

    in
    with pkgs;
    {

      devShells.${system}.default = mkShellNoCC {
        packages = [ pythonEnv ];
        DEBUG = "1";
      };

      packages.x86_64-linux.default =
        with lib;
        stdenv.mkDerivation {
          name = "web-app";
          src = fileset.toSource {
            root = ./.;
            fileset = fileset.unions [
              ./bwhsite
              ./subalter
            ];
          };
          installPhase = ''
            mkdir -p $out/bin $out/lib
            cp -r bwhsite subalter $out/lib

            makeWrapper ${getBin pythonEnv}/bin/gunicorn $out/bin/web-app \
              --add-flags "--chdir $out/lib -b 127.0.0.1:\''${PORT:-8000} bwhsite.wsgi"
          '';
          nativeBuildInputs = [ makeWrapper ];
          buildInputs = [ pythonEnv ];
        };

      nixosModules.default =
        {
          lib,
          config,
          pkgs,
          ...
        }:
        with lib;
        let
          cfg = config.web-app;
        in
        {
          options.web-app = {
            enable = mkEnableOption "web app";
            package = mkOption {
              type = types.package;
              default = self.packages.${stdenv.hostPlatform.system}.default;
              description = ''
                The package to use for the web app.
                           Only x86_64-linux is tested at the moment.
              '';
            };
            port = mkOption {
              type = types.port;
              default = 8000;
              description = "The port to run the web app on.";
            };
            subscription.mihomo = {
              configPath = mkOption {
                type = types.str;
                example = "/run/secrets/mihomo.json";
                description = "The path to the mihomo subscription config file.";
              };
              urlPath = mkOption {
                type = types.str;
                example = "mihomo.json";
                description = "The URL path for the mihomo subscription.";
              };
            };
            subscription.sing-box = {
              configPath = mkOption {
                type = types.str;
                example = "/run/secrets/sing-box.json";
                description = "The path to the sing-box subscription config file.";
              };
              urlPath = mkOption {
                type = types.str;
                example = "sing-box.json";
                description = "The URL path for the sing-box subscription.";
              };
            };
            envFile = mkOption {
              type = types.str;
              example = "/run/secrets/env";
              description = ''
                The path to the environment file with content like:
                ```
                SECRET_KEY=your_secret_key
                ```
              '';
            };
          };

          config = mkIf config.web-app.enable {
            systemd.services.web-app = {
              description = " web app";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              environment = {
                PORT = builtins.toString cfg.port;
                MIHOMO_CONFIG_PATH = cfg.subscription.mihomo.configPath;
                SINGBOX_CONFIG_PATH = cfg.subscription.sing-box.configPath;
                MIHOMO_URL_PATH = cfg.subscription.mihomo.urlPath;
                SINGBOX_URL_PATH = cfg.subscription.sing-box.urlPath;
                # TODO: use django-hosts to support multiple domains
                DOMAIN = "subscription.${config.domain}";
              };
              serviceConfig = {
                EnvironmentFile = [ cfg.envFile ];
                Restart = "always";
                ExecStart = "${cfg.package}/bin/web-app";
              };
            };
          };
        };
    };
}
