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

Customize the prompt color by adding e.g. `SHELLSTUFF_PROMPT_COLOR=47` to ~/.bashrc.

<details><summary>Expected hashes of /etc/skel/.bashrc</summary>

Just to be safe, here are the most recent versions of /etc/skel/.bashrc in various distributions as of this writing. commonbashrc.sh should already cover everything they do. If the hash doesn't match anymore, perhaps the distribution added something new that might be worth a look.

| Distribution | sha256sum /etc/skel/.bashrc                                      | Permalink                                                                                                                                 | Latest                                                                                               |
| ------------ | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Debian       | afae8986f549c6403410e029f9cce7983311512d04b1f02af02e4ce0af0dd2bf | [2015-01-29](https://bazaar.launchpad.net/~doko/+junk/pkg-bash-debian/view/29/skel.bashrc)                                                | [link?](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/skel.bashrc?h=debian%2Fsid) (sigh) |
| Ubuntu       | 342099da4dd28c394d3f8782d90d7465cb2eaa611193f8f378d6918261cb9bb8 | [unknown date](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/skel.bashrc?id=f4a6a7f308779b118b4e8efecb87d4ad86f2d587)         | [link](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/skel.bashrc)                        |
| Arch         | 959bc596166c9758fdd68836581f6b8f1d6fdb947d580bf24dce607998a077b8 | [2023-02-02](https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/6c4e8435a132bbf5924055e6e940e9a5bc95e0bf/dot.bashrc)   | [link](https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/main/dot.bashrc)        |
| Fedora       | c5566fb3645f14ef9f8fd2bcb0ad468bf6ef8a0c51a55633cb57f4c3e572aac6 | [2022-11-06](https://src.fedoraproject.org/rpms/bash/blob/b05f1d7a2338ad5f398190370e415a795d792d46/f/dot-bashrc)                          | [link](https://src.fedoraproject.org/rpms/bash/blob/rawhide/f/dot-bashrc)                            |
| Gentoo       | e280e34af6e830c93adb6285f66ead4812ddfb2bbc6a7ff618467f4c933f6446 | [2015-08-08](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/dot-bashrc?id=56bd759df1d0c750a065b8c845e93d5dfa6b549d) | [link](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/dot-bashrc)              |

</details>

## Explanations

### Why should .bashrc check for interactive shells? (`[[ $- != *i* ]]`)

Does Bash even read .bashrc if the shell is not interactive? Usually no. But there is one edge case: if Bash is started by sshd with a `-c` command, it may run some rc files even though it's not interactive.

From [bash(1)](https://man.archlinux.org/man/bash.1):

> **Bash** attempts to determine when it is being run with its standard input connected to a network connection, as when executed by the remote shell daemon, usually _rshd_, or the secure shell daemon _sshd_. If **bash** determines it is being run in this fashion, it reads and executes commands from _~/.bashrc_, if that file exists and is readable. It will not do this if invoked as **sh**. The **--norc** option may be used to inhibit this behavior, and the **--rcfile** option may be used to force another file to be read, but neither _rshd_ nor _sshd_ generally invoke the shell with those options or allow them to be specified.

Implementation details: This is handled in [run_startup_files() in bash](https://github.com/bminor/bash/blob/ec8113b9861375e4e17b3307372569d429dec814/shell.c#L1136) and works by checking for `$SSH_CLIENT` or `$SSH_CLIENT2`. It is toggled by the compile time option SSH_SOURCE_BASHRC, which is enabled on [Debian](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/patches/deb-bash-config.diff?h=debian/sid), [Ubuntu](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/patches/deb-bash-config.diff), [Fedora](https://src.fedoraproject.org/rpms/bash/blob/rawhide/f/bash-3.2-ssh_source_bash.patch), and [Gentoo](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/bash-9999.ebuild#:~:text=DSSH_SOURCE_BASHRC), but not on [Arch](https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/main/PKGBUILD) or in upstream Bash. It is true that sshd does not give Bash any extra options: when a command is given to ssh, [do_child() in sshd](https://github.com/openssh/openssh-portable/blob/3c6ab63b383b0b7630da175941e01de9db32a256/session.c#L1705) will run `/bin/bash -c 'some command'` with no other arguments. It also doesn't matter whether the ssh connection has a pseudoterminal (pty) or not.

I think this behavior is unexpected and usually not what I want, so it's better to `return` immediately.

The default /etc/skel/.bashrc files on [Debian](https://bazaar.launchpad.net/~doko/+junk/pkg-bash-debian/view/29/skel.bashrc#L5), [Ubuntu](https://git.launchpad.net/ubuntu/+source/bash/tree/debian/skel.bashrc?id=f4a6a7f308779b118b4e8efecb87d4ad86f2d587#n5), [Arch](https://gitlab.archlinux.org/archlinux/packaging/packages/bash/-/blob/6c4e8435a132bbf5924055e6e940e9a5bc95e0bf/dot.bashrc#L5) and [Gentoo](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/dot-bashrc?id=56bd759df1d0c750a065b8c845e93d5dfa6b549d#n9) also have an early `return`. [Fedora](https://src.fedoraproject.org/rpms/bash/blob/b05f1d7a2338ad5f398190370e415a795d792d46/f/dot-bashrc) does not.

For completeness: Bash also reads SYS_BASHRC in this scenario. It is `/etc/bash.bashrc` on Debian, Ubuntu and Arch, `/etc/bash/bashrc` on Gentoo, and is not set on Fedora. Fortunately, those files also contain an early `return`.

### Bash history variables

HISTSIZE has a setter function which truncates the in-memory history list. This is usually irrelevant because the in-memory history list is usually empty while running rc files.

HISTFILESIZE has a setter function which immediately checks if the history file is too long (according to the current value of $HISTFILE), and if so, truncates it. The in-memory history list is unaffected. Therefore, if you set HISTFILESIZE to a smaller number and then a bigger number, you effectively get the smaller number.

HISTFILE is just a normal variable and does not have a setter function. Before Bash runs anything, it sets HISTFILE to ~/.bash_history. After Bash finishes loading rc files, it looks at HISTFILE's value and reads commands from that file into the in-memory history list. When Bash exits, it looks at HISTFILE's value and saves the in-memory history list to that file. HISTFILE is also used by the aforementioned HISTFILESIZE setter and by the `history` builtin, but that's about it.

On Debian and Ubuntu, the default /etc/skel/.bashrc sets HISTSIZE=1000 and HISTFILESIZE=2000. This irritates me because I originally wanted to keep .bashrc completely clean of any modifications and put all my custom stuff in .bash_aliases, which is sourced by it. But setting a bigger HISTFILESIZE in .bash_aliases is too late -- ~/.bash_history is already truncated. I could work around it by also setting HISTFILE to some other filename, but it didn't feel right.

On Fedora, the default [/etc/profile](https://pagure.io/setup/blob/c01ca2665ab3ab95e9569083c3e3011ec312a6ca/f/profile) sets HISTSIZE=1000, and other rc files don't mention it. This is much nicer because it's easy to override. FYI, it's OK to not assign HISTFILESIZE because Bash sets it to $HISTSIZE if it's still empty after running rc files.
