# Tomi's universal bash initialization file

# ----- BORROWED ---------------------------------------------------------------

# Borrowed from Fedora's /etc/skel/.bashrc.
# On Fedora, ~/.bashrc is responsible for reading /etc/bashrc. (They do not use
# the SYS_BASHRC compile option.) Hopefully this should be harmless on other
# distributions, I haven't seen anyone except Fedora using this exact filename.
# XXX: As of this writing, this was never tested. I don't use Fedora.
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Not borrowing Fedora's ~/.bashrc.d/* because I don't think I'll need it.

# Borrowed from Ubuntu's /etc/skel/.bashrc. Should also work on Debian.
# It sets LESSOPEN and LESSCLOSE.
# On Arch, Fedora, and Gentoo, LESSOPEN should be already set by /etc/profile.d
# or /etc/env.d, and it might be named `lesspipe.sh` anyway.
[[ -z "$LESSOPEN" ]] && type lesspipe &>/dev/null && eval "$(lesspipe)"

# Borrowed from Debian/Ubuntu's /etc/skel/.bashrc. Should also work on Arch.
# It sets LS_COLORS.
# On Fedora and Gentoo the system bashrc file already takes care of this.
if [[ -z "$LS_COLORS" ]] && [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Borrowed from Debian/Ubuntu's /etc/skel/.bashrc.
# On Arch, Fedora and Gentoo the system bashrc file already takes care of this.
if [[ -z "$BASH_COMPLETION_VERSINFO" ]] && ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Not borrowing Debian/Ubuntu's /etc/debian_chroot in PS1 because that file
# seems to be only created by `schroot`.

# Borrowed from Ubuntu's /etc/skel/.bashrc.
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# ----- HISTORY ----------------------------------------------------------------

# See explanation in README.md.
if [[ $HISTFILESIZE != "" ]] && [[ -t 2 ]]; then
  echo >&2 "commonbashrc.sh warning: HISTFILESIZE was already set to $HISTFILESIZE by some earlier rc script! This truncates the history in $HISTFILE."
fi

HISTCONTROL=ignoreboth
HISTSIZE=50000
HISTFILESIZE=50000

# This enables writing timestamps to .bash_history and shows them in `history`.
HISTTIMEFORMAT='%F %T %z '

# `h` is a shortcut to disable history for this shell.
h () {
  HISTFILE=
}

# ----- SHELL OPTIONS ----------------------------------------------------------

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.
# Updated links:
#   https://bugs.gentoo.org/65623
#   https://tiswww.case.edu/php/chet/bash/FAQ (E11)
shopt -s checkwinsize

# histappend is almost always meaningless, but we might as well enable it.
# Everyone online is wrong about it, except these links:
#   https://unix.stackexchange.com/a/428208
#   https://lists.gnu.org/archive/html/help-bash/2016-05/msg00022.html
# histappend only matters when (num commands entered this session) > $HISTSIZE && $HISTFILESIZE > $HISTSIZE.
#   suppose HISTSIZE=5, HISTFILESIZE=100, and you run 10 commands and log out:
#   if histappend is off, HISTFILE will contain only the last 5 commands from this session.
#   if histappend is on, HISTFILE will contain 95 old commands and the last 5 commands from this session.
shopt -s histappend

# Obvious improvement, ought to be enabled by default.
shopt -s checkhash

# Disable history substitution with `!`. I don't think I ever used it on purpose.
set +H

# My current terminal (Wezterm) complains when bash has nonzero exit status.
# This forces bash to always exit with 0, even if the last command was "false"
# or we pressed ^C just before ^D. I'm OK with this because the exit status of
# an interactive shell isn't really meaningful.
trap 'exit 0' EXIT

# ----- ALIASES ----------------------------------------------------------------

unalias ll la 2>/dev/null
alias grep='grep --color=auto'
alias ls='ls -F --color=auto'
alias diff='diff --color=auto'
alias l='ls -lAh'
alias du='du -h'
alias df='df -h'
alias free='free -h'
alias m='less'
# `pskt` lists all processes except kernel threads (descendants of PID 2).
alias pskt='ps --ppid 2 -p 2 --deselect'
type ag &>/dev/null && alias ag='ag --color-match="4;31"'

# ----- VARIABLES --------------------------------------------------------------

# Good for `ls` (case sensitive sort) and `bash` (case sensitive [A-Z] globs).
# It could also be solved with `alias ls=...` and `shopt -s globasciiranges`,
# but exporting LC_COLLATE=C for all programs is probably a saner default.
export LC_COLLATE=C

export LESS=-MRi

# The pager options used by systemctl and journalctl. This won't work with
# `sudo systemctl`, but it's better than nothing.
# The default value is FRSXMK. I removed X (no longer necessary with -F in less
# 489+). I removed K (I don't want it). I added i.
export SYSTEMD_LESS=FRSMi

# Change default columns shown by `ps`.
# But note that this disables the STAT and TIME columns.
# If you need them, run ps with: `PS_FORMAT= ps ...`
export PS_FORMAT=pid,user,tname,start_time,args

type nano &>/dev/null && export EDITOR=nano

[ -d ~/Sync/dotfiles/bin ] && [[ $PATH != *Sync/dotfiles/bin* ]] && export PATH="$HOME/Sync/dotfiles/bin-$HOSTNAME:$HOME/Sync/dotfiles/bin:$PATH"
[ -d ~/.bin ] && [[ $PATH != *"$HOME/.bin"* ]] && export PATH="$HOME/.bin:$PATH"

# ----- PROMPT AND WINDOW TITLE ------------------------------------------------

# Note: As a self imposed restriction / challenge, I don't want to fork any
# unnecessary processes. If I run `ps` twice, they should have successive PIDs.
# This means I can't use process substitution in PS1 (at least as of Bash 5.1).

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

  # if enabled, save each command to the history file immediately (before running it).
  [[ "$SHELLSTUFF_SAVE_OFTEN" ]] && [[ "$HISTFILE" ]] && ! [[ "$BASH_COMMAND" =~ ^\ *(h|HISTFILE=)\ *$ ]] && history -a

  # send history information to historywriter.
  local etype=run
  [[ "$BASH_COMMAND" == "__prompt" ]] && etype=end
  [ "$HISTFILE" ] && [ "$__history_shellid" ] && __history_write "$etype" "$1"
  return 0
}
trap '__debugtrap $?' DEBUG
