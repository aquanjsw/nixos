{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {

  imports = [
    ./tunnel
    ./caddy
  ];

  options = {

    isOversea = lib.mkOption {
      default = false;
      description = "Whether the system is oversea.";
    };

    domain = lib.mkOption {
      default = "zaelggk.com";
      readOnly = true;
    };

    frpProxies = with lib.types; lib.mkOption {
      default = {
        lib5.aria2-rpc.port = 6800;
      };
      readOnly = true;
    };

    frps.enable = lib.mkEnableOption "frp server";

  };

  config = let
    ssh-keys = lib.strings.splitString "\n"
      (lib.strings.trim (builtins.readFile inputs.ssh-keys));
  in lib.mkMerge [
    {
      users.users.${config.user} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
        ] ++ lib.optional (config.services.aria2.enable) "aria2";
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = ssh-keys;
        packages = with pkgs; [
        ];
      };
      users.users.root.openssh.authorizedKeys.keys = ssh-keys;

      environment.variables.EDITOR = "vim";
      environment.variables.NIXPKGS_ALLOW_UNFREE = "1";
      environment.systemPackages = with pkgs; ([
      ]);

      programs.fish.enable = true;
      programs.nix-ld.enable = !config.isLimited;

      services.frp.instances.default = lib.mkIf config.frps.enable {
        enable = true;
        role = "server";
        settings = {
          bindPort = 7000;
        };
      };
      services.openssh.enable = true;
      services.openssh.settings.PasswordAuthentication = false;
      services.beszel.agent.enable = lib.mkDefault true;
      services.beszel.agent.environmentFile = config.age.secrets.beszel-agent-env.path;
      services.beszel.agent.environment = {
        HUB_URL = "https://beszel.${config.domain}";
      };

      networking.networkmanager.enable = true;
      networking.iproute2.enable = true;
      networking.firewall.enable = false;
      networking.nftables.enable = true;

      zramSwap.enable = true;
      zramSwap.memoryPercent = lib.mkIf config.isLimited 100;

      time.timeZone = "Asia/Shanghai";

      i18n.defaultLocale = "en_US.UTF-8";

      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      nix.settings.substituters = lib.optionals (!config.isOversea)
        [ "https://mirrors.cernet.edu.cn/nix-channels/store" ];

      age.secrets = let
        path = config.paths.secrets;
      in {
        beszel-agent-env.file = path + "/beszel-agent-env.age";
      };
    }
    (lib.mkIf config.web-app.enable {
      age.secrets.web-app-env.file = config.paths.secrets + "/web-app-env.age";
      web-app.envFile = config.age.secrets.web-app-env.path;
    })
  ];
}

# vim: sts=2 sw=2 et ai
