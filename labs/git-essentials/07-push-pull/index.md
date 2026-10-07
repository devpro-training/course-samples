# Push and pull

A remote repository is usually hosted on a service such as GitHub or GitLab.
Here, a bare repository in `~/lab/server` plays the server: it holds the history with no working tree, which is what a hosting service keeps.

## Push

1. Create the server repository:

   <!-- verify: expect="Initialized empty Git repository" -->

   ```bash exec
   git init --bare ~/lab/server/demo.git
   ```

2. Go to the repository, register the server as the remote `origin`, then push `main` to it:

   <!-- verify: expect="set up to track" -->

   ```bash exec
   cd ~/lab/demo && \
   git remote add origin ~/lab/server/demo.git && \
   git push -u origin main
   ```

   `-u` links the local `main` to `origin/main`, so a plain `git push` or `git pull` is enough afterwards.

## A teammate pushes a change

1. Clone the repository in another folder, with a local identity for this teammate:

   <!-- verify: expect="Cloning into" -->

   ```bash exec
   cd ~/lab && \
   git clone server/demo.git teammate && \
   cd teammate && \
   git config user.name "Grace Hopper" && \
   git config user.email "grace@example.com"
   ```

2. Change a file, commit and push:

   <!-- verify: expect="main -> main" -->

   ```bash exec
   echo "Bonjour, Git!" >> hello.txt && \
   git commit -am "Add French greeting" && \
   git push
   ```

   > [!NOTE]
   > `git commit -a` stages every modified file that is already tracked, so `git add` is not needed.

## Pull

1. Back in the first repository, get the new commit:

   <!-- verify: expect="Fast-forward" -->

   ```bash exec
   cd ~/lab/demo && \
   git pull
   ```

   `git pull` is `git fetch`, which downloads the new commits, followed by `git merge`.

2. [Open hello.txt](:open:demo/hello.txt) to see the teammate's line.

3. Display the history with the author of each commit:

   <!-- verify: expect="Grace Hopper" -->

   ```bash exec
   git log --format="%h %an %s"
   ```

> [!IMPORTANT]
> A push is refused when the remote has commits the local branch does not have.
> The fix is to pull first, then push again.
