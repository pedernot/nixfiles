_: {
  imports = [
    ../shared
    ../linux
    ./discord.nix
  ];

  home = {
    username = "peder";
    homeDirectory = "/home/peder";
    stateVersion = "25.11";
  };
}
