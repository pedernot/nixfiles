_: {
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      desktop = "$HOME";
      documents = "$HOME/docs";
      download = "$HOME/docs/dl";
      music = "$HOME/docs";
      pictures = "$HOME/docs";
      videos = "$HOME/docs";
      templates = "$HOME/docs";
      publicShare = "$HOME/docs";
      setSessionVariables = true;
    };
    mimeApps = {
      enable = true;
      associations.added = {"binary/octet-stream" = "gvim/desktop";};
      defaultApplications = {
        "application/pdf" = "zathura.desktop";
        "application/x-extension-html" = "firefox.desktop";
        "image/png" = "grim.desktop";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
      };
    };
  };
}
