{pkgs, ...}: {
  programs = {
    jujutsu = {
      enable = true;
      settings = {
        aliases = {
          l = ["log" "-r" "(trunk()..@):: | (trunk()..@)-"];
          sl = ["log" "-l" "20"];
          al = ["log" "-r" "all()"];
          mylog = ["log" "-r" "author('peder.galteland@softwarelab.no')"];
        };
        ui = {
          diff-editor = ["nvim" "-c" "DiffEditor $left $right $output"];
          diff-formatter = ["difft" "--color=always" "$left" "$right"];
          pager = ":builtin";
          default-command = "log";
        };
        user = {
          email = "peder.galteland@softwarelab.no";
          name = "Peder Notto Galteland";
        };
        signing = {
          # sign-all = true;
          backend = "gpg";
          key = "4980821A221FE5B1";
        };
        templates = {
          git_push_bookmark = "'pedernot/push-' ++ change_id.short()";
        };
        fix.tools.ruff-fix = {
          command = ["ruff" "check" "--fix"];
          patterns = ["glob:'**/*.py'"];
        };
        fix.tools.ruff-format = {
          command = ["ruff" "format"];
          patterns = ["glob:'**/*.py'"];
        };
      };
    };

    git = {
      enable = true;
      package = pkgs.git;
      signing.format = "openpgp";
      settings = {
        user = {
          name = "Peder Notto Galteland";
          email = "peder.galteland@softwarelab.no";
          signingKey = "4980821A221FE5B1";
        };
        interactive.colorMoved = "default";
        push.default = "current";
        commit.gpgsign = true;
        status.showUntrackedFiles = "all";
        "remote \"origin\"".prune = true;
        "mergetool \"nvim\"".cmd = "nvim -f -c \"Gdiffsplit!\" \"$MERGED\"";
        merge = {
          tool = "nvim";
          conflictstyle = "zdiff3";
        };
        mergetool.keepBackup = false;
        web.browser = "firefox";
        pull.rebase = false;
        diff.algorithm = "histogram";
        aliases = {
          a = "add";
          b = "branch";
          co = "checkout";
          c = "commit";
          ss = "status -sb";
          st = "status";
          graph = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
          oneline = "log --pretty=oneline";
          mergelog = "log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --merges";
          amend = "commit --amend -C HEAD";
          listfiles = "diff-tree --no-commit-id --name-only -r";
          stash-all = "stash save --include-untracked";
          files = "!git diff --name-only $(git merge-base HEAD master)";
          stat = "!git diff --stat $(git merge-base HEAD master)";
          compare = "diff master...HEAD";
        };
        difftastic = {
          enable = true;
          options = {
            background = "dark";
            color = "always";
          };
        };
      };
      ignores = [
        "tags"
        "tags.lock"
        "*.swp"
        "*.bak"
        "*.swo"
        ".ropeproject"
        "*peder*"
        "pytest.ini"
        "profile"
        "callgraph.dot"
        "__pycache__"
        ".bash_history"
        "pylint-error.xml"
        ".mypy_cache"
        ".jira.d"
        ".pytest_cache"
        ".hypothesis"
        ".sqlfluff"
        "*_null-ls*"
        "*.null-ls*"
        ".envrc"
        ".codespellrc"
        ".jj"
        ".jjconflict*"
        "shell.nix"
        ".direnv"
        ".opencode"
        ".claude"
        ".codex"
      ];
    };

    gh = {
      enable = true;
      extensions = [
        pkgs.gh-dash
      ];
    };
  };
}
