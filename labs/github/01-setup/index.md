<!-- include: ../../shared/setup.md -->

## On a workstation

Git is a command line tool, available on every operating system, and a public repository is read without a GitHub account.

System         | Command
---------------|-----------------------------------------------------
Windows        | `winget install --id Git.Git -e --source winget`
macOS          | `brew install git`, or `xcode-select --install`
Debian, Ubuntu | `sudo apt install git`
Fedora         | `sudo dnf install git`

[git-scm.com/install](https://git-scm.com/install) is the reference for every system.

> [!NOTE]
> This lab only reads public repositories, so no account and no token are needed.
> The GitHub CLI, `gh`, is not used: Git, a browser and `wget` show what it relies on.

<!-- include: ../../shared/setup-git.md -->
