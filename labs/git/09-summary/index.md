# Summary

---

## Cheat sheet

Command                          | Does
---------------------------------|--------------------------------------------
`git config --global user.name`  | Set the author name, once per machine
`git init`                       | Turn a folder into a repository
`git clone <url>`                | Copy an existing repository
`git status`                     | Show what changed
`git add <file>`                 | Stage a change for the next commit
`git commit -m "<message>"`      | Record the staged changes
`git log --oneline`              | Show the history
`git switch -c <branch>`         | Create a branch and switch to it
`git merge <branch>`             | Bring a branch into the current one
`git push` / `git pull`          | Send / get commits to / from the remote
`git stash push` / `git stash pop` | Put changes aside / bring them back

---

## Good practices

- Small commits, each with one purpose.

- Messages that say why, not only what.

- Pull before starting work, push often.

- A `.gitignore` for build output, and never a secret in a commit.

---

## Graphical clients

The command line is the reference, and graphical clients run the same Git underneath.

- **GitKraken Desktop**, on Windows, macOS and Linux, draws the commit graph and makes branches easy to follow.
  Free with local and public repositories, a paid plan is needed for private ones.

- **Visual Studio Code** has a built-in Source Control view.

---

## Next

- GitHub: hosting, pull requests and collaboration.

- The free [Pro Git book](https://git-scm.com/book) and the [reference documentation](https://git-scm.com/docs).
