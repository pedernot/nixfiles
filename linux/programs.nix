_: {
  imports = [
    ./terminal.nix
    ./gpg.nix
    ./email.nix
    ./rss.nix
  ];

  programs = {
    zathura.enable = true;
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 5d --keep 3";
      };
      flake = "/home/peder/workspace/nixfiles";
    };
  };
}
