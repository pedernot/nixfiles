_: {
  home.file = {
    ".pi/agent/extensions/bash-command-guard.ts" = {
      source = ../pi/extensions/bash-command-guard.ts;
      force = true;
    };

    ".pi/agent/extensions/cwd-boundary-guard.ts" = {
      source = ../pi/extensions/cwd-boundary-guard.ts;
      force = true;
    };

    ".pi/agent/extensions/tmux-runner.ts" = {
      source = ../pi/extensions/tmux-runner.ts;
      force = true;
    };

    ".pi/agent/extensions/verify-after-edit.ts" = {
      source = ../pi/extensions/verify-after-edit.ts;
      force = true;
    };
  };
}
