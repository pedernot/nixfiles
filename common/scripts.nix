{pkgs, ...}: let
  fzfmenu = pkgs.writeShellApplication {
    name = "fzfmenu";
    runtimeInputs = [pkgs.coreutils pkgs.foot pkgs.fzf];
    text = ''
      input=$(mktemp -u --suffix .fzfmenu.input)
      output=$(mktemp -u --suffix .fzfmenu.output)
      mkfifo "$input"
      mkfifo "$output"
      chmod 600 "$input" "$output"

      # shellcheck disable=SC2086
      foot -a fzfmenu -T launcher -W 200x30 sh -c "cat $input | fzf $* | tee $output" & disown

      trap 'kill $! 2>/dev/null; rm -f "$input" "$output"' EXIT

      cat > "$input"
      cat "$output"
    '';
  };

  fzflaunch = pkgs.writeShellApplication {
    name = "fzflaunch";
    runtimeInputs = [pkgs.dmenu pkgs.fzf fzfmenu];
    text = ''
      dmenu_path | fzfmenu --prompt "run\> " +m | ''${SHELL:-"/bin/sh"} &
    '';
  };

  fpass = pkgs.writeShellApplication {
    name = "fpass";
    runtimeInputs = [pkgs.fzf pkgs.pass pkgs.xdotool fzfmenu];
    text = ''
      shopt -s nullglob globstar

      typeit=0
      if [[ ''${1:-} == "--type" ]]; then
        typeit=1
        shift
      fi

      prefix=''${PASSWORD_STORE_DIR-~/.password-store}
      password_files=( "$prefix"/**/*.gpg )
      password_files=( "''${password_files[@]#"$prefix"/}" )
      password_files=( "''${password_files[@]%.gpg}" )

      password=$(printf '%s\n' "''${password_files[@]}" | fzfmenu "$@")
      [[ -n "$password" ]] || exit 0

      if [[ "$typeit" -eq 0 ]]; then
        pass show -c "$password" 2>/dev/null
      else
        pass show "$password" | { IFS= read -r passline; printf '%s' "$passline"; } |
          xdotool type --clearmodifiers --file -
      fi
    '';
  };
in {
  home.packages = [
    fzfmenu
    fzflaunch
    fpass
  ];
}
