# My Bash shell stuff

## commonbashrc.sh

This is my personal Bash initialization file. It is public to make it easier to use from multiple computers. I don't expect anybody else to use it, but it might be good for inspiration.

**Installation:**

```bash
git clone https://github.com/TomiBelan/shellstuff.git
./shellstuff/install_shellstuff
```

You can rename or move the directory if you prefer. The `install_shellstuff` script will do three things: 1. Report whether /etc/skel/.bashrc has a known good hash. 2. Report whether ~/.bashrc is equal to /etc/skel/.bashrc and print any differences. 3. Offer to replace the whole content of ~/.bashrc with this code:

```bash
[[ $- != *i* ]] && return  # Stop if not interactive. Explained in shellstuff/README.md.

source ~/shellstuff/commonbashrc.sh
```

**Customization:**

You can change the main prompt color by adding e.g. `RRPROMPT_COLOR=47` to ~/.bashrc. See rrprompt.sh for more.

## rrprompt.sh

This is my bash prompt. It is a part of commonbashrc.sh, but it can also be used on its own. Just download rrprompt.sh and `source` it in your ~/.bashrc.

Its main attraction is that the whole line is highlighted with a background color, not just the prompt but also the command area where you type. The highlight makes it very easy to see where commands begin and end.

Other than that, it's a pretty minimal one-line prompt. There is no version control integration, memory usage, battery level, weather, etc.

For comparison, [this page](https://liquidprompt.readthedocs.io/en/latest/overview.html#competitors) looks like a decent overview of the competition.

## Explanations

### Why should .bashrc check for interactive shells? (`[[ $- != *i* ]]`)

Does Bash even read .bashrc if the shell is not interactive? Usually no. But there is one edge case: if Bash is started by sshd with a `-c` command, it may run some rc files even though it's not interactive.

From [bash(1)](https://man.archlinux.org/man/bash.1):

> **Bash** attempts to determine when it is being run with its standard input connected to a network connection, as when executed by the remote shell daemon, usually _rshd_, or the secure shell daemon _sshd_. If **bash** determines it is being run in this fashion, it reads and executes commands from _~/.bashrc_, if that file exists and is readable. It will not do this if invoked as **sh**. The **--norc** option may be used to inhibit this behavior, and the **--rcfile** option may be used to force another file to be read, but neither _rshd_ nor _sshd_ generally invoke the shell with those options or allow them to be specified.

Implementation details: This is handled in [run_startup_files() in bash](https://github.com/bminor/bash/blob/ec8113b9861375e4e17b3307372569d429dec814/shell.c#L1136) and works by checking for `$SSH_CLIENT` or `$SSH_CLIENT2`. It is toggled by the compile time option SSH_SOURCE_BASHRC, which is enabled on [Debian](https://sources.debian.org/src/bash/latest/debian/patches/deb-bash-config.diff/), [Ubuntu](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/patches/deb-bash-config.diff), [Fedora](https://src.fedoraproject.org/rpms/bash/blob/rawhide/f/bash-3.2-ssh_source_bash.patch), and [Gentoo](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/bash-9999.ebuild#:~:text=DSSH_SOURCE_BASHRC), but not on [Arch](https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/main/PKGBUILD) or in upstream Bash. It is true that sshd does not give Bash any extra options: when a command is given to ssh, [do_child() in sshd](https://github.com/openssh/openssh-portable/blob/3c6ab63b383b0b7630da175941e01de9db32a256/session.c#L1705) will run `/bin/bash -c 'some command'` with no other arguments. It also doesn't matter whether the ssh connection has a pseudoterminal (pty) or not.

I think this behavior is unexpected and usually not what I want, so it's better to `return` immediately.

The default /etc/skel/.bashrc files on [Debian](https://sources.debian.org/src/bash/5.2.15-2/debian/skel.bashrc/#L5), [Ubuntu](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/skel.bashrc?id=f4a6a7f308779b118b4e8efecb87d4ad86f2d587#n5), [Arch](https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/6c4e8435a132bbf5924055e6e940e9a5bc95e0bf/dot.bashrc#L5) and [Gentoo](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/dot-bashrc?id=56bd759df1d0c750a065b8c845e93d5dfa6b549d#n9) also have an early `return`. [Fedora](https://src.fedoraproject.org/rpms/bash/blob/b05f1d7a2338ad5f398190370e415a795d792d46/f/dot-bashrc) does not, but it at least tries to silence output in /etc/profile and /etc/bashrc.

For completeness: Bash also reads SYS_BASHRC in this scenario. It is `/etc/bash.bashrc` on Debian, Ubuntu and Arch, `/etc/bash/bashrc` on Gentoo, and is not set on Fedora. Fortunately, those files also contain an early `return`.

### Bash history variables

- HISTSIZE has a setter function which truncates the in-memory history list. This is usually irrelevant because the in-memory history list is usually empty while running rc files.
- HISTFILESIZE has a setter function which immediately _performs truncation_. That means: it loads the file currently named in $HISTFILE, and if it is too long, makes it shorter. The in-memory history list is mostly unaffected, I think. The current value of $HISTTIMEFORMAT affects how timestamp lines are interpreted (whether they also count towards the command limit).
  - Implementation details: to _perform truncation_ means to call [sv_histsize("HISTFILESIZE")](https://github.com/bminor/bash/blob/ec8113b9861375e4e17b3307372569d429dec814/variables.c#L6117). The main implementation is in [history_truncate_file(...)](https://github.com/bminor/bash/blob/ec8113b9861375e4e17b3307372569d429dec814/lib/readline/histfile.c#L514). See how it uses HIST_TIMESTAMP_START.
- HISTSIZE and HISTFILESIZE technically start out unset. If HISTSIZE is still not set after running rc files, Bash sets it to 500. If HISTFILESIZE is still not set after running rc files, Bash sets it to $HISTSIZE.
- HISTFILE is just a normal variable and does not have a setter function. Bash sets it to ~/.bash_history before running anything. After Bash finishes loading rc files, it _performs truncation_ and reads commands from $HISTFILE into the in-memory history list. When Bash exits, it saves the in-memory history list to $HISTFILE and _performs truncation_. HISTFILE is also used by the aforementioned HISTFILESIZE setter and by the `history` builtin, but that's about it.
  - Implementation details: [load_history()](https://github.com/bminor/bash/blob/ec8113b9861375e4e17b3307372569d429dec814/bashhist.c#L313) is called from [main()](https://github.com/bminor/bash/blob/ec8113b9861375e4e17b3307372569d429dec814/shell.c) at some point after run_startup_files(). save_history() is dead code. [maybe_save_shell_history()](https://github.com/bminor/bash/blob/ec8113b9861375e4e17b3307372569d429dec814/bashhist.c#L476) is called when exiting.

Consequences:

- Bash loads the history file three times during normal startup. First to perform truncation when you assign HISTFILESIZE=n, then to perform truncation again after reading rc files, and finally to fill the in-memory history list. Oh well.
- It's bad to set HISTFILESIZE to a small number and later a bigger number. You effectively get the smaller limit.
- It's bad to set HISTFILESIZE and later set HISTTIMEFORMAT. You effectively get half the expected number because it thinks timestamp lines are also commands. HISTTIMEFORMAT should be set first.
- It's safe to change HISTFILE as often as you want.

On Debian and Ubuntu, the default /etc/skel/.bashrc sets HISTSIZE=1000 and HISTFILESIZE=2000. This irritates me because I originally wanted to keep .bashrc completely clean of any modifications, and put all my custom stuff in .bash_aliases, which is sourced by it. But setting a bigger HISTFILESIZE in .bash_aliases is too late: ~/.bash_history is already truncated. On Fedora, the default [/etc/profile](https://pagure.io/setup/blob/c01ca2665ab3ab95e9569083c3e3011ec312a6ca/f/profile) only sets (and exports) HISTSIZE=1000, and /etc/skel/.bashrc sets neither. That's better. An ideal distribution would set HISTSIZE to some larger number (without export) in /etc/bash.bashrc.

For now, my commonbashrc.sh also sets HISTFILE to ~/.bash_history2. This is to protect it from accidental truncation if you run `bash --norc` (because it defaults to 500) or if something somehow leads to running the default Debian .bashrc. Back when sudo didn't reset $HOME in [old versions of Ubuntu](https://askubuntu.com/questions/1186999/how-does-sudo-handle-home-differently-since-19-10), I suspect that could somehow cause accidental truncation too. But I'm not sure if I'm a fan. Using a custom filename feels ugly and inelegant. We'll see.

### How to get the current filename in a sourced script

The answer is `${BASH_SOURCE[0]}`.

I hesitated because [bash(1)](https://man.archlinux.org/man/bash.1) describes BASH_SOURCE like this: "An array variable whose members are the source filenames where the corresponding shell function names in the `FUNCNAME` array variable are defined. The shell function `${FUNCNAME[$i]}` is defined in the file `${BASH_SOURCE[$i]}` and called from `${BASH_SOURCE[$i+1]}`."

This confused me because I'm not inside a shell function. And it sounded like BASH_SOURCE always has the same length as FUNCNAME, but FUNCNAME was empty.

The man page is wrong. BASH_SOURCE is not just for functions, but also sourced scripts and the main script (if any). This is used by many existing scripts and also in some places in bash itself, so it is unlikely to change even though it is technically undocumented. And FUNCNAME internally stores data, but it appears empty if you read it outside of a function.

Example: If you run `bash a.sh` which sources `b.sh` which defines and calls `fn`, you'll get `BASH_SOURCE=([0]="./b.sh" [1]="./b.sh" [2]="a.sh")` and `FUNCNAME=([0]="fn" [1]="source" [2]="main")`. Outside of `fn`, FUNCNAME secretly contains `("source" "main")` but appears empty.

`${BASH_ARGV[0]}` also works... sometimes. I'll attempt to describe how it really works. BASH_ARGV is a stack and 0 is the top. Initially the main script's arguments are pushed, regardless of extdebug. `source file.sh` pushes the filename `file.sh`, regardless of extdebug, but only if there are no arguments. `source file.sh x y` pushes x, y if extdebug is enabled, otherwise nothing. `func x y` pushes x, y if extdebug is enabled, otherwise nothing. Conclusion: Let's stay with BASH_SOURCE.

The path in `${BASH_SOURCE[0]}` (and `${BASH_ARGV[0]}`) will be absolute if `source` had to look it up on $PATH. Otherwise it will be exactly as it was given to `source` and may be relative.

### Implementing a preexec hook

There are four ways I know of to do something after a prompt and act on the user's input before it is executed.

Sadly, none of them are very good. They all have problems.

- `DEBUG` trap + `$BASH_COMMAND`
  - Good: the DEBUG trap works regardless of history settings.
  - Good: the DEBUG trap does not run for command substitutions in $PS1, and does not run an extra time if the command contains a command substitution. This is usually what I want.
    - E.g. `echo $(echo aa)` and `$(echo echo aa)` run DEBUG exactly once. BASH_COMMAND is the original command, before command substitution is performed.
  - Tolerable: the DEBUG trap also runs before prompt, for each command in $PROMPT_COMMAND.
    - The trap code should not assume the user typed it.
  - Tolerable: the DEBUG trap can also run during prompt.
    - The trap code should check if `[[ -v COMP_LINE ]]` or `[[ -v READLINE_LINE ]]`. (`-v` also detects if they're set but empty. COMP_LINE is probably only needed if `functrace` or `extdebug` is enabled, because `complete -C` uses subshells and `complete -F` uses functions, but let's check it anyway.)
  - Tolerable: the DEBUG trap also runs for the remaining commands during the rest of .bashrc, .profile, etc.
    - The trap code should not do anything until it sees the first $PROMPT_COMMAND.
  - Tolerable: stdout and stderr might already be redirected at the time the DEBUG trap runs.
    - E.g. `{ echo aa; echo bb; echo cc; } &> output_file`
    - E.g. `for f in ./*; do echo "$f"; done &> output_file`
    - The trap code should avoid accidentally polluting the output file if it prints anything. Either by checking `[[ -t 2 ]]` or with `echo ... 2>/dev/null >/dev/tty`.
      - `2>/dev/null` is a mostly theoretical safety measure -- just in case. It blocks a Bash error message if the process has no controlling terminal (in which case open("/dev/tty") fails with ENXIO). The 2> must be before 1>. You can test it with `setsid bash -c '...'`. In practice I think there's no way a normally started interactive shell could lose its tty.
  - Neutral: the DEBUG trap might run multiple times for some inputs. This can be good for some use cases and a problem for others.
    - E.g. `echo a; echo b; echo c` (BASH_COMMAND is: `echo a`, `echo b`, `echo c`)
    - E.g. `echo a && echo b && echo c` (BASH_COMMAND is: `echo a`, `echo b`, `echo c`)
    - E.g. `for f in ./*; do echo "$f"; done` (BASH_COMMAND is: _N_ &times; [`for f in ./*`, `echo "$f"`])
  - Problem: the DEBUG trap does not run at all for some inputs. It'll run when it's time to display the next prompt, with $BASH_COMMAND from $PROMPT_COMMAND.
    - E.g. <code></code>&nbsp;(empty command), `   ` (spaces), ctrl+V tab (tabs), `# hi` (comments)
    - E.g. `;`, `)`, `>` (syntax errors)
    - E.g. `for f in ; do echo "$f"; done` (zero iteration loops)
    - E.g. `(echo a; echo b; echo c)` (subshells)
      - This can be solved by enabling `functrace` (aka `set -T`) and/or `extdebug`. I don't like this because I feel it's too invasive and hacky, and probably slow. Also, the bash-preexec library tried it and [ran into some Bash bugs](https://github.com/rcaloras/bash-preexec#subshells).
  - Problem: `$BASH_COMMAND` does not contain the original command as written. Bash takes the parsed command and serializes it back to a string.
    - Aliases are already expanded.
    - Whitespace between arguments is normalized.
    - Whitespace (including newlines) in quotes or in heredocs is kept.
    - Quotes and backslashes are mostly preserved, with one big exception: `$'...'` is replaced with `'...'` and escape sequences become actual special characters. E.g. `$'\e'` becomes the ESC character.
    - Because of ESC and newlines, it might not be safe to print $BASH_COMMAND inside another terminal escape sequence, e.g. to show the command in the window title.
  - Problem: when exiting with ctrl+D, Bash will run the DEBUG trap several times, but $BASH_COMMAND will still be the previous command. (Maybe because of my EXIT trap?)
- `DEBUG` trap + `history 1`
  - Used by the [bash-preexec library](https://github.com/rcaloras/bash-preexec).
  - Same DEBUG trap notes and problems as above.
  - Good: `history 1` is able to see comments, syntax errors, subshells, and ctrl+V tab (a single literal tab).
    - Also a line consisting only of spaces, but only if `ignorespace` is disabled.
  - Good: `history 1` preserves the original whitespace and quotes.
  - Good: by default (see `cmdhist`), Bash tries to merge multiline entries into one line, adding semicolons where necessary. `history 1` also returns the merged line. Not literally what the user wrote. This is usually what I want.
    - E.g. `echo a \` &#8629; `b` &rarr; `echo a b`
    - E.g. `echo a &&` &#8629; `echo b` &rarr; `echo a && echo b`
    - E.g. `for i in a b c` &#8629; `do` &#8629; `echo $i` &#8629; `done` &rarr; `for i in a b c; do echo $i; done`
  - Tolerable: `history 1` can print a multi-line string if Bash can't rewrite it as one line.
    - E.g. `echo 'a` &#8629; `b'` (quoted newline)
    - E.g. `cat <<END` &#8629; `a` &#8629; `END` (heredoc) (it also has an extra newline after "END")
    - The trap code should not assume it has to be a single line.
  - Tolerable: `history 1` also prints the entry number and HISTTIMEFORMAT.
    - The trap code should temporarily set HISTTIMEFORMAT to something machine readable.
  - Tolerable: `history 1` can print non-printable characters in some rare cases, e.g. if you press ctrl+V esc.
    - The trap code should not assume it has to be printable.
  - Problem: `history 1` won't see commands starting with a space if `ignorespace` is on.
  - Problem: `history 1` can't distinguish between commands ignored because of `ignorespace`, commands ignored because of `ignoredups`, commands ignored because of `HISTIGNORE`, empty commands, and exiting the shell with ctrl+D.
    - In all those cases, it just prints the previous command that wasn't ignored.
    - I looked into $HISTCMD and the prompt sequences `\!` and `\#`, but they didn't help.
    - $BASH_COMMAND and $PS0 can't always reliably help distinguish these cases, because of their own blindspots (syntax errors and/or subshells).
    - The bash-preexec library "solves" this by disabling `ignorespace`. That's a price I'm not willing to pay.
  - Problem (only for me): reading the output with `somevar=$(history 1)` performs a fork.
    - I have a self-imposed rule against unnecessary forking. If I run `ps` twice, I want them to have consecutive PIDs. (It used to be a fun challenge... Stopping now would be conceding defeat...)
    - Command substitution always performs a fork, even for shell builtins. (Except `$(< )` in Bash 5.2+.)
    - The fork can be avoided with a temporary file. Write `history 1 > f` and read it with `read somevar < f`. How disgusting. (At least you can put it on a tmpfs, and `history -a` would do a disk write anyway.)
- `$PS0`
  - It is printed after a prompt. In case of multiline input with $PS2, it's only printed once at the end.
  - If PS0 contains `$(history 1)`, same notes and problems as above.
  - Problem: $PS0 is just a prompt string and it can't run arbitrary code.
    - $PS0 may contain command substitutions, but they run in a subshell, so variable assignments etc. won't be preserved. And they break my self-imposed rule against forking.
    - $PS0 can assign to foo with `${foo:=value}`, but foo must be empty or unset.
    - $PS0 can append to arr with `${arr[${#arr[@]}]:=value}`.
    - The output can be suppressed with `${empty_variable#${arr[${#arr[@]}]:=value}}`.
  - Problem: $PS0 is not printed after some inputs.
    - E.g. <code></code>&nbsp;(empty command), `   ` (spaces), ctrl+V tab (tabs), `# hi` (comments)
    - E.g. `;`, `)`, `>` (syntax errors)
  - Problem: At the time of printing $PS0 is printed, $BASH_COMMAND still contains the previous command.
    - Surprisingly, it is not the $PROMPT_COMMAND.
- `bind -x` + `$READLINE_LINE`
  - Used by the [bpx library](https://github.com/d630/bpx).
  - Tolerable: lines are submitted not just with `accept-line (C-j, C-m)` but also `operate-and-get-next (C-o)`, `insert-comment (M-#)` and `edit-and-execute-command (C-x C-e)`. They should be rebound or disabled for completeness.
  - Tolerable: $READLINE_LINE may contain non-printable characters in some rare cases, such as if the user presses ctrl+V esc.
  - Problem: Bash erases the prompt line before `bind -x` and rerenders it afterwards. If the previous command's output didn't end with a newline, it will disappear.
  - Problem: for multiline commands, `bind -x` will run for each line, but it won't see how Bash merges them into one line and where it adds semicolons.
  - Problem: at the time `bash -x` runs, it is not yet known whether this is the last line or not.
  - Problem: at the time `bash -x` runs, the prompt technically hasn't ended. For example it's too early to save the history file with `history -a`.

For the moment I'm reluctantly using the "`DEBUG` trap + `history 1`" method.
