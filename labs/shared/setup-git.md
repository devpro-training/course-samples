## Git

The lab runs Debian 12, as a user with no administrator rights, so the official Debian packages are unpacked in the home directory instead of being installed with `apt`.

1. Download and unpack Git, and `less`, the pager Git uses to display long output, then add them to the `PATH`, now and for every new shell:

   <!-- verify: requires=network timeout=180 -->

   ```bash exec
   wget -q "${DEBIAN_MIRROR}/pool/main/g/git/${GIT_DEB}" -O git.deb && \
   wget -q "${DEBIAN_MIRROR}/pool/main/l/less/${LESS_DEB}" -O less.deb && \
   dpkg-deb -x git.deb ~/.local/ && \
   dpkg-deb -x less.deb ~/.local/ && \
   rm git.deb less.deb && \
   export PATH="$HOME/.local/usr/bin:$HOME/.local/usr/lib/git-core:$PATH" && \
   echo 'export PATH="$HOME/.local/usr/bin:$HOME/.local/usr/lib/git-core:$PATH"' >> ~/.bashrc && \
   export GIT_EXEC_PATH="$HOME/.local/usr/lib/git-core" && \
   echo 'export GIT_EXEC_PATH="$HOME/.local/usr/lib/git-core"' >> ~/.bashrc && \
   export PAGER=less && \
   echo 'export PAGER=less' >> ~/.bashrc && \
   git config --global init.templateDir "$HOME/.local/usr/share/git-core/templates"
   ```

   > [!NOTE]
   > `GIT_EXEC_PATH` and `init.templateDir` are only needed because Git is not in its usual location, `/usr`.
   > `PAGER` is set because Debian's Git calls the system pager, which is `more` when `less` was not installed with `apt`.

2. Check the version:

   <!-- verify: expect="git version 2." -->

   ```bash exec
   git --version
   ```
