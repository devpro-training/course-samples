<!-- include: ../../shared/setup.md -->

## On a workstation

The pipeline of this lab is a shell script, and its server is Git itself, so a workstation needs Git and a Bash shell.

System         | Command
---------------|-----------------------------------------------------
Windows        | `winget install --id Git.Git -e --source winget`, which includes Git Bash
macOS          | `brew install git`, or `xcode-select --install`
Debian, Ubuntu | `sudo apt install git`
Fedora         | `sudo dnf install git`

[git-scm.com/install](https://git-scm.com/install) is the reference for every system.

> [!NOTE]
> No account is needed anywhere in this lab: the Git server and the pipeline both run in the lab.
> The last step only writes a pipeline file in the syntax of a CI service, and checks it offline.

<!-- include: ../../shared/setup-git.md -->

<!-- include: ../../shared/setup-git-identity.md -->

## actionlint

[actionlint](https://github.com/rhysd/actionlint) checks a GitHub Actions workflow file without running it, and without an account.
It is a single binary, released with a checksum file.

1. Download the release and its checksums, check the archive against them, then unpack the binary in `~/.local/bin`:

   <!-- verify: requires=network timeout=120 expect="linux_amd64.tar.gz: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz" \
     "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_checksums.txt" && \
   sha256sum --check --ignore-missing "actionlint_${ACTIONLINT_VERSION}_checksums.txt" && \
   mkdir -p ~/.local/bin && \
   tar -C ~/.local/bin -xzf "actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz" actionlint && \
   rm "actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz" "actionlint_${ACTIONLINT_VERSION}_checksums.txt" && \
   export PATH="$HOME/.local/bin:$PATH" && \
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   ```

2. Check the version:

   <!-- verify: expect="built with go" -->

   ```bash exec
   actionlint -version
   ```
