_: {
  programs.opencode = {
    enable = true;
    skills = ../skills;
    settings = {
      theme = "system";
      plugin = ["opencode-anthropic-auth@latest"];
    };
  };
}
