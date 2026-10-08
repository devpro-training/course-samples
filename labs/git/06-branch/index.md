# Branch and merge

A branch is a movable pointer to a commit.
Working on a branch keeps `main` stable until the change is ready.

![Before the merge, feature/greeting is one commit ahead of main, after the merge both point to the same commit](../assets/git-branch-dark.svg#gh-dark-mode-only)
![Before the merge, feature/greeting is one commit ahead of main, after the merge both point to the same commit](../assets/git-branch.svg#gh-light-mode-only)

## Create a branch

1. Go to the repository and list its branches, the current one is marked with `*`:

   <!-- verify: expect="* main" -->

   ```bash exec
   cd ~/lab/demo && \
   git branch
   ```

2. Create a branch and switch to it:

   <!-- verify: expect="Switched to a new branch" -->

   ```bash exec
   git switch -c feature/greeting
   ```

   > [!NOTE]
   > `git checkout -b feature/greeting` does the same, and is still widely used.
   > `git switch`, added in Git 2.23, only deals with branches, which makes it clearer.

3. Commit a new file on the branch:

   <!-- verify: expect="1 file changed" -->

   ```bash exec
   echo "Hello, Git!" > hello.txt && \
   git add hello.txt && \
   git commit -m "Add greeting"
   ```

   [Open hello.txt](:open:demo/hello.txt) to see the new file.

## Merge

1. Go back to `main`, where `hello.txt` does not exist, as the refreshed file tree in the editor shows:

   <!-- verify: expect="Switched to branch 'main'" -->

   ```bash exec
   git switch main
   ```

2. Merge the branch into `main`:

   <!-- verify: expect="Fast-forward" -->

   ```bash exec
   git merge feature/greeting
   ```

3. Delete the merged branch, its commit stays in the history:

   <!-- verify: expect="Deleted branch" -->

   ```bash exec
   git branch -d feature/greeting && \
   git log --oneline --graph
   ```
