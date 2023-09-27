# My Bash shell stuff

## commonbashrc.sh

This is my personal Bash initialization file. It is public to make it easier to use from multiple computers. I don't expect anybody else to use it, but it might be good for inspiration.

Installation:

1. Clone the shellstuff repo somewhere. E.g. `~/shellstuff` or `~/.shellstuff`.

2. Compare your ~/.bashrc with the distribution default. If they are not equal, decide whether you want to keep your changes.

   ```bash
   diff -u /etc/skel/.bashrc ~/.bashrc
   ```

3. Edit ~/.bashrc. Delete everything and replace it with:

   ```bash
   [[ $- != *i* ]] && return  # Stop if not interactive. Explained in shellstuff/README.md.

   source ~/shellstuff/commonbashrc.sh
   ```

Customization:

You can change the main prompt color by adding e.g. `RRPROMPT_COLOR=47` to ~/.bashrc. See rrprompt.sh for more.

<details><summary>Expected hashes of /etc/skel/.bashrc</summary>

Just to be safe, here are the most recent versions of /etc/skel/.bashrc in various distributions as of this writing. commonbashrc.sh should already cover everything they do. If the hash doesn't match anymore, perhaps the distribution added something new that might be worth a look.

| Distribution | sha256sum /etc/skel/.bashrc                                      | Permalink                                                                                                                                 | Latest                                                                                        |
| ------------ | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Debian       | afae8986f549c6403410e029f9cce7983311512d04b1f02af02e4ce0af0dd2bf | [2015-01-29](https://sources.debian.org/src/bash/5.2.15-2/debian/skel.bashrc/)                                                            | [link](https://sources.debian.org/src/bash/latest/debian/skel.bashrc/)                        |
| Ubuntu       | 342099da4dd28c394d3f8782d90d7465cb2eaa611193f8f378d6918261cb9bb8 | [unknown date](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/skel.bashrc?id=f4a6a7f308779b118b4e8efecb87d4ad86f2d587)         | [link](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/skel.bashrc)                 |
| Arch         | 959bc596166c9758fdd68836581f6b8f1d6fdb947d580bf24dce607998a077b8 | [2023-02-02](https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/6c4e8435a132bbf5924055e6e940e9a5bc95e0bf/dot.bashrc)   | [link](https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/main/dot.bashrc) |
| Fedora       | c5566fb3645f14ef9f8fd2bcb0ad468bf6ef8a0c51a55633cb57f4c3e572aac6 | [2022-11-06](https://src.fedoraproject.org/rpms/bash/blob/b05f1d7a2338ad5f398190370e415a795d792d46/f/dot-bashrc)                          | [link](https://src.fedoraproject.org/rpms/bash/blob/rawhide/f/dot-bashrc)                     |
| Gentoo       | e280e34af6e830c93adb6285f66ead4812ddfb2bbc6a7ff618467f4c933f6446 | [2015-08-08](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/dot-bashrc?id=56bd759df1d0c750a065b8c845e93d5dfa6b549d) | [link](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/dot-bashrc)       |

</details>

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
