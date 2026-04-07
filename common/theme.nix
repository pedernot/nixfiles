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
      };
      tmux.enable = true;
      bat.enable = true;
      btop.enable = true;
      fzf.enable = true;
      starship.enable = true;
      yazi.enable = true;
      zathura.enable = true;
      # nvf theming via stylix uses base16-nvim which maps colors differently
      # than tinted-vim. To switch, enable this and remove tinted-vim from nvf.nix.
      # nvf.enable = true;
    };
  };
}
