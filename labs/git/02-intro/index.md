# Git

The version control system behind almost every software project.

---

## What Git is

- A **distributed** version control system: every copy holds the full history.

- It records **snapshots** of a project, called commits.

- Created by Linus Torvalds in 2005 to develop the Linux kernel.

- Free and open source, at [git-scm.com](https://git-scm.com).

---

## Why it matters

- **History**: who changed what, when and why.

- **Safety**: any previous state can be restored.

- **Collaboration**: branches let many people work in parallel.

- **Foundation** for GitHub, GitLab, CI/CD and GitOps.

---

## Where changes live

![Working tree, staging area, local and remote repositories, with the commands moving changes between them](../assets/git-areas-dark.svg#gh-dark-mode-only)
![Working tree, staging area, local and remote repositories, with the commands moving changes between them](../assets/git-areas.svg#gh-light-mode-only)

---

## In this lab

Topic                 | Commands
----------------------|-------------------------------------------------------------
Configure             | `git config`
Create and commit     | `git init`, `git status`, `git add`, `git commit`, `git log`
Clone                 | `git clone`, `git remote`
Branch                | `git branch`, `git switch`, `git merge`
Push and pull         | `git push`, `git pull`
Stash                 | `git stash`

> All commands run in a Linux terminal, and work the same on Windows and macOS.
