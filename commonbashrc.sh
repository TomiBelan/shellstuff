# Tomi's universal bash initialization file

# shellcheck shell=bash disable=SC1091,SC2016,SC2164,SC2244,SC2250,SC2312

__shellstuff_dir=$(dirname "${BASH_SOURCE[0]}")
__shellstuff_dir=$(readlink -fv "$__shellstuff_dir")

# ----- BORROWED ---------------------------------------------------------------

# Borrowed from Fedora's /etc/skel/.bashrc.
# On Fedora, ~/.bashrc is responsible for reading /etc/bashrc. (They do not use
# the SYS_BASHRC compile option.) Hopefully this should be harmless on other
# distributions, I haven't seen anyone except Fedora using this exact filename.
# XXX: As of this writing, this was never tested. I don't use Fedora.
if [[ -f /etc/bashrc ]]; then
  source /etc/bashrc
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
  if [[ -r ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi
fi

# Borrowed from Debian/Ubuntu's /etc/skel/.bashrc.
# On Arch, Fedora and Gentoo the system bashrc file already takes care of this.
if [[ -z "$BASH_COMPLETION_VERSINFO" ]] && ! shopt -oq posix; then
  if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
  elif [[ -f /etc/bash_completion ]]; then
    source /etc/bash_completion
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

# This enables writing timestamps to .bash_history and shows them in `history`.
# It's best to set it before HISTFILESIZE.
HISTTIMEFORMAT='%F %T %z '

HISTCONTROL=ignoreboth

HISTSIZE=50000

# Using a custom history file to help prevent accidental truncation.
# TODO: Do I really want it?
#
# This dance is to avoid touching the default .bash_history file and to slightly
# optimize I/O (how many times we load it). It should work even if HISTFILESIZE
# was already set by an earlier rc file (although that shouldn't happen).
HISTFILE=
HISTFILESIZE=$HISTSIZE
HISTFILE=~/.bash_history2

if [[ -f ~/.bash_history ]] && ! [[ -f ~/.bash_history2 ]]; then
  cp -an ~/.bash_history ~/.bash_history2
fi

# `h` is a shortcut to disable history for this shell.
h () {
  HISTFILE=
}

# Press Ctrl+P to delete the most recent command from history and put it in the
# editor. Useful for fixing typos. (It only works with the most recent command
# because bash/readline doesn't tell us the currently edited history index.)
__histdelete () {
  READLINE_LINE=$(HISTTIMEFORMAT=@ history 1 | sed -r 's/^[^@]+@//')
  READLINE_POINT=${#READLINE_LINE}
  history -d -1
}
bind -x '"\C-p":__histdelete'

# Forbid altering history.
bind 'set revert-all-at-newline on'

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

# Show colors in tab completion.
bind 'set colored-completion-prefix on'
bind 'set colored-stats on'

# `exit 0` because:
# My current terminal (Wezterm) complains when bash has nonzero exit status.
# This forces bash to always exit with 0, even if the last command was "false"
# or we pressed ^C just before ^D. I'm OK with this because the exit status of
# an interactive shell isn't really meaningful.
#
# tmpfile stuff because:
# Clean up the temporary file used by our DEBUG trap below.
__shellstuff_tmpfile=
trap '[[ "$__shellstuff_tmpfile" ]] && [[ -f "$__shellstuff_tmpfile" ]] && rm -f "$__shellstuff_tmpfile"; exit 0' EXIT

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
ct() { cd "$(mktemp -d)"; }
[[ -d "$HOME/tmpt" ]] && ctt() { cd "$(TMPDIR="$HOME/tmpt" mktemp -d)"; }

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

[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || PATH=$HOME/.local/bin:$PATH
[[ ":$PATH:" == *":$__shellstuff_dir/bin:"* ]] || PATH=$__shellstuff_dir/bin:$PATH

# ----- RRPAK ------------------------------------------------------------------

eval "$("$__shellstuff_dir/rrpak" hook)"

# ----- PROMPT AND WINDOW TITLE ------------------------------------------------

# Override PROMPT_COMMAND if it was set by some earlier script.
# __debugtrap assumes the only value will be __rrprompt.
# (If something is after __rrprompt, we might think it's the user's input. If
# something is before __rrprompt, we won't detect the isstart && isend case.)
#
# Warn the user (to be safe just in case, and to be polite). But ignore known
# common values of PROMPT_COMMAND from distro /etc/ files.
#
# Fedora: https://pagure.io/setup/blob/master/f/bashrc
# Arch: https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/main/system.bashrc
# Debian/Ubuntu: just a comment in https://sources.debian.org/src/bash/latest/debian/etc.bash.bashrc/
# Gentoo: just a comment in https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/bashrc
# VTE: https://gitlab.gnome.org/GNOME/vte/-/blob/master/src/vte.sh.in
for __shellstuff_i in "${PROMPT_COMMAND[@]}"; do
  [[ $__shellstuff_i == "" ]] && continue
  [[ $__shellstuff_i =~ ^/etc/sysconfig/bash-prompt-[a-z]+$ ]] && continue
  [[ $__shellstuff_i =~ ^printf( \"[!-~]+\")+$ ]] && continue
  [[ $__shellstuff_i == __vte_osc7 ]] && continue
  [[ $__shellstuff_i == __vte_prompt_command ]] && continue
  [[ $__shellstuff_i == __rrprompt ]] && continue  # if `source ~/.bashrc`
  echo >&2 "warning: overriding PROMPT_COMMAND [${PROMPT_COMMAND[*]@Q}]"
  break
done
unset __shellstuff_i

PROMPT_COMMAND=()

source "$__shellstuff_dir/rrprompt.sh"

# ----- EXTENDED WINDOW TITLE AND SQL HISTORY ----------------------------------

__shellstuff_empty=
__shellstuff_ps0_time=
__shellstuff_ps0_wd=
__shellstuff_nextstart=
__shellstuff_lasthistory1=
__shellstuff_activeid=

# This is disgusting. See pathetic excuses in README.md.
if [[ -w "$XDG_RUNTIME_DIR" && -O "$XDG_RUNTIME_DIR" ]]; then
  __shellstuff_tmpfile=$(mktemp "$XDG_RUNTIME_DIR/shellstuff.$$.XXXXXXXXXX")
else
  __shellstuff_tmpfile=$(mktemp --tmpdir shellstuff.$$.XXXXXXXXXX)
fi

# Writes to the controlling terminal even if stdout and stderr are redirected.
# See explanation in README.md.
__debugtrap_echo () {
  printf '%s' "$1" 2>/dev/null >/dev/tty
}

__debugtrap_write_event () {
  log+=" e:[$*]"
  # TODO: To be implemented...
}

__debugtrap () {
  # Return if during prompt. -v also detects set but empty variables.
  [[ -v COMP_LINE || -v READLINE_LINE ]] && return 0

  # - for simple commands, DEBUG runs with isstart=y before it and isend=y after it.
  # - for commands that run DEBUG multiple times, isstart and isend are both false in the middle.
  # - for commands that run DEBUG zero times, afterwards it'll get both isstart=y and isend=y.
  # - at the beginning, DEBUG runs once with isend=y just before the first prompt.
  local isstart='' isend=''
  isstart=$__shellstuff_nextstart
  [[ "$BASH_COMMAND" == "__rrprompt" ]] && isend=y
  __shellstuff_nextstart=$isend

  local log="d:${isstart:-.}${isend:-.} b:${BASH_COMMAND@Q}"

  if [[ $isstart || $isend ]] && [[ "$__shellstuff_tmpfile" ]] && [[ -f "$__shellstuff_tmpfile" ]]; then
    local now=$EPOCHREALTIME

    # My obstinate avoidance of forks has led to this repulsive monstrosity.
    # Doing foo=$(history 1) performs a fork, but writing it to a temporary
    # file doesn't. See also README.md.
    local command=
    HISTTIMEFORMAT=X history 1 >"$__shellstuff_tmpfile"
    read -r -d '' command <"$__shellstuff_tmpfile"
    true >"$__shellstuff_tmpfile"

    command=${command#*X}

    log+=" h:${command@Q}"

    if [[ $isstart ]]; then
      # `history 1` can't distinguish between ignorespace, ignoredups, empty
      # commands, and ^D. See README.md. Let's use its output only if we know
      # it is really the current command. Otherwise ignore it.
      local knowcommand=
      [[ "$command" != "$__shellstuff_lasthistory1" ]] && knowcommand=$command

      [[ $knowcommand ]] && log+=' known' || log+=' unknown'

      # Show the running command in the window title.
      # (If isstart && isend, it's already over. Don't show it.)
      if [[ ! $isend && -n "$RRPROMPT_TITLE" ]]; then
        # Use the command from `history 1` if known. Otherwise fall back to
        # $BASH_COMMAND. So for e.g. ` echo a; echo b; echo c` only the first
        # command will be displayed. Not perfect, but easier to implement.
        local titlecommand="$BASH_COMMAND"
        [[ $knowcommand ]] && titlecommand=$knowcommand

        # Don't show the command if it contains \n, \e or other special chars.
        # See README.md for how that can happen. This regex should do the right
        # thing. It's true on ' ', 'aaa', 'ááá', but false on '', $'\a', $'\t',
        # $'\n', $'\r', $'\e', $'\x7f', $'\x8f', $'\xc3'.
        if [[ "$titlecommand" =~ ^[[:print:]]+$ ]]; then
          log+=" t:${titlecommand@Q}"
          __debugtrap_echo "${RRPROMPT_TITLE_PREFIX@P}$titlecommand @ ${RRPROMPT_TITLE@P}${RRPROMPT_TITLE_SUFFIX@P}"
        fi
      fi

      __shellstuff_activeid=

      # Should the command be saved to history? I.e.
      # - the command is known,
      # - HISTFILE is on,
      # - we aren't about to turn HISTFILE off.
      #
      # Note: I like ignoredups, but it's not quite ideal here. For normal Bash
      # history, ignoredups is good. For SQL history, it would be nice to keep
      # duplicates and save each run's timestamps and exit status.
      if [[ $knowcommand && $HISTFILE && ! $knowcommand =~ ^\ *(h|HISTFILE=)\ *$ ]]; then
        # $__shellstuff_ps0_time and $__shellstuff_ps0_wd might be unset if
        # PS0 wasn't displayed. See README.md for how that can happen.
        __shellstuff_activeid=$SRANDOM$SRANDOM
        __debugtrap_write_event start "$__shellstuff_activeid" "${__shellstuff_ps0_time:-$now}" "${__shellstuff_ps0_wd:-$PWD}" "$knowcommand"

        # If enabled, save each command to the Bash history file immediately
        # (before running it).
        [[ "$SHELLSTUFF_SAVE_OFTEN" ]] && history -a
      fi
    fi  # if isstart

    if [[ $isend && $__shellstuff_activeid ]]; then
      __debugtrap_write_event end "$__shellstuff_activeid" "$now" "$1"
      __shellstuff_activeid=
    fi

    __shellstuff_lasthistory1=$command

    __shellstuff_ps0_time=
    __shellstuff_ps0_wd=
  fi  # if isstart || isend

  [[ $SHELLSTUFF_TRACE ]] && __debugtrap_echo "[$log]"$'\n'

  return 0
}

PS0+='${__shellstuff_empty#${__shellstuff_ps0_time:=$EPOCHREALTIME}${__shellstuff_ps0_wd:=$PWD}}'

trap '__debugtrap $?' DEBUG
