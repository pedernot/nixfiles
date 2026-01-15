{pkgs, ...}: {
  imports = [
    ../common
    ./sway.nix
    ./terminal.nix
  ];
  home.packages = with pkgs; [
    hledger
  ];
  home.sessionVariables = {
    LEGDER_FILE = "$HOME/workspace/finances/main.journal";
  };
}
