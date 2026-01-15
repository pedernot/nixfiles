_: {
  wayland.windowManager.sway = {
    config = {
      output = {
        "eDP-1" = {
          scale = "1.2";
        };
      };
      input = {
        "2:7:SynPS/2_Synaptics_TouchPad" = {
          dwt = "enabled";
          tap = "enabled";
          middle_emulation = "enabled";
        };
      };
    };
  };
}
