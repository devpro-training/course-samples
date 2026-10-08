# Create a repository and commit

A commit is a snapshot of the staged files, with an author, a date, a message and a unique identifier.

## Initialize

1. Create a project folder and turn it into a Git repository:

   <!-- verify: expect="Initialized empty Git repository" -->

   ```bash exec
   mkdir -p ~/lab/demo && \
   cd ~/lab/demo && \
   git init
   ```

   > [!NOTE]
   > The whole history lives in the hidden `.git` folder.
   > Deleting it turns the folder back into a plain folder.

## Stage and commit

1. Create a file and look at the status:

   <!-- verify: expect="Untracked files" -->

   ```bash exec
   echo "# Demo" > README.md && \
   git status
   ```

   An **untracked** file is in the working tree, but Git does not follow it yet.
   [Open README.md](:open:demo/README.md) to see it in the editor.

2. Add the file to the staging area, the content of the next commit:

   <!-- verify: expect="A  README.md" -->

   ```bash exec
   git add README.md && \
   git status --short
   ```

3. Record the commit, with a message saying why the change was made:

   <!-- verify: expect="1 file changed" -->

   ```bash exec
   git commit -m "Add README"
   ```

4. Display the history:

   <!-- verify: expect="Add README" -->

   ```bash exec
   git log --oneline
   ```

   > [!TIP]
   > `git add .` stages every change of the current folder, and a `.gitignore` file lists the files Git must never track, such as build output or secrets.
