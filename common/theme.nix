_: {
  # Shared HM Stylix target policy — applies to all hosts.
  # Base scheme, polarity, fonts, and image are set at the NixOS level in
  # common/stylix.nix and inherited here automatically.
  #
  # Keep autoEnable = false. Add new targets explicitly below only after
  # verifying they don't conflict with existing per-app config.
  stylix = {
    autoEnable = false;

    targets = {
      foot = {
        enable = true;
        colors.enable = true;
        fonts.enable = false;
        inputs.enable = true;
        opacity.enable = false;
      };
      tmux.enable = true;
      fzf.enable = true;
      starship.enable = true;
      yazi.enable = true;
    };
  };
}
