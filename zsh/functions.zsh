function fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}

function _update_agents {
  local force=${1:-0}
  local cooldown=60

  [[ -n "$SSH_CONNECTION" ]] && return
  (( $+commands[gpg-connect-agent] )) || return
  (( $+commands[gpgconf] )) || return

  typeset -gi _AGENTS_LAST_REFRESH
  if (( force == 0 )) && (( EPOCHSECONDS - _AGENTS_LAST_REFRESH < cooldown )); then
    return
  fi
  _AGENTS_LAST_REFRESH=$EPOCHSECONDS

  export SSH_AUTH_SOCK
  SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"

  if ! timeout -k 2 1 gpg-connect-agent updatestartuptty /bye > /dev/null; then
    local socket
    echo "Removing stale GPG agent"
    socket="$(gpgconf --list-dirs agent-socket)"
    test -S "$socket" && rm "$socket"
    killall -KILL gpg-agent 2>/dev/null
    timeout -k 2 1 gpg-connect-agent updatestartuptty /bye > /dev/null
  fi
}

function agents_refresh {
  _update_agents 1
}

function _tmux_update_env {
  [[ -n "$TMUX" ]] || return
  eval "$(tmux show-environment -s | grep 'DISPLAY\|SSH_CONNECTION\|SSH_AUTH_SOCK')"
}
