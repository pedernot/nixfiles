{...}: {
  imports = [
    ./packages.nix
    ./programs.nix
    ./xdg.nix
    ./sway.nix
    ./services.nix
    ./ai.nix
  ];

  home = {
    username = "peder";
    homeDirectory = "/home/peder";
    stateVersion = "24.11";
    preferXdgDirectories = true;
    sessionPath = ["$HOME/.local/bin"];
    sessionVariables = {
      COMPOSE_BAKE = "true";
      KUBECONFIG = "$HOME/.config/kube/config.yaml";
      MOZ_ENABLE_WAYLAND = "1";
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

  home.file.".local/bin" = {
    source = ../bin;
    recursive = true;
  };

  xdg.configFile = {
    "tinted-theming/tinty/config.toml".source = ../tinty.toml;
  };
}
