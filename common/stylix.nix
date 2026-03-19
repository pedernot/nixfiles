{pkgs, ...}: {
  # Canonical Stylix configuration — shared across all hosts.
  # Do not add host-specific overrides for base16Scheme, polarity, or fonts
  # in individual host configs. Per-host divergence should be a deliberate,
  # documented exception, not the default.
  stylix = {
    enable = true;

    # Harmonic16 Dark — single palette source of truth for all apps and hosts.
    base16Scheme = "${pkgs.base16-schemes}/share/themes/harmonic16-dark.yaml";

    # Stylix requires an image. We use an explicit base16Scheme above so
    # palette generation from the image does not apply. The image is only
    # used by targets that render a wallpaper (none currently active).
    image = pkgs.runCommand "blank-wallpaper" {} ''
      ${pkgs.imagemagick}/bin/convert -size 1x1 xc:#0b1c2c $out
    '';

    polarity = "dark";

    # Fonts declared here so Stylix uses the same fonts when generating
    # themed app configs. These match the fonts installed in host configs.
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.hack;
        name = "Hack Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };

    # Never auto-enable targets. All targets are opted in explicitly in
    # common/theme.nix.
    autoEnable = false;
  };
}
