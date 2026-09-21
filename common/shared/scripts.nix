{pkgs, ...}: let
  sm = pkgs.writeShellApplication {
    name = "sm";
    text = ''
      smug "$(smug list | fzf --height 50% --reverse)"
    '';
  };
in {
  home.packages = [sm];
}
