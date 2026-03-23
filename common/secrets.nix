{config, ...}: {
  sops = {
    defaultSopsFile = ../secrets/test.yaml;
    defaultSopsFormat = "yaml";
    gnupg.home = "${config.home.homeDirectory}/.local/share/gnupg";

    secrets.test-secret = {
      path = "${config.xdg.configHome}/sops-nix/test-secret";
    };
  };

  home.sessionVariables.SOPS_TEST_SECRET = config.sops.secrets.test-secret.path;
}
