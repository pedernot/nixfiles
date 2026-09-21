_: {
  imports = [
    ../common
    ./discord.nix
  ];

  home = {
    username = "peder";
    homeDirectory = "/home/peder";
    stateVersion = "25.11";
  };
}
