# Stash work in progress

An urgent fix comes in while a change is half done.
`git stash` puts the unfinished change aside and leaves a clean working tree.

1. Go to the repository and start a change:

   <!-- verify: expect="M README.md" -->

   ```bash exec
   cd ~/lab/demo && \
   echo "Work in progress" >> README.md && \
   git status --short
   ```

   [Open README.md](:open:demo/README.md) to see the new line.

2. Put it aside, and reopen [README.md](:open:demo/README.md): the line is gone:

   <!-- verify: expect="Saved working directory and index state" -->

   ```bash exec
   git stash push -m "README draft"
   ```

3. Check the working tree is clean, and the change is in the stash list:

   <!-- verify: expect="stash@{0}" -->

   ```bash exec
   git status --short && \
   git stash list
   ```

   The urgent fix can now be done, on any branch.

4. Bring the change back and remove it from the stash list, then reopen [README.md](:open:demo/README.md):

   <!-- verify: expect="Dropped refs/stash@{0}" -->

   ```bash exec
   git stash pop
   ```

> [!NOTE]
> New files that were never added are not stashed, unless `git stash push -u` is used.
> `git stash apply` brings a change back and keeps it in the list.
