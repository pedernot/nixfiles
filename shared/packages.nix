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
    alejandra
    codex
    ctags
    difftastic
    dig
    entr
    fastmod
    fd
    gnumake
    go
    jq
    kubectx
    kubelogin
    kubelogin-oidc
    kubernetes-helm
    lsof
    lua5_1
    luarocks
    nixd
    nodejs
    openssl
    pi-coding-agent
    readline
    ripgrep
    rsync
    shellcheck
    slides
    statix
    stylua
    tree
    unzip
    urlscan
    wget
    xh
    yq
  ];
}
