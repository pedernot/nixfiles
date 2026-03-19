function fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}

function _update_agents {
    # take over SSH keychain (with gpg-agent soon) but only on local machine, not remote ssh machine
    # keychain used in a non-invasive way where it's up to you to add your keys to the agent.
    if [ ! "$SSH_CONNECTION" ] && which gpg-connect-agent &>/dev/null; then
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs | grep agent-ssh-socket | cut -f 2 -d :)
        # start GPG agent, and update TTY. For the former only, omit updatestartuptty
        # ssh-agent protocol can't tell gpg-agent/pinentry what tty to use, so tell it
        # if GPG agent has locked up or there is a stale remote agent, remove
        # the stale socket and possible local agent.
        if ! timeout -k 2 1 gpg-connect-agent updatestartuptty /bye > /dev/null; then
            echo "Removing stale GPG agent"
            socket=$(gpgconf --list-dirs | grep agent-socket | cut -f 2 -d :)
            test -S $socket && rm $socket
            killall -KILL gpg-agent 2> /dev/null
            # try again
            timeout -k 2 1 gpg-connect-agent updatestartuptty /bye > /dev/null
        fi
    fi
}

function _tmux_update_env {
        # tmux must be running
        [ "$TMUX" ] || return

        # update current shell to parent tmux shell (useful for new SSH connections, x forwarding, etc)
        eval $(tmux show-environment -s | grep 'DISPLAY\|SSH_CONNECTION\|SSH_AUTH_SOCK')
    }
