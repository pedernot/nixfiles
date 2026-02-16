_: {
  # nixpkgs = {
  #   overlays = [
  #     inputs.neovim-nightly-overlay.overlays.default
  #   ];
  # };
  imports = [
    ./ssh.nix
    ./version_control.nix
    ./terminal.nix
    ./nvim.nix
    ./gpg.nix
    ./email.nix
    ./rss.nix
  ];
  programs = {
    home-manager.enable = true;
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 5d --keep 3";
      };
      flake = "/home/peder/workspace/nixfiles";
    };
  };
}
