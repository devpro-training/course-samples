# Clone a repository

`git clone` copies an existing repository, its whole history included, and checks out its default branch.

1. Clone a small public repository from GitHub:

   <!-- verify: requires=network timeout=120 expect="Cloning into" -->

   ```bash exec
   cd ~/lab && \
   git clone https://github.com/octocat/Hello-World.git
   ```

2. Look at its history:

   <!-- verify: expect="first commit" -->

   ```bash exec
   cd Hello-World && \
   git log --oneline
   ```

3. Display the remote the repository was cloned from, saved under the name `origin`:

   <!-- verify: expect="(fetch)" -->

   ```bash exec
   git remote -v
   ```

4. List the local and remote branches:

   <!-- verify: expect="remotes/origin/master" -->

   ```bash exec
   git branch --all
   ```

   > [!NOTE]
   > This repository was created before `main` became common, so its default branch is still `master`.
