{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  ssh-keys = lib.strings.splitString "\n"
    (lib.strings.trim (builtins.readFile inputs.ssh-keys));
in {

  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    ./tunnel
  ];

  options = {

    paths = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {
        module = ./.;
        secrets = ./../secrets;
      };
    };

    limited.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the system is limited in resources.";
    };

    oversea.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the system is oversea.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "zaelggk.com";
      readOnly = true;
    };
  };

  config = let
    secrets = config.paths.secrets;
  in {

    age.secrets = {
      caddy-env = { file = secrets + "/caddy-env.age"; };
      vless-uuid = { file = secrets + "/vless-uuid.age"; };
      reality-private-key = { file = secrets + "/reality-private-key.age"; };
      reality-public-key = { file = secrets + "/reality-public-key.age"; };
      clash-api-secret = { file = secrets + "/clash-api-secret.age"; };
      inbound-password = { file = secrets + "/inbound-password.age"; };
      django-env = { file = secrets + "/django-env.age"; };
      beszel-agent-env = { file = secrets + "/beszel-agent-env.age"; };
    };

    users.users.rag = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = ssh-keys;
      packages = with pkgs; ([
        gh
      ] ++ lib.optionals (!config.limited.enable) [
        xdg-utils
        nodejs
      ]);
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.rag = {
      pkgs,
      lib,
      ...
    }: {

      programs.git.settings.user = {
        enable = true;
        email = "zhdlcc@gmail.com";
        name = "aquanjsw";
      };

      home.activation = {

        initDotfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
          DIR="$HOME/.dotfiles"
          if [ ! -d "$DIR" ]; then
            ${lib.getExe pkgs.git} clone --bare https://github.com/aquanjsw/dotfiles "$DIR"
            dotfiles() {
              ${lib.getExe pkgs.git} --git-dir="$DIR" --work-tree="$HOME" "$@"
            }
            dotfiles config --local status.showUntrackedFiles no
            dotfiles checkout
          fi
        '';
      };

      home.stateVersion = "25.11";
    };

    users.users.root.openssh.authorizedKeys.keys = ssh-keys;

    environment.variables.EDITOR = "vim";

    environment.systemPackages = with pkgs; ([
      tree
      netcat
      curl
      ranger
      inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
    ]);

    programs.fish.enable = true;
    programs.git.enable = true;
    programs.vim.enable = true;
    programs.vim.defaultEditor = true;
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

    nixpkgs.config.allowUnfree = true;
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
