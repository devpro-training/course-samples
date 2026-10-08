# GitHub

The most widely used host of Git repositories.

---

## What GitHub is

- A **hosting service** for Git repositories, with a web interface and an API around them.

- Founded in 2008, owned by Microsoft since 2018.

- Adds to Git what Git does not have: **pull requests**, **issues**, **Actions** and **access control**.

- GitHub is not Git: the same repository can be hosted by GitLab, Bitbucket, Azure DevOps or Gitea.

---

## Why it matters

- **Collaboration**: a pull request is where a change is reviewed before it is merged.

- **Automation**: GitHub Actions builds and tests every change.

- **Discovery**: open source projects are read, forked and reported on in the open.

- **Foundation** for CI/CD, GitOps and supply chain security.

---

## One repository, three ways in

![A local repository pushes to and fetches from a GitHub repository, which is also read by the REST API and the web interface](../assets/github-flow-dark.svg#gh-dark-mode-only)
![A local repository pushes to and fetches from a GitHub repository, which is also read by the REST API and the web interface](../assets/github-flow.svg#gh-light-mode-only)

---

## In this lab

Topic         | Where
--------------|------------------------------------------------------
Repository    | the web interface, `git clone`, `git log`
REST API      | `wget` on `api.github.com`
Pull request  | the web interface, `git fetch origin pull/<n>/head`
Actions       | a workflow file, and the **Actions** tab

> Everything is read without an account, from public repositories.
> Writing to GitHub (push, fork, open a pull request) needs an account and a token, and is the next step after this lab.
