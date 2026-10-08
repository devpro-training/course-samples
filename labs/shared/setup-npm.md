## Node.js and npm

Playwright is a Node.js library, and npm installs it.
The lab image carries Node.js and no npm, so npm is unpacked from its registry tarball, which holds its own dependencies.

1. Check the Node.js version, which Playwright requires to be a current 22, 24 or 26:

   <!-- verify: expect="v22." -->

   ```bash exec
   node --version
   ```

2. Download the npm tarball with the metadata of this version, and compare its checksum with the one the registry publishes:

   <!-- verify: requires=network timeout=120 expect="integrity ok" -->

   ```bash exec
   cd ~ && \
   wget -q "${NPM_REGISTRY_URL}/npm/-/npm-${NPM_VERSION}.tgz" -O npm.tgz && \
   wget -q "${NPM_REGISTRY_URL}/npm/${NPM_VERSION}" -O npm.json && \
   python3 -c 'import base64, hashlib, json, sys; want = json.load(open("npm.json"))["dist"]["integrity"]; got = "sha512-" + base64.b64encode(hashlib.sha512(open("npm.tgz", "rb").read()).digest()).decode(); print("integrity", "ok" if got == want else "MISMATCH"); sys.exit(got != want)'
   ```

3. Unpack it in the home directory, then add it to the `PATH`, now and for every new shell:

   ```bash exec
   mkdir -p ~/.local/lib/npm ~/.local/bin && \
   tar -C ~/.local/lib/npm --strip-components=1 -xzf ~/npm.tgz && \
   rm ~/npm.tgz ~/npm.json && \
   ln -sfn ~/.local/lib/npm/bin/npm-cli.js ~/.local/bin/npm && \
   ln -sfn ~/.local/lib/npm/bin/npx-cli.js ~/.local/bin/npx && \
   export PATH="$HOME/.local/bin:$PATH" && \
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   ```

4. The lab image sets `NODE_ENV=production`, with which npm skips the development dependencies, the ones a test tool belongs to.
   Set it to `development`, now and for every new shell, then check the version:

   <!-- verify: expect="12." -->

   ```bash exec
   export NODE_ENV=development && \
   echo 'export NODE_ENV=development' >> ~/.bashrc && \
   npm --version
   ```
