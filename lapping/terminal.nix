{lib, ...}: {
  programs = {
    foot = {
      settings = {
        main = {
          dpi-aware = lib.mkForce "no";
          font = lib.mkForce "Hack Nerd Font Mono:size=11, Noto Color Emoji:size=11";
        };
      };
    };
  };
}
