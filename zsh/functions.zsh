function fkill() {
  local signal pids

  signal="${1:-9}"
  pids=$(ps -ef | sed 1d | fzf -m | awk '{print $2}') || return 0
  [[ -n "$pids" ]] || return 0

  printf '%s\n' "$pids" | xargs -r kill -"$signal"
}

function _update_agents {
  local force cooldown socket

  force=${1:-0}
  cooldown=60

  [[ -n "$SSH_CONNECTION" ]] && return
  (( $+commands[gpg-connect-agent] )) || return
  (( $+commands[gpgconf] )) || return
  (( $+commands[timeout] )) || return

  typeset -gi _AGENTS_LAST_REFRESH
  if (( force == 0 )) && (( EPOCHSECONDS - _AGENTS_LAST_REFRESH < cooldown )); then
    return
  fi
  _AGENTS_LAST_REFRESH=$EPOCHSECONDS

  export SSH_AUTH_SOCK
  SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  [[ -n "$SSH_AUTH_SOCK" ]] || return

  if ! timeout -k 2 1 gpg-connect-agent updatestartuptty /bye > /dev/null; then
    echo "Removing stale GPG agent"
    socket="$(gpgconf --list-dirs agent-socket)"
    test -S "$socket" && rm "$socket"
    if (( $+commands[killall] )); then
      killall -KILL gpg-agent 2>/dev/null
    fi
    timeout -k 2 1 gpg-connect-agent updatestartuptty /bye > /dev/null
  fi
}

function agents_refresh {
  _update_agents 1
}

function _tmux_update_env {
  local line key value

  [[ -n "$TMUX" ]] || return

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    if [[ "$line" == -* ]]; then
      unset "${line#-}"
      continue
    fi

    key="${line%%=*}"
    value="${line#*=}"
    export "$key=$value"
  done < <(tmux show-environment DISPLAY SSH_CONNECTION SSH_AUTH_SOCK 2>/dev/null || true)
}
