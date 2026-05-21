_: {
  home.file = {
    ".pi/agent/extensions/bash-command-guard.ts" = {
      source = ../extensions/bash-command-guard.ts;
      force = true;
    };

    ".pi/agent/extensions/cwd-boundary-guard.ts" = {
      source = ../extensions/cwd-boundary-guard.ts;
      force = true;
    };

    ".pi/agent/extensions/tmux-runner.ts" = {
      source = ../extensions/tmux-runner.ts;
      force = true;
    };

    ".pi/agent/extensions/verify-after-edit.ts" = {
      source = ../extensions/verify-after-edit.ts;
      force = true;
    };
  };
}
