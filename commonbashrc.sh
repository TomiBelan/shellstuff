# Tomi's universal bash initialization file

HISTCONTROL=ignoreboth
HISTSIZE=50000
HISTFILESIZE=50000

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.
# Updated links:
#   https://bugs.gentoo.org/65623
#   https://tiswww.case.edu/php/chet/bash/FAQ (E11)
shopt -s checkwinsize

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

# Good for `ls` (case sensitive sort) and `bash` (case sensitive [A-Z] globs).
# It could also be solved with `alias ls=...` and `shopt -s globasciiranges`,
# but exporting LC_COLLATE=C for all programs is probably a saner default.
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
  __shellstuff_promptcolors="[0;1;38;5;16;48;5;$(( ${#HISTFILE} == 0 ? 248 : ${SHELLSTUFF_PROMPT_COLOR:-81} ))m"
  __shellstuff_linecolors="[0;38;5;231;48;5;$(( ${#HISTFILE} == 0 ? 235 : EUID == 0 ? 52 : 17 ))m"

  local maxlen=80 wd='\w'
  wd=${wd@P}
  (( ${#wd} > maxlen )) && wd=...${wd:${#wd}-${maxlen}+3}
  __shellstuff_prompttext="[${HOSTNAME%%.*} $wd]"

  # ctrl+R glitches if \e[K is in PS1
  echo -n $'\e'"$__shellstuff_linecolors"$'\e[K' >&2
}
[[ "$PROMPT_COMMAND" ]] && echo >&2 "overriding PROMPT_COMMAND [$PROMPT_COMMAND]"
PROMPT_COMMAND='__prompt'   # __debugtrap needs this to be the only thing

PS1='\[\e${__shellstuff_promptcolors}\]${__shellstuff_prompttext}\[\e${__shellstuff_linecolors}\]\$ '
PS0='\[\e[0m\e[K\]'

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
