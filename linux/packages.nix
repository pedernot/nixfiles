{pkgs, ...}: {
  home.packages = with pkgs; [
    acpi
    alsa-utils
    brightnessctl
    dmenu
    dmenu-wayland
    firefox
    gcc
    grim
    handlr
    k3s
    libcamera
    libnotify
    pinentry-qt
    powertop
    ps_mem
    pwvucontrol
    slurp
    spotify
    strace
    swayimg
    waylock
    wl-clipboard
    xclip
    xdg-utils
  ];
}
