## A folder for the tools

The lab runs as a user with no administrator rights, so the tools of this course are single binaries, placed in a folder of the home directory.

1. Create it, and add it to the `PATH`, now and for every new shell:

   ```bash exec
   mkdir -p ~/.local/bin && \
   export PATH="$HOME/.local/bin:$PATH" && \
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   ```
