# Configure Git

Every commit records the name and email of its author, so Git needs both before the first commit.

## Three levels

Option     | File             | Applies to
-----------|------------------|------------------------------------------
`--system` | `/etc/gitconfig` | Every user of the machine
`--global` | `~/.gitconfig`   | The current user, in every repository
`--local`  | `.git/config`    | One repository, the default when writing

A local value wins over a global one, which wins over a system one.

## Identity

1. Set the name and email of the current user:

   ```bash exec
   git config --global user.name "${GIT_USER_NAME}" && \
   git config --global user.email "${GIT_USER_EMAIL}"
   ```

   > [!TIP]
   > On GitHub or GitLab, the email links commits to an account, so it has to be one the account knows.

## Recommended defaults

1. Name the first branch of a new repository `main`, the name used by GitHub and GitLab, and the default planned for Git 3.0:

   ```bash exec
   git config --global init.defaultBranch main
   ```

2. Merge when pulling a branch that has diverged, otherwise `git pull` stops and asks how to reconcile:

   ```bash exec
   git config --global pull.rebase false
   ```

## Check

1. Display every value and the file it comes from:

   <!-- verify: expect="user.email=" -->

   ```bash exec
   git config --list --show-origin
   ```
