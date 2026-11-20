# Files and folders

Moving around the tree, and creating, copying, moving and removing what it holds.

## Where am I

1. Create a folder for the exercise and move into it.
   `~` is the home directory, and `pwd` prints the current directory:

   <!-- verify: expect="in /" -->

   ```bash exec target=linux
   mkdir -p ~/lab/files && \
   cd ~/lab/files && \
   echo "in $(pwd)"
   ```

2. `mkdir -p` creates the folders of a path at once, and `touch` creates an empty file.
   `tee` writes its input to a file and shows it:

   <!-- verify: expect="6 project/docs/readme.txt" -->

   ```bash exec target=linux
   cd ~/lab/files && \
   mkdir -p project/docs project/src && \
   touch project/src/main.txt project/.hidden && \
   echo "hello" | tee project/docs/readme.txt && \
   wc -c project/docs/readme.txt
   ```

3. List what was created.
   `ls -a` shows the hidden files, which start with a dot, and `-l` the details:

   <!-- verify: expect=".hidden" -->

   ```bash exec target=linux
   cd ~/lab/files && \
   ls -a project && \
   ls -lR project
   ```

## Relative and absolute paths

A path that starts with `/` is **absolute**, from the root of the tree.
Any other path is **relative**, from the current directory, where `.` is the directory itself and `..` its parent.

1. Reach the same folder both ways:

   <!-- verify: expect="/lab/files/project/docs" -->

   ```bash exec target=linux
   cd ~/lab/files && \
   cd project/docs && pwd && \
   cd ../src && pwd && \
   cd ~/lab/files/project && pwd
   ```

## Copy, move, remove

1. `cp` copies, `mv` moves or renames, and `find` lists the files below a folder:

   <!-- verify: expect="project/src/copy.txt" -->

   ```bash exec target=linux
   cd ~/lab/files && \
   cp project/docs/readme.txt project/docs/copy.txt && \
   mv project/docs/copy.txt project/src/ && \
   find project -type f
   ```

2. `rm` removes a file, and `rm -r` a folder with what it holds.
   There is no recycle bin: a removed file is gone.

   <!-- verify: expect="docs" -->

   ```bash exec target=linux
   cd ~/lab/files && \
   rm project/src/copy.txt && \
   rm -r project/src && \
   ls project
   ```

> [!TIP]
> `Tab` completes a name, the up arrow brings back the previous command, and `Ctrl+R` searches the history.
> Most commands print their options with `--help`, for example `ls --help`.
