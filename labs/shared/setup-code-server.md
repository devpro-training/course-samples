## VS Code in the browser

[code-server](https://github.com/coder/code-server) is VS Code running on a server, here the lab, and used from a browser.
Its release archive installs in the home directory, with no administrator rights.

1. Download and unpack code-server, then add it to the `PATH`, now and for every new shell:

   <!-- verify: requires=network timeout=300 -->

   ```bash exec
   mkdir -p ~/.local/lib ~/.local/bin && \
   wget -qO- "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz" | \
     tar -C ~/.local/lib -xz && \
   ln -sfn ~/.local/lib/code-server-${CODE_SERVER_VERSION}-linux-amd64/bin/code-server ~/.local/bin/code-server && \
   export PATH="$HOME/.local/bin:$PATH" && \
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   ```

2. Check the version:

   <!-- verify: expect="with Code 1." -->

   ```bash exec
   code-server --version
   ```

3. Start it in the background on the lab folder, then wait until it answers:

   <!-- verify: timeout=90 expect="lastHeartbeat" -->

   ```bash exec
   nohup code-server --auth none --bind-addr 127.0.0.1:8080 ~/lab > ~/code-server.log 2>&1 &
   wget -qO- --retry-connrefused --tries=30 --waitretry=1 http://127.0.0.1:8080/healthz; echo
   ```

   > [!NOTE]
   > `/healthz` answers `expired` until a browser connects, then `alive`.
   > `--auth none` is only acceptable because code-server listens on `127.0.0.1`, inside the lab.
   > Anywhere else, code-server must keep its password, or sit behind an authenticating proxy.

4. [Open VS Code](:navigate:vscode:http://localhost:8080/) in the lab browser.
