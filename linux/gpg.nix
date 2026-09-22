{
  pkgs,
  config,
  ...
}: {
  programs = {
    password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "${config.xdg.dataHome}/pass";
      };
    };

    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      publicKeys = [
        {
          source = ../peder.galteland.pem;
          trust = "ultimate";
        }
        {
          source = ../personal-key;
          trust = "ultimate";
        }
      ];
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    pinentry.package = pkgs.pinentry-qt;
  };
}
