_: {
  imports = [
    ../common
    ./sway.nix
    ./nvim.nix
    ./scripts.nix
    ./zsh.nix
  ];

  home = {
    username = "peder";
    homeDirectory = "/home/peder";
    stateVersion = "25.11";
  };
}
