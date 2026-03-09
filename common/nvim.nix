{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs; [
      tree-sitter
      lua-language-server
    ];
  };

  xdg.configFile = {
    "nvim" = {
      source = ../nvim;
      recursive = true;
    };
  };
}
