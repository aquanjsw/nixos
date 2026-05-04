{
  description = "Django web server";

  inputs = {
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    pyproject-nix,
    ...
  }: let 
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    project = pyproject-nix.lib.project.loadPyproject {
      projectRoot = ./.;
    };
    python = pkgs.python3;
    pythonEnv = python.withPackages
      (project.renderers.withPackages { inherit python; });
  in with pkgs;{

    devShells.${system}.default = 
      mkShellNoCC {
        packages = [ pythonEnv ];
        DEBUG = "1";
      };

    packages.${system}.default = with lib; stdenv.mkDerivation {
      name = "django-web-server";
      src = fileset.toSource {
        root = ./.;
        fileset = fileset.unions [
          ./bwhsite
          ./subalter
          ./test
        ];
      };
      installPhase = ''
        mkdir -p $out/bin $out/lib
        cp -r bwhsite subalter test $out/lib

        makeWrapper ${getBin pythonEnv}/bin/gunicorn $out/bin/web-server \
          --add-flags "--chdir $out/lib -b 127.0.0.1:\''${PORT:-8000} bwhsite.wsgi"
      '';
      nativeBuildInputs = [ makeWrapper ];
      buildInputs = [ pythonEnv ];
    };

    nixosModules.default = {
      lib,
      config,
      pkgs,
      ...
    }: with lib; let 
      cfg = config.services.web-server;
    in {
      options.services.web-server = {
        enable = mkEnableOption "web server";
        package = mkOption {
          type = types.package;
          default = self.packages.${stdenv.hostPlatform.system}.default;
          description = '' The package to use for the web server.
            Only x86_64-linux is tested at the moment.
          '';
        };
        port = mkOption {
          type = types.ints.between 1 65535;
          default = 8000;
          description = "The port to run the web server on.";
        };
        subscriptionPath = mkOption {
          type = types.str;
          example = "/run/secrets/config.json";
          description = "The path to the subscription config file.";
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

      config = mkIf config.services.web-server.enable {
        systemd.services.web-server = {
          description = " Web Server";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          environment = {
            PORT = builtins.toString cfg.port;
            SUBSCRIPTION_PATH = cfg.subscriptionPath;
            DOMAIN = config.domain;
          };
          serviceConfig = {
            EnvironmentFile = [ cfg.envFile ];
            Restart = "always";
            ExecStart = "${cfg.package}/bin/web-server";
          };
        };
      };
    };
  };
}