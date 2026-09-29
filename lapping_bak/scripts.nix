{pkgs, ...}: let
  capbak = pkgs.writeShellApplication {
    name = "capbak";
    text = ''
      test -f "$HOME"/workspace/capture-backend/bin/capbak || exit 0
      "$HOME"/workspace/capture-backend/bin/capbak "$@"
    '';
  };

  mimir = pkgs.writeShellApplication {
    name = "mimir";
    text = ''
      test -f "$HOME"/workspace/capture-backend/bin/mimir || exit 0
      "$HOME"/workspace/capture-backend/bin/mimir "$@"
    '';
  };

  search = pkgs.writeShellApplication {
    name = "search";
    text = ''
      test -f "$HOME"/workspace/capture-backend/bin/search || exit 0
      "$HOME"/workspace/capture-backend/bin/search "$@"
    '';
  };
in {
  home.packages = [
    capbak
    mimir
    search
  ];
}
