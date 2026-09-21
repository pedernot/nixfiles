_: {
  imports = [
    ./pi.nix
    ./zsh-completions.nix
  ];

  home = {
    preferXdgDirectories = true;
    sessionPath = ["$HOME/.local/bin"];
    sessionVariables = {
      EDITOR = "nvim";
      COMPOSE_BAKE = "true";
      DO_NOT_TRACK = "1";
      KUBECONFIG = "$HOME/.config/kube/config.yaml";
      PIPENV_VENV_IN_PROJECT = "1";
      PYRIGHT_PYTHON_IGNORE_WARNINGS = "1";
      TINTED_TMUX_OPTION_STATUSBAR = "1";
    };
  };

  manual.manpages.enable = false;
}
