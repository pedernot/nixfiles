{
  pkgs,
  lib,
  ...
}: {
  nixpkgs = {
    config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "spotify"
        "discord"
        "discord-unwrapped"
        "todo.txt-vim"
        "vim-textobj-entire"
        "litee.nvim"
      ];
  };
  home.packages = with pkgs; [
    ctags
    difftastic
    dig
    entr
    fastmod
    fd
    gnumake
    go
    jq
    lsof
    lua5_1
    luarocks
    nodejs
    openssl
    pi-coding-agent
    readline
    ripgrep
    rsync
    slides
    tree
    unzip
    urlscan
    wget
    xh
    yq
  ];
}
