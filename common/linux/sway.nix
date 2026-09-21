{
  lib,
  pkgs,
  ...
}: {
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.waylock}/bin/waylock";
      }
    ];
  };

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    config = rec {
      modifier = "Mod4";

      startup = [
        {
          command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
          always = true;
        }
        {
          command = "dbus-update-activation-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
          always = true;
        }
      ];

      bars = [
        {
          position = "top";
          statusCommand = "while date +'%Y-%m-%d %H:%M'; do sleep 1; done";
          colors = {
            statusline = "#ffffff";
            background = "#323232";
            inactiveWorkspace = {
              background = "#32323200";
              border = "#32323200";
              text = "#5c5c5c";
            };
          };
        }
      ];

      floating.criteria = [
        {app_id = "fzfmenu";}
        {class = "Pavucontrol";}
      ];

      window.titlebar = false;

      seat = {
        "*" = {
          hide_cursor = "3000";
        };
      };

      keybindings = lib.mkOptionDefault {
        "${modifier}+Shift+c" = "kill";
        "${modifier}+Shift+r" = "reload";
        "${modifier}+Shift+s" = "exec waylock";
        "${modifier}+p" = "exec fzflaunch";
        # this seems hacky
        "--locked XF86AudioMicMute" = "exec sp"; # HHKB eject key
        "--locked XF86AudioPlay" = "exec sp";
        "--locked XF86AudioMute" = "exec wpctl set-mute \@DEFAULT_SINK@ toggle";
        "--locked XF86AudioLowerVolume" = "exec pactl set-sink-volume \@DEFAULT_SINK@ 5%-";
        "--locked XF86AudioRaiseVolume" = "exec pactl set-sink-volume \@DEFAULT_SINK@ 5%+";
      };

      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
          xkb_options = "ctrl:nocaps";
        };
      };
    };
    extraConfig = ''
      set $XDG_CURRENT_DESKTOP sway
    '';
  };
}
