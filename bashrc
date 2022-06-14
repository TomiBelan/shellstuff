# Tomi's universal bash initialization file

HISTCONTROL=ignoreboth
HISTSIZE=50000
HISTFILESIZE=50000

shopt -s checkwinsize  # http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)

unalias ll la 2>/dev/null
alias grep='grep --color=auto'
alias ls='ls -F --color=auto'
alias l='ls -lAh'
alias du='du -h'
alias df='df -h'
alias free='free -h'
alias m='less'
alias pskt='ps --ppid 2 -p 2 --deselect'
[ -f /usr/bin/ag ] && alias ag='ag --color-match="4;31"'

h () {
  HISTFILE=
}

export LC_COLLATE=C
export LESS=-MRi
export PS_FORMAT=pid,user,tname,start_time,args
[[ -f /usr/bin/nano ]] && export EDITOR=nano

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

[ -d ~/Sync/dotfiles/bin ] && [[ $PATH != *Sync/dotfiles/bin* ]] && export PATH="$HOME/Sync/dotfiles/bin-$HOSTNAME:$HOME/Sync/dotfiles/bin:$PATH"
[ -d ~/.bin ] && [[ $PATH != *"$HOME/.bin"* ]] && export PATH="$HOME/.bin:$PATH"

[ -f ~/goostuff/goobash ] && source ~/goostuff/goobash

__prompt () {
  local maxlen=78 template="[${HOSTNAME%%.*} ^]" title=""
  local lcolor='0;38;5;15;48;5;17' pcolor='0;1;38;5;0;48;5;81'
  [[ ${HOSTNAME%%.*} == sadaharu ]]   && pcolor='0;1;38;5;0;48;5;200'
  [[ ${HOSTNAME%%.*} == kuwadorian ]] && pcolor='0;1;38;5;0;48;5;220'
  [[ ${HOSTNAME%%.*} == deuterium ]]  && pcolor='0;1;38;5;0;48;5;202'
  [[ ${HOSTNAME%%.*} == element ]]    && pcolor='0;1;38;5;0;48;5;118'
  (( EUID == 0 )) && lcolor='0;38;5;15;48;5;52'

  local wd="${PWD/#$HOME/'~'}"; local prompt="${template/^/$wd}"
  [[ $TERM == xterm* ]] && title='\e]0;'"${HOSTNAME%%.*}:$wd"'\a'
  (( ${#prompt} > maxlen )) && wd=...${wd:${#prompt}-${maxlen}+3}
  echo -n $'\e['"$lcolor"$'m\e[K'  # ctrl+R glitches if \e[K is in PS1
  PS1='\['"$title"'\e['$pcolor'm\]'"${template/^/$wd}"'\[\e['$lcolor'm\]\$ '

  [[ $VIRTUAL_ENV ]] && PS1='\[\e[1;37;40m\]'"(${VIRTUAL_ENV##*/})$PS1"
}
export -f __prompt
PROMPT_COMMAND+=$'\n__prompt'

__debugtrap () {
  [ -n "$COMP_LINE" ] && return
  [ -z "$__inprompt" ] && return
  echo -n $'\e[0m\e[K'
  __inprompt=

  local c="$BASH_COMMAND"
  [ "$c" == "__inprompt=" ] && c=
#  echo -n "{{$c}}"
  [[ $c ]] && [[ $TERM == xterm* ]] &&
    echo -n $'\e]0;'"$c @ ${HOSTNAME%%.*}:${PWD/#$HOME/'~'}"$'\a'
}
trap __debugtrap DEBUG
PROMPT_COMMAND=$'__inprompt=\n'"$PROMPT_COMMAND"$'\n__inprompt=1'
