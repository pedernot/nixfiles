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
          # Colors are managed by stylix.targets.foot (see common/theme.nix).
          # Font is set here explicitly; stylix.targets.foot.fonts is disabled
          # to avoid conflicts with per-host font/size overrides.
          font = "Hack Nerd Font Mono:size=8, Noto Color Emoji:size=8";
        };
      };
    };

    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      shellAliases = {
        grep = "grep --color=auto";
        cp = "cp -iv";
        rm = "rm -iv --one-file-system";
        mv = "mv -iv";
        mkdir = "mkdir -p -v";
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        tnew = "new-tmux-from-dir-name";
        tree = "tree -C";

        ls = "ls -hF --color=auto";
        lr = "ls -R";
        ll = "ls -l";
        la = "ll -A";
        lx = "ll -BX";
        lz = "ll -rS";
        lt = "ll -rt";
        lm = "la | more";

        gpgreset = "gpg-connect-agent updatestartuptty /bye";
        https = "http --default-scheme=https";
        mutt = "neomutt";
        startx = "startx $XINITRC";
        tmux = "tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf";
        mbsync = "mbsync -c \"$XDG_CONFIG_HOME\"/isync/mbsyncrc";
        abook = "abook --config \"$XDG_CONFIG_HOME\"/abook/abookrc --datafile \"$XDG_DATA_HOME\"/notes/addressbook";
        wget = "wget --hsts-file='$XDG_CACHE_HOME/wget-hsts'";

        j = "zi";

        k = "kubectl";
        kctx = "kubectx";
        kns = "kubens";
      };
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
      setOptions = [
        "INC_APPEND_HISTORY"
        "AUTO_CD"
        "EXTENDED_GLOB"
        "PROMPT_SUBST"
        "NO_HUP"
        "NO_BEEP"
        "NO_NOMATCH"
        "NO_NOTIFY"
      ];
      initContent = ''
        ${lib.strings.fileContents ../zsh/functions.zsh}
        ${lib.strings.fileContents ../zsh/zshrc}
      '';
      history = {
        path = "${config.programs.zsh.dotDir}/histfile";
      };
      defaultKeymap = "viins";
    };

    tmux = {
      enable = true;
      package = pkgs.tmux;
      shortcut = "Space";
      baseIndex = 1;
      escapeTime = 0;
      historyLimit = 100000;
      focusEvents = true;
      keyMode = "vi";
      terminal = "screen-256color";
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

    btop.enable = true;

    bat.enable = true;

    smug = {
      enable = true;
      projects = {
        capture-backend = {
          root = "~/workspace/capture-backend";
          windows = [
            {
              name = "shell";
              layout = "even-horizontal";
              panes = [
                {
                  type = "horizontal";
                  commands = ["jj l"];
                }
              ];
            }
            {
              name = "code";
              root = "capture-storage";
              layout = "even-horizontal";
              commands = ["nvim"];
            }
            {
              name = "k8s";
              root = "capture-storage";
              layout = "main-vertical";
              commands = ["ssh dora-cluster"];
              panes = [
                {
                  type = "horizontal";
                  commands = ["k9s"];
                }
              ];
            }
            {
              name = "mimir";
              root = "mimir";
              layout = "even-horizontal";
            }
            {
              name = "search";
              root = "search-backend";
              layout = "even-horizontal";
            }
          ];
        };
        tests = {
          root = "~/workspace/capture-backend";
          windows = [
            {
              name = "lints";
              root = ".";
              layout = "even-horizontal";
            }
            {
              name = "tests";
              root = ".";
              layout = "even-horizontal";
            }
            {
              name = "opencode";
              root = ".";
              layout = "even-horizontal";
              commands = ["opencode"];
            }
            {
              name = "staging";
              root = ".";
              layout = "even-horizontal";
              commands = ["ssh staging"];
            }
          ];
        };
        nixfiles = {
          root = "~/workspace/nixfiles";
          windows = [
            {
              name = "code";
              root = ".";
              layout = "even-horizontal";
              panes = [
                {
                  type = "horizontal";
                  commands = ["nvim ."];
                }
              ];
            }
            {
              name = "email";
              root = ".";
              layout = "even-horizontal";
              commands = ["mbsync -a; mutt"];
            }
          ];
        };
      };
    };

    yazi = {
      enable = true;
      shellWrapperName = "y";
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

        git_status = {disabled = true;};
        git_commit = {disabled = true;};
        git_metrics = {disabled = true;};
        git_branch = {disabled = true;};

        custom = {
          jj = {
            description = "The current jj status";
            when = "jj --ignore-working-copy root";
            symbol = "🥋 ";
            command = ''
              jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template '
                separate(" ",
                  change_id.shortest(4),
                  bookmarks,
                  "|",
                  concat(
                    if(conflict, "💥"),
                    if(divergent, "🚧"),
                    if(hidden, "👻"),
                    if(immutable, "🔒"),
                  ),
                  raw_escape_sequence("\x1b[1;32m") ++ if(empty, "(empty)"),
                  raw_escape_sequence("\x1b[1;32m") ++ coalesce(
                    truncate_end(29, description.first_line(), "…"),
                    "(no description set)",
                  ) ++ raw_escape_sequence("\x1b[0m"),
                )
              '
            '';
          };
          git_status = {
            when = "! jj --ignore-working-copy root";
            command = "starship module git_status";
            style = "";
            description = "Only show git_status if we're not in a jj repo";
          };
          git_commit = {
            when = "! jj --ignore-working-copy root";
            command = "starship module git_commit";
            style = "";
            description = "Only show git_commit if we're not in a jj repo";
          };
          git_metrics = {
            when = "! jj --ignore-working-copy root";
            command = "starship module git_metrics";
            style = "";
            description = "Only show git_metrics if we're not in a jj repo";
          };
          git_branch = {
            when = "! jj --ignore-working-copy root";
            command = "starship module git_branch";
            style = "";
            description = "Only show git_branch if we're not in a jj repo";
          };
        };
      };
    };
  };
}
