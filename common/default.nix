{...}: {
  imports = [
    ./packages.nix
    ./scripts.nix
    ./programs.nix
    ./secrets.nix
    ./zsh-completions.nix
    ./xdg.nix
    ./sway.nix
    ./services.nix
    ./ai.nix
    ./theme.nix
  ];

  home = {
    username = "peder";
    homeDirectory = "/home/peder";
    stateVersion = "25.11";
    preferXdgDirectories = true;
    sessionPath = ["$HOME/.local/bin"];
    sessionVariables = {
      COMPOSE_BAKE = "true";
      DO_NOT_TRACK = "1";
      KUBECONFIG = "$HOME/.config/kube/config.yaml";
      MOZ_ENABLE_WAYLAND = "1";
      PIPENV_VENV_IN_PROJECT = "1";
      PYRIGHT_PYTHON_IGNORE_WARNINGS = "1";
      TINTED_TMUX_OPTION_STATUSBAR = "1";
    };
  };

  manual.manpages.enable = false;

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = ["Noto Color Emoji"];
      monospace = ["Hack Nerd Font Mono"];
    };
  };
}
