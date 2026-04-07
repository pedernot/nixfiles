_: {
  programs.opencode = {
    enable = true;
    skills = ../skills;
    tui = {
      theme = "system";
    };
    settings = {
      plugin = ["opencode-anthropic-auth@latest"];
    };
  };
}
