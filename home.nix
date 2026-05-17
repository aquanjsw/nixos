{
  args,
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  finalArgs = config // args;
in
{
  programs.git.enable = true;
  programs.vim.enable = true;
  programs.vim.defaultEditor = true;
  programs.fzf.enable = true;
  programs.fzf.enableFishIntegration = true;

  home.username = finalArgs.user;
  home.homeDirectory = "/home/${finalArgs.user}";
  home.packages =
    with pkgs;
    (
      [
        gh
        tree
        yazi
        tmux
        btop
        inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
        python3
      ]
      ++ lib.optionals (!finalArgs.isLimited) [
        xdg-utils
        nodejs
      ]
      ++ lib.optionals (!finalArgs.isNixOS) [ home-manager ]
    );

  home.activation.init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.getExe pkgs.git} config --global user.name "aquanjsw"
    ${lib.getExe pkgs.git} config --global user.email "zhdlcc@gmail.com"

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
  };

  home.stateVersion = "25.11";
}
