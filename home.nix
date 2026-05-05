{
  args,
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  finalArgs = config // args;
in {
  programs.git.enable = true;
  programs.git.settings.user.email = "zhdlcc@gmail.com";
  programs.git.settings.user.name = "aquanjsw";
  programs.vim.enable = true;
  programs.vim.defaultEditor = true;

  home.username = finalArgs.user;
  home.homeDirectory = "/home/${finalArgs.user}";
  home.packages = with pkgs; ([
    gh
    tree
    netcat
    curl
    ranger
    screen
    inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
  ]
  ++ lib.optionals (!finalArgs.limited.enable) [
    xdg-utils
    nodejs
  ]
  ++ lib.optional (config ? home) home-manager
  );

  home.activation.initDotfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    DIR="$HOME/.dotfiles"
    if [ ! -d "$DIR" ]; then
      ${lib.getExe pkgs.git} clone --bare https://github.com/aquanjsw/dotfiles "$DIR"
      dotfiles() {
        ${lib.getExe pkgs.git} --git-dir="$DIR" --work-tree="$HOME" "$@"
      }
      export -f dotfiles
      dotfiles config status.showUntrackedFiles no
      dotfiles ls-files --deleted | xargs dotfiles checkout --
    fi
  '';

  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
    EDITOR = "vim";
    GIT_CONFIG_GLOBAL = "${config.home.homeDirectory}/.gitconfig";
  };

  home.stateVersion = "25.11";
}
