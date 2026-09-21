_: {
  programs = {
    foot = {
      enable = true;
      settings = {
        main = {
          dpi-aware = "yes";
          # Colors are managed by stylix.targets.foot.
          # Font is set here explicitly; stylix.targets.foot.fonts is disabled
          # to avoid conflicts with per-host font/size overrides.
          font = "Hack Nerd Font Mono:size=8, Noto Color Emoji:size=8";
        };
      };
    };

    zsh.shellAliases = {
      grep = "grep --color=auto";
      rm = "rm -iv --one-file-system";

      ls = "ls -hF --color=auto";
      lr = "ls -R";
      ll = "ls -l";
      la = "ll -A";
      lx = "ll -BX";
      lz = "ll -rS";
      lt = "ll -rt";
      lm = "la | more";

      gpgreset = "gpg-connect-agent updatestartuptty /bye";
      mutt = "neomutt";
      startx = "startx $XINITRC";
      abook = "abook --config \"$XDG_CONFIG_HOME\"/abook/abookrc --datafile \"$XDG_DATA_HOME\"/notes/addressbook";
    };
  };
}
