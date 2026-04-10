{
  pkgs,
  config,
  lib,
  ...
}: let
  defaultFolders = {
    inbox = "inbox";
    sent = "sent";
    drafts = "drafts";
  };

  commonMailAccount = {
    realName = "Peder Notto Galteland";
    msmtp.enable = true;
    notmuch = {
      enable = true;
      neomutt.enable = false;
    };
  };

  mkNeomuttAccount = {
    statusColor,
    syncGroup,
  }: {
    enable = true;
    sendMailCommand = "msmtp";
    showDefaultMailbox = false;
    extraConfig = ''
      unmailboxes *
      mailboxes +inbox \
                +drafts \
                +sent \
                +archive

      color status ${statusColor} color18
      macro index,pager \cs "<shell-escape>mbsync -V -c ~/.config/isyncrc ${syncGroup}<enter>"
    '';
  };

  mkDefaultSyncChannel = {
    patterns,
    createNear ? false,
  }: {
    inherit patterns;
    extraConfig =
      {
        SyncState = "*";
      }
      // lib.optionalAttrs createNear {
        Create = "Near";
      };
  };

  mkNearSyncChannel = {
    farPattern,
    nearPattern,
  }: {
    inherit farPattern nearPattern;
    extraConfig = {
      Create = "Near";
      SyncState = "*";
    };
  };

  mkGroupedMbsync = {
    syncGroup,
    channels,
  }: {
    enable = true;
    groups.${syncGroup}.channels = channels;
  };

  mkStartTlsSmtp = {
    host ? null,
    port ? 587,
  }:
    {
      inherit port;
      tls = {
        enable = true;
        useStartTls = true;
      };
    }
    // lib.optionalAttrs (host != null) {inherit host;};

  mkGmailMbsync = {
    syncGroup,
    patterns,
  }:
    mkGroupedMbsync {
      inherit syncGroup;
      channels = {
        default = mkDefaultSyncChannel {
          inherit patterns;
          createNear = true;
        };
        sent = mkNearSyncChannel {
          farPattern = "[Gmail]/Sent Mail";
          nearPattern = "sent";
        };
        drafts = mkNearSyncChannel {
          farPattern = "[Gmail]/Drafts";
          nearPattern = "drafts";
        };
        archive = mkNearSyncChannel {
          farPattern = "[Gmail]/All Mail";
          nearPattern = "archive";
        };
      };
    };

  mkGmailAccount = {
    address,
    userName,
    passwordCommand,
    maildirPath,
    syncGroup,
    statusColor,
    patterns,
    primary ? false,
  }:
    commonMailAccount
    // {
      inherit primary address userName;
      flavor = "gmail.com";
      passwordCommand = ["pass" passwordCommand];
      maildir.path = maildirPath;
      folders = defaultFolders;
      smtp = mkStartTlsSmtp {};
      mbsync = mkGmailMbsync {
        inherit syncGroup patterns;
      };
      neomutt = mkNeomuttAccount {
        inherit statusColor syncGroup;
      };
    };

  mkPurelymailAccount = {
    syncGroup,
    statusColor,
  }:
    commonMailAccount
    // {
      flavor = "plain";
      address = "peder.notto@galte.land";
      userName = "peder.notto@galte.land";
      passwordCommand = ["pass" "purelymail"];
      maildir.path = "purelymail";
      folders = defaultFolders;
      imap = {
        host = "imap.purelymail.com";
        port = 993;
        tls.enable = true;
      };
      smtp = mkStartTlsSmtp {
        host = "smtp.purelymail.com";
      };
      mbsync = mkGroupedMbsync {
        inherit syncGroup;
        channels = {
          default = mkDefaultSyncChannel {
            patterns = ["INBOX"];
          };
          sent = mkNearSyncChannel {
            farPattern = "Sent";
            nearPattern = "sent";
          };
          drafts = mkNearSyncChannel {
            farPattern = "Drafts";
            nearPattern = "drafts";
          };
          archive = mkNearSyncChannel {
            farPattern = "Trash";
            nearPattern = "archive";
          };
        };
      };
      neomutt = mkNeomuttAccount {
        inherit statusColor syncGroup;
      };
    };
in {
  accounts.email = {
    maildirBasePath = "${config.xdg.dataHome}/mail";

    accounts = {
      gmail-tsl = mkGmailAccount {
        primary = true;
        address = "peder.galteland@jottagroup.no";
        userName = "peder.galteland@jottagroup.no";
        passwordCommand = "gmail-jotta-app-pw";
        maildirPath = "gmail-tsl";
        syncGroup = "sync-gmail-tsl";
        patterns = [
          "INBOX"
          "jira"
        ];
        statusColor = "color6";
      };

      gmail-personal = mkGmailAccount {
        address = "pederng@gmail.com";
        userName = "pederng@gmail.com";
        passwordCommand = "gmail-personal-app-pw";
        maildirPath = "gmail-personal";
        syncGroup = "sync-gmail-personal";
        patterns = ["INBOX"];
        statusColor = "green";
      };

      purelymail = mkPurelymailAccount {
        syncGroup = "sync-purelymail";
        statusColor = "magenta";
      };
    };
  };

  programs = {
    mbsync.enable = true;

    neomutt = {
      enable = true;
      editor = "nvim";
      sort = "threads";
      sidebar = {
        enable = true;
        width = 32;
      };
      binds = [
        {
          map = ["index"];
          key = "-";
          action = "collapse-all";
        }
        {
          map = [
            "index"
            "pager"
          ];
          key = "\\`";
          action = "next-unread";
        }
        {
          map = ["index"];
          key = "<space>";
          action = "collapse-thread";
        }
        {
          map = [
            "attach"
            "index"
          ];
          key = "g";
          action = "first-entry";
        }
        {
          map = [
            "attach"
            "index"
          ];
          key = "G";
          action = "last-entry";
        }
        {
          map = ["index"];
          key = "R";
          action = "group-reply";
        }
        {
          map = ["editor"];
          key = "<Tab>";
          action = "complete-query";
        }
        {
          map = ["pager"];
          key = "g";
          action = "top";
        }
        {
          map = ["pager"];
          key = "G";
          action = "bottom";
        }
        {
          map = ["pager"];
          key = "p";
          action = "previous-subthread";
        }
        {
          map = ["pager"];
          key = "n";
          action = "next-subthread";
        }
        {
          map = ["pager"];
          key = "R";
          action = "group-reply";
        }
        {
          map = ["pager"];
          key = "J";
          action = "next-line";
        }
        {
          map = ["pager"];
          key = "K";
          action = "previous-line";
        }
        {
          map = ["attach"];
          key = "<return>";
          action = "view-mailcap";
        }
      ];
      macros = [
        {
          map = [
            "index"
            "pager"
          ];
          key = "\\cj";
          action = "<sidebar-next><sidebar-open>";
        }
        {
          map = [
            "index"
            "pager"
          ];
          key = "\\ck";
          action = "<sidebar-prev><sidebar-open>";
        }
        {
          map = ["index"];
          key = "\\Cr";
          action = "T~U<enter><tag-prefix><clear-flag>N<untag-pattern>.<enter>";
        }
        {
          map = [
            "index"
            "pager"
          ];
          key = "\\cb";
          action = "<pipe-message> urlscan<Enter>";
        }
        {
          map = [
            "attach"
            "compose"
          ];
          key = "\\cb";
          action = "<pipe-entry> urlscan<Enter>";
        }
        {
          map = [
            "index"
            "pager"
          ];
          key = "a";
          action = "<pipe-message>abook --config ~/.config/abook/abookrc --datafile ~/.local/share/notes/addressbook --add-email-quiet<return>";
        }
      ];
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

        source ~/.config/mutt/colors
        source ~/.config/mutt/gpg.rc
        source ~/.config/mutt/bindings

        color sidebar_new color221 color233

        macro index,pager 1 "<change-folder> =../gmail-tsl/inbox<enter>"
        macro index,pager 2 "<change-folder> =../purelymail/inbox<enter>"
        macro index,pager 3 "<change-folder> =../gmail-personal/inbox<enter>"
      '';
    };

    notmuch = {
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
        other_email = "peder.galteland@jottagroup.no;pederng@gmail.com;";
      };
    };

    msmtp = {
      enable = true;
      configContent = lib.mkBefore ''
        defaults
        auth on
        tls on
        tls_trust_file ${config.accounts.email.certificatesFile}
        logfile ${config.xdg.cacheHome}/msmtp.log
      '';
    };
  };

  xdg.configFile = {
    "mutt/bindings".source = ../mutt/bindings;
    "mutt/colors".source = ../mutt/colors;
    "mutt/gpg.rc".source = ../mutt/gpg.rc;
    "mutt/mailcap".source = ../mutt/mailcap;
  };
}
