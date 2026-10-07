# Source control

VS Code runs the same Git commands as the terminal, and shows their result.

## Change, review, commit

1. Open `hello/app.js` and add `"Margaret"` to the list of names.
   Auto Save, set in the previous step, saves the file, otherwise use **☰ > File > Save**.

2. Open the **Source Control** view with **☰ > View > Source Control**: `app.js` is listed under **Changes**, with an `M` for modified.

3. Click `app.js` in that list: the diff opens, the last commit on the left and the working tree on the right.

4. Click the `+` next to the file, **Stage Changes**, the same as `git add`.

5. Type `Add Margaret` in the message box, then click **Commit**.

6. Click the **main** branch name in the Status Bar to see the branches, and to create one, the same as `git switch -c`.

## Check from the terminal

1. In the [terminal](:panel:terminal), display the history:

   <!-- verify: skip reason="the commit is made in VS Code" -->

   ```bash exec
   cd ~/lab/hello && \
   git log --oneline
   ```

   The commit made in VS Code is there, on top of the one made in the terminal.

> [!TIP]
> With GitLens, the line under the cursor shows who changed it last, when, and in which commit.
