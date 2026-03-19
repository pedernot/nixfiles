{lib, ...}: {
  programs.zsh.initContent = lib.mkAfter ''
    if (( ($+commands[capbak] || $+commands[mimir] || $+commands[search]) && !$+functions[complete] )); then
      autoload -U bashcompinit
      bashcompinit
    fi

    if (( $+commands[capbak] )); then
      eval "$(capbak completion)"
    fi
    if (( $+commands[mimir] )); then
      eval "$(mimir completion)"
    fi
    if (( $+commands[search] )); then
      eval "$(search completion)"
    fi
  '';
}
