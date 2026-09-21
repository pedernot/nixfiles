_: {
  imports = [
    ./packages.nix
    ./scripts.nix
    ./programs.nix
    ./xdg.nix
    ./sway.nix
    ./services.nix
    ./theme.nix
  ];

  home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = ["Noto Color Emoji"];
      monospace = ["Hack Nerd Font Mono"];
    };
  };
}
