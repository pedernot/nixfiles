{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = ["btrfs"];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  hardware = {
    enableAllFirmware = true;
    graphics.enable = true;
    nvidia = {
      open = true;
      nvidiaSettings = true;
      modesetting.enable = true;
      # Apply CachyOS kernel 6.19 patch to NVIDIA latest driver
      package = let
        base = config.boot.kernelPackages.nvidiaPackages.latest;
        cachyos-nvidia-patch = pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/master/nvidia/nvidia-utils/kernel-6.19.patch";
          sha256 = "sha256-YuJjSUXE6jYSuZySYGnWSNG5sfVei7vvxDcHx3K+IN4=";
        };

        # Patch the appropriate driver based on config.hardware.nvidia.open
        driverAttr =
          if config.hardware.nvidia.open
          then "open"
          else "bin";
      in
        base
        // {
          ${driverAttr} = base.${driverAttr}.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or []) ++ [cachyos-nvidia-patch];
          });
        };
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.hostName = "heisenberg";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Oslo";

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam.services.waylock = {};
  };

  virtualisation.docker.enable = true;

  programs = {
    nix-ld.enable = true;
    gnupg.agent.enable = true;
    zsh.enable = true;
    steam.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.hack
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts
  ];

  services = {
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber = {
        enable = true;
        extraConfig = {
          "disable-v4l2" = {
            "wireplumber.profiles" = {
              "main" = {"monitor.v4l2" = "disabled";};
            };
          };
        };
      };
    };
    hardware.bolt.enable = true;
    resolved.enable = true;
    printing = {
      enable = true;
      drivers = [pkgs.cnijfilter_2_80];
    };
    xserver.videoDrivers = ["nvidia"];
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [];
    config.common.default = "*";
  };

  users.users.peder = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "docker"];
    shell = pkgs.zsh;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
