_: {
  imports = [
    ./ssh.nix
    ./version_control.nix
    ./terminal.nix
    ./nvf.nix
  ];

  programs.home-manager.enable = true;
}
