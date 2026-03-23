{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
  ];

  accounts.email = {
    maildirBasePath = "${config.xdg.dataHome}/mail";

    accounts = {
      gmail-tsl = {
        primary = true;
        flavor = "gmail.com";
        address = "peder.galteland@softwarelab.no";
        realName = "Peder Notto Galteland";
        userName = "peder.galteland@softwarelab.no";
        passwordCommand = ["pass" "gmail-tsl-app-pw"];
        maildir.path = "gmail-tsl";
        folders = {
          inbox = "inbox";
          sent = "sent";
          drafts = "drafts";
        };
        smtp = {
          port = 587;
          tls.useStartTls = true;
        };
        mbsync = {
          enable = true;
          groups.sync-gmail-tsl.channels = {
            default = {
              patterns = [
                "INBOX"
                "jira"
              ];
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
            sent = {
              farPattern = "[Gmail]/Sent Mail";
              nearPattern = "sent";
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
            drafts = {
              farPattern = "[Gmail]/Drafts";
              nearPattern = "drafts";
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
            archive = {
              farPattern = "[Gmail]/All Mail";
              nearPattern = "archive";
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
          };
        };
        msmtp.enable = true;
        neomutt = {
          enable = true;
          sendMailCommand = "msmtp";
          showDefaultMailbox = false;
          extraConfig = ''
            unmailboxes *
            mailboxes +inbox \
                      +drafts \
                      +sent \
                      +archive

            color status color6 color18
            macro index,pager \cs "<shell-escape>mbsync -V -c ~/.config/isyncrc sync-gmail-tsl<enter>"
          '';
        };
        notmuch = {
          enable = true;
          neomutt.enable = false;
        };
      };

      gmail-personal = {
        flavor = "gmail.com";
        address = "pederng@gmail.com";
        realName = "Peder Notto Galteland";
        userName = "pederng@gmail.com";
        passwordCommand = ["pass" "gmail-personal-app-pw"];
        maildir.path = "gmail-personal";
        folders = {
          inbox = "inbox";
          sent = "sent";
          drafts = "drafts";
        };
        smtp = {
          port = 587;
          tls.useStartTls = true;
        };
        mbsync = {
          enable = true;
          groups.sync-gmail-personal.channels = {
            default = {
              patterns = ["INBOX"];
              extraConfig.SyncState = "*";
            };
            sent = {
              farPattern = "[Gmail]/Sent Mail";
              nearPattern = "sent";
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
            drafts = {
              farPattern = "[Gmail]/Drafts";
              nearPattern = "drafts";
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
            archive = {
              farPattern = "[Gmail]/All Mail";
              nearPattern = "archive";
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
          };
        };
        msmtp.enable = true;
        neomutt = {
          enable = true;
          sendMailCommand = "msmtp";
          showDefaultMailbox = false;
          extraConfig = ''
            unmailboxes *
            mailboxes +inbox \
                      +drafts \
                      +sent \
                      +archive

            color status green color18
            macro index,pager \cs "<shell-escape>mbsync -V -c ~/.config/isyncrc sync-gmail-personal<enter>"
          '';
        };
        notmuch = {
          enable = true;
          neomutt.enable = false;
        };
      };

      purelymail = {
        flavor = "plain";
        address = "peder.notto@galte.land";
        realName = "Peder Notto Galteland";
        userName = "peder.notto@galte.land";
        passwordCommand = ["pass" "purelymail"];
        maildir.path = "purelymail";
        folders = {
          inbox = "inbox";
          sent = "sent";
          drafts = "drafts";
        };
        imap = {
          host = "imap.purelymail.com";
          port = 993;
          tls.enable = true;
        };
        smtp = {
          host = "smtp.purelymail.com";
          port = 587;
          tls = {
            enable = true;
            useStartTls = true;
          };
        };
        mbsync = {
          enable = true;
          groups.sync-purelymail.channels = {
            default = {
              patterns = ["INBOX"];
              extraConfig.SyncState = "*";
            };
            sent = {
              farPattern = "Sent";
              nearPattern = "sent";
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
            drafts = {
              farPattern = "Drafts";
              nearPattern = "drafts";
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
            archive = {
              farPattern = "Trash";
              nearPattern = "archive";
              extraConfig = {
                Create = "Near";
                SyncState = "*";
              };
            };
          };
        };
        msmtp.enable = true;
        neomutt = {
          enable = true;
          sendMailCommand = "msmtp";
          showDefaultMailbox = false;
          extraConfig = ''
            unmailboxes *
            mailboxes +inbox \
                      +drafts \
                      +sent \
                      +archive

            color status magenta color18
            macro index,pager \cs "<shell-escape>mbsync -V -c ~/.config/isyncrc sync-purelymail<enter>"
          '';
        };
        notmuch = {
          enable = true;
          neomutt.enable = false;
        };
      };
    };
  };

  programs.mbsync.enable = true;

  programs.neomutt = {
    enable = true;
    editor = "nvim";
    sort = "threads";
    settings = {
      use_from = "yes";
      envelope_from = "yes";
      move = "no";
      delete = "yes";
      quit = "yes";
      charset = "utf-8";
      record = "";
      quote_regexp = ''"^( {0,4}[>|:#%]| {0,4}[a-z0-9]+[>|]+)+"'';
      sort_aux = "last-date-received";
      date_format = ''"%m/%d"'';
      index_format = ''"[%Z]  %D  %-20.20F  %s"'';
      uncollapse_jump = "yes";
      sort_re = "yes";
      reply_regexp = ''"^(([Rr][Ee]?(\[[0-9]+\])?: *)?(\[[^]]+\] *)?)*"'';
      pager_index_lines = "30";
      pager_context = "3";
      pager_stop = "yes";
      menu_scroll = "yes";
      tilde = "yes";
      mailcap_path = ''"~/.config/mutt/mailcap"'';
      sleep_time = "0";
      query_command = ''"abook --config ~/.config/abook/abookrc --datafile ~/.local/share/notes/addressbook --mutt-query '%s'"'';
    };
    extraConfig = ''
      unset confirmappend
      unset markers

      set header_cache = "${config.xdg.cacheHome}/mutt/headers"
      set message_cachedir = "${config.xdg.cacheHome}/mutt/bodies"
      set certificate_file = "${config.xdg.dataHome}/mutt/certificates"

      alternative_order text/plain text/enriched text/html
      auto_view text/html

      source ~/.config/mutt/bindings
      source ~/.config/mutt/colors
      source ~/.config/mutt/sidebar
      source ~/.config/mutt/gpg.rc

      macro index,pager 1 "<change-folder> =../gmail-tsl/inbox<enter>"
      macro index,pager 2 "<change-folder> =../purelymail/inbox<enter>"
      macro index,pager 3 "<change-folder> =../gmail-personal/inbox<enter>"
    '';
  };

  programs.notmuch = {
    enable = true;
    new.tags = [
      "unread"
      "inbox"
    ];
    search.excludeTags = [
      "deleted"
      "spam"
    ];
    maildir.synchronizeFlags = true;
    extraConfig.user = {
      name = "Peder Notto Galteland";
      primary_email = "peder.notto@galte.land";
      other_email = "peder.galteland@softwarelab.no;pederng@gmail.com;";
    };
  };

  programs.msmtp = {
    enable = true;
    configContent = lib.mkBefore ''
      defaults
      auth on
      tls on
      tls_trust_file ${config.accounts.email.certificatesFile}
      logfile ${config.xdg.cacheHome}/msmtp.log
    '';
  };

  xdg.configFile = {
    "mutt/bindings".source = ../mutt/bindings;
    "mutt/colors".source = ../mutt/colors;
    "mutt/sidebar".source = ../mutt/sidebar;
    "mutt/gpg.rc".source = ../mutt/gpg.rc;
    "mutt/mailcap".source = ../mutt/mailcap;
  };
}
