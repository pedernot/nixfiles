_: {
  imports = [
    ./ssh.nix
    ./version_control.nix
    ./terminal.nix
  ];

  programs.home-manager.enable = true;
}
