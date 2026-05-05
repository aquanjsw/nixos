{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {

  imports = [
    ./tunnel
  ];

  options = {

    oversea.enable = lib.mkOption {
      default = false;
      description = "Whether the system is oversea.";
    };

  };

  config = let

    ssh-keys = lib.strings.splitString "\n"
      (lib.strings.trim (builtins.readFile inputs.ssh-keys));

  in {

    age.secrets = let
      path = config.paths.secrets;
    in {
      vless-uuid.file = path + "/vless-uuid.age";
      reality-private-key.file = path + "/reality-private-key.age";
      reality-public-key.file = path + "/reality-public-key.age";
      clash-api-secret.file = path + "/clash-api-secret.age";
      inbound-password.file = path + "/inbound-password.age";
      beszel-agent-env.file = path + "/beszel-agent-env.age";
    };

    users.users.${config.user} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = ssh-keys;
    };

    users.users.root.openssh.authorizedKeys.keys = ssh-keys;

    environment.variables.EDITOR = "vim";

    environment.systemPackages = with pkgs; ([
    ]);

    programs.fish.enable = true;
    programs.nix-ld.enable = !config.limited.enable;

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
    zramSwap.memoryPercent = lib.mkIf config.limited.enable 100;

    environment.variables.NIXPKGS_ALLOW_UNFREE = "1";

    time.timeZone = "Asia/Shanghai";

    i18n.defaultLocale = "en_US.UTF-8";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.auto-optimise-store = true;
    nix.settings.substituters = lib.optionals (!config.oversea.enable)
      [ "https://mirrors.cernet.edu.cn/nix-channels/store" ];
  };
}

# vim: sts=2 sw=2 et ai
