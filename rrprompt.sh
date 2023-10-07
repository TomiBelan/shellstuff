# Tomi's fancy bash prompt

# Customization:
# If you want to...              ...then run (and add to your .bashrc):
# * change the main color --------> RRPROMPT_COLOR=47
# * disable the line background --> RRPROMPT_LINE_COLORS=''
# * disable the window title -----> RRPROMPT_TITLE=''
# * add a clock (not animated) ---> RRPROMPT_TEXT='[\t \h ${RRPROMPT_SHORTCWD}]'
#
# There are more variables that can be customized below.
# Useful links:
# https://man7.org/linux/man-pages/man1/bash.1.html#PROMPTING
# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit

# shellcheck shell=bash disable=SC2016,SC1003

# Sanity checks.
test -z "${BASH_VERSION-}" && return 0
[[ $- != *i* ]] && return 0

# Initialize variables (unless already set).
[[ -v RRPROMPT_COLOR ]]         || RRPROMPT_COLOR=81
[[ -v RRPROMPT_PROMPT_COLORS ]] || RRPROMPT_PROMPT_COLORS='\e[0;1;38;5;16;48;5;$(( ${#HISTFILE} == 0 ? 248 : RRPROMPT_COLOR ))m'
[[ -v RRPROMPT_LINE_COLORS ]]   || RRPROMPT_LINE_COLORS='\e[0;38;5;231;48;5;$(( ${#HISTFILE} == 0 ? 235 : EUID == 0 ? 52 : 17 ))m'
[[ -v RRPROMPT_TEXT ]]          || RRPROMPT_TEXT='[\h ${RRPROMPT_SHORTCWD}]'
[[ -v RRPROMPT_TITLE ]]         || RRPROMPT_TITLE='\h:\w'
[[ -v RRPROMPT_CWD_LIMIT ]]     || RRPROMPT_CWD_LIMIT=70

RRPROMPT_TITLE_PREFIX='\e]0;'
RRPROMPT_TITLE_SUFFIX='\e\\'
RRPROMPT_SHORTCWD=''

__rrprompt () {
  local wdp='\w'
  RRPROMPT_SHORTCWD=${wdp@P}
  (( ${#RRPROMPT_SHORTCWD} > RRPROMPT_CWD_LIMIT )) && RRPROMPT_SHORTCWD=...${RRPROMPT_SHORTCWD:${#RRPROMPT_SHORTCWD} - RRPROMPT_CWD_LIMIT + 3}

  # Erase the line and fill it with the background color.
  # Must be here because Ctrl+R (history search) can glitch if \e[K is in PS1.
  if [[ -n "${RRPROMPT_LINE_COLORS:-}" ]]; then
    printf '%s' "${RRPROMPT_LINE_COLORS@P}"$'\e[K' >&2
  fi
}

PROMPT_COMMAND+=(__rrprompt)

PS1='\[${RRPROMPT_TITLE:+${RRPROMPT_TITLE_PREFIX@P}${RRPROMPT_TITLE@P}${RRPROMPT_TITLE_SUFFIX@P}}${RRPROMPT_PROMPT_COLORS@P}\]${RRPROMPT_TEXT@P}\[\e[0m${RRPROMPT_LINE_COLORS@P}\]\$ '

PS0='\e[0m\e[K'

# Implementation notes:

# More useful links:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
# https://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html
# https://man7.org/linux/man-pages/man4/console_codes.4.html
# https://terminalguide.namepad.de/attr/
# https://terminalguide.namepad.de/seq/a_esc_zhash_a8/ <-- Wow!

# As a self imposed restriction / challenge, I don't want to fork any
# unnecessary processes. If I run `ps` twice, they should have successive PIDs.
# So the default configuration doesn't use command substitution or any external
# programs. As of Bash 5.1, even shell functions and builtins in $( ) will fork.
# Of course, users can add $( ... ) to RRPROMPT_TEXT in their own .bashrc.

# Let's not check $TERM, $COLORTERM etc. I think nowadays it's best to assume
# that all terminals support at least 256 colors and OSC 0 to set title, or at
# least they can harmlessly ignore it. E.g. the linux console:
# https://github.com/torvalds/linux/commit/cec5b2a97a11ade56a701e83044d0a2a984c67b4
# -
# The Arch Linux system bashrc has a special case for `screen` here, but in fact
# I tried the latest `screen` and it supports `\e]0;` (OSC 0) just fine.
# https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/main/system.bashrc
# https://www.gnu.org/software/screen/manual/screen.html#Hardstatus
# -
# Regarding \e\\ (ST) vs \a (BEL), it seems ST is more standard.
# https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#:~:text=BEL%20%20or%20ST
# https://man7.org/linux/man-pages/man4/console_codes.4.html#:~:text=a%20BEL%20to

# PS0 should *not* contain \[ and \]. Bash prints them as '\001' and '\002'.
# Windows Terminal displays them as rectangle characters. Reason: \[, \] are
# internally translated to RL_PROMPT_START_IGNORE and RL_PROMPT_END_IGNORE.
# That's fine for PS1 which is given to readline, but PS0 is just printed.
