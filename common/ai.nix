_: {
  programs.opencode = {
    enable = true;
    skills = ../skills;
    settings = {
      plugin = ["opencode-anthropic-auth@latest"];
    };
  };
}
