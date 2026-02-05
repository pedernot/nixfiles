{
  pkgs,
  lib,
  config,
  ...
}: {
  programs = {
    foot = {
      enable = true;
      settings = {
        main = {
          dpi-aware = "yes";
          font = "Hack Nerd Font Mono:size=8, Noto Color Emoji:size=8";
          include = "~/.local/share/tinted-theming/tinty/tinted-terminal-themes-foot-file.ini";
        };
      };
    };

    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      profileExtra = lib.strings.fileContents ../zsh/zprofile;
      plugins = [
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.8.0";
            sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
          };
        }
      ];
      syntaxHighlighting.enable = true;
      initContent = builtins.concatStringsSep "\n" [
        ''
          ${lib.strings.fileContents ../zsh/zshrc}
          ${lib.strings.fileContents ../zsh/aliases.zsh}
          ${lib.strings.fileContents ../zsh/functions.zsh}
        ''
      ];
      history = {
        path = "${config.programs.zsh.dotDir}/histfile";
      };
      defaultKeymap = "viins";
    };

    tmux = {
      enable = true;
      package = pkgs.tmux;
      extraConfig = builtins.concatStringsSep "\n" [
        (lib.strings.fileContents ../tmux.conf)
      ];
      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.tmux-thumbs;
          extraConfig = ''
            set -g @thumbs-alphabet qwerty-homerow
            set -g @thumbs-bg-color blue
            set -g @thumbs-fg-color green
            set -g @thumbs-hint-bg-color black
            set -g @thumbs-hint-fg-color yellow
          '';
        }
        {
          plugin = tmuxPlugins.tmux-fzf;
          extraConfig = ''
            bind w choose-tree -Z
          '';
        }
      ];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type d";
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    starship = {
      enable = true;
      package = pkgs.starship;
      settings = {
        python = {symbol = " ";};
        rust = {symbol = " ";};
        directory = {fish_style_pwd_dir_length = 1;};
        command_timeout = 1000;
        kubernetes = {
          disabled = false;
          format = "[$context](blue)[\(:$namespace\)](dimmed green) ";
        };
        aws = {disabled = true;};
      };
    };
  };
}
