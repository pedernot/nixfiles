{pkgs, ...}: {
  imports = [
    ../common
    ./sway.nix
    ./terminal.nix
  ];

  home = {
    username = "peder";
    homeDirectory = "/home/peder";
    stateVersion = "25.11";
    packages = with pkgs; [
      hledger
    ];
    sessionVariables = {
      LEGDER_FILE = "$HOME/workspace/finances/main.journal";
    };
  };
}
