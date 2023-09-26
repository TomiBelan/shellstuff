# Tomi's fancy bash prompt

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

# PS0 should *not* contain \[ and \]. Bash prints them as '\001' and '\002'.
# Windows Terminal displays them as rectangle characters. Reason: \[, \] are
# internally translated to RL_PROMPT_START_IGNORE and RL_PROMPT_END_IGNORE.
# That's fine for PS1 which is given to readline, but PS0 is just printed.
PS0='\e[0m\e[K'
