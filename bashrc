# Tomi's universal bash initialization file

HISTCONTROL=ignoreboth
HISTSIZE=50000
HISTFILESIZE=50000

shopt -s checkwinsize  # http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)

unalias ll la 2>/dev/null
alias grep='grep --color=auto'
alias ls='ls -F --color=auto'
alias diff='diff --color=auto'
alias l='ls -lAh'
alias du='du -h'
alias df='df -h'
alias free='free -h'
alias m='less'
alias pskt='ps --ppid 2 -p 2 --deselect'
type ag &>/dev/null && alias ag='ag --color-match="4;31"'

h () {
  HISTFILE=
}

export LC_COLLATE=C
export LESS=-MRi
export PS_FORMAT=pid,user,tname,start_time,args
type nano &>/dev/null && export EDITOR=nano

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

[ -d ~/Sync/dotfiles/bin ] && [[ $PATH != *Sync/dotfiles/bin* ]] && export PATH="$HOME/Sync/dotfiles/bin-$HOSTNAME:$HOME/Sync/dotfiles/bin:$PATH"
[ -d ~/.bin ] && [[ $PATH != *"$HOME/.bin"* ]] && export PATH="$HOME/.bin:$PATH"

[ -f ~/goostuff/goobash ] && source ~/goostuff/goobash

__prompt () {
  local maxlen=78 template="[${HOSTNAME%%.*} ^]"
  local lcolor='0;38;5;15;48;5;17' pcolor='0;1;38;5;0;48;5;81'
  [[ ${HOSTNAME%%.*} == sadaharu ]]   && pcolor='0;1;38;5;0;48;5;200'
  [[ ${HOSTNAME%%.*} == kuwadorian ]] && pcolor='0;1;38;5;0;48;5;220'
  [[ ${HOSTNAME%%.*} == deuterium ]]  && pcolor='0;1;38;5;0;48;5;202'
  [[ ${HOSTNAME%%.*} == element ]]    && pcolor='0;1;38;5;0;48;5;118'
  (( EUID == 0 )) && lcolor='0;38;5;15;48;5;52'

  local wd="${PWD/#$HOME/'~'}"; local prompt="${template/^/$wd}"
  (( ${#prompt} > maxlen )) && wd=...${wd:${#prompt}-${maxlen}+3}
  echo -n $'\e['"$lcolor"$'m\e[K'  # ctrl+R glitches if \e[K is in PS1
  PS1='\[\e['$pcolor'm\]'"${template/^/$wd}"'\[\e['$lcolor'm\]\$ '

  [[ $VIRTUAL_ENV ]] && PS1='\[\e[1;37;40m\]'"(${VIRTUAL_ENV##*/})$PS1"
}
[[ "$PROMPT_COMMAND" ]] && echo >&2 "overriding PROMPT_COMMAND [$PROMPT_COMMAND]"
PROMPT_COMMAND='__prompt'   # __debugtrap needs this to be the only thing

PS0=$'\e[0m\e[K'

__debugtrap () {
  [ -n "$COMP_LINE" ] && return 0
  [ -n "$READLINE_LINE" ] && return 0

  # this runs
  # - before showing prompt (BASH_COMMAND is __prompt)
  # - before each of aa, bb, cc if the user executes "aa; bb; cc"
  # - not at all before "(aa; bb; cc)" (I don't like the functrace+extdebug hack)

  # show window title.
  if [[ -t 1 ]] && [[ $TERM == xterm* ]]; then
    local c="$BASH_COMMAND @ "
    [[ $BASH_COMMAND == __prompt ]] && c=''
    echo -n $'\e]0;'"$c${HOSTNAME%%.*}:${PWD/#$HOME/'~'}"$'\a'
  fi

  # on goostuff, always save history immediately (effectively after every prompt)
  [ -f ~/goostuff/goobash ] && [ "$HISTFILE" ] && ! [[ "$BASH_COMMAND" =~ ^\ *(h|HISTFILE=)\ *$ ]] && history -a

  # send history information to historywriter.
  local etype=run
  [[ "$BASH_COMMAND" == "__prompt" ]] && etype=end
  [ "$HISTFILE" ] && [ "$__history_shellid" ] && __history_write "$etype" "$1"
  return 0
}
trap '__debugtrap $?' DEBUG
