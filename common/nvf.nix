{
  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;
      lazy.enable = false;

      # Load existing config: bootstrap lazy.nvim + require all modules
      luaConfigRC.existing-config = let
        nvimDir = ../nvim;
      in ''
        vim.g.mapleader = " "

        local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
        if not vim.loop.fs_stat(lazypath) then
          vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable",
            lazypath,
          })
        end
        vim.opt.rtp:prepend(lazypath)
        vim.opt.rtp:prepend("${nvimDir}")

        require("lazy").setup("plugins")

        -- Re-add to package.path after lazy.setup() resets rtp
        package.path = "${nvimDir}/lua/?.lua;${nvimDir}/lua/?/init.lua;" .. package.path
        require("config")
      '';
    };
  };
}
