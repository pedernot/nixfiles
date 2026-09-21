{lib, ...}: {
  programs.zsh.initContent = lib.mkAfter ''
    # Lazy-loading completion wrappers
    if (( $+commands[pip] )); then
      pip() {
        unfunction "$0"
        eval "$(pip completion --zsh)"
        $0 "$@"
      }
    fi

    if (( $+commands[jj] )); then
      jj() {
        unfunction "$0"
        source <(COMPLETE=zsh jj)
        $0 "$@"
      }
    fi

    if (( $+commands[uv] )); then
      uv() {
        unfunction "$0"
        eval "$(uv --generate-shell-completion zsh)"
        $0 "$@"
      }
    fi

    if (( $+commands[kubectl] )); then
      kubectl() {
        unfunction "$0"
        eval "$(kubectl completion zsh)"
        $0 "$@"
      }
    fi
  '';
}
