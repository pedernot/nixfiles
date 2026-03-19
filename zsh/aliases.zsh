#Utilities
alias grep='grep --color=auto'
alias cp='cp -iv'
alias rm='rm -iv --one-file-system'
alias mv='mv -iv'
alias mkdir='mkdir -p -v'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias tnew='new-tmux-from-dir-name'
alias tree='tree -C'

#ls
alias ls='ls -hF --color=auto'
alias lr='ls -R'                    # recursive ls
alias ll='ls -l'
alias la='ll -A'
alias lx='ll -BX'                   # sort by extension
alias lz='ll -rS'                   # sort by size
alias lt='ll -rt'                   # sort by date
alias lm='la | more'

alias gpgreset="gpg-connect-agent updatestartuptty /bye"

alias https='http --default-scheme=https'

alias mutt='neomutt'

alias startx="startx $XINITRC"
alias tmux="tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf"

alias mbsync="mbsync -c "$XDG_CONFIG_HOME"/isync/mbsyncrc"
alias abook="abook --config "$XDG_CONFIG_HOME"/abook/abookrc --datafile "$XDG_DATA_HOME"/notes/addressbook"
alias wget="wget --hsts-file='$XDG_CACHE_HOME/wget-hsts'"

alias bat="bat --theme='base16'"

alias j=zi

alias k=kubectl
alias kctx=kubectx
alias kns=kubens
