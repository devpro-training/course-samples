## Git

[Git](https://git-scm.com/) is what a Git server speaks, and what Gitea itself runs for every repository.

1. Install it with the packages of the machine:

   <!-- verify: requires=network timeout=180 expect="git version 2." -->

   ```bash exec target=docker
   export DEBIAN_FRONTEND=noninteractive && \
   apt-get update -qq && \
   apt-get install -y -qq git > /dev/null 2>&1 ; \
   git --version
   ```

2. Record the identity of the commits, and name the default branch `main`:

   <!-- verify: expect="Ada Lovelace" -->

   ```bash exec target=docker
   git config --global user.name "${GIT_USER_NAME}" && \
   git config --global user.email "${GIT_USER_EMAIL}" && \
   git config --global init.defaultBranch main && \
   git config --global user.name
   ```

## Gitea

[Gitea](https://about.gitea.com/) is a Git server with a web interface, pull requests and an API, in one binary.
Each release is signed with a GPG key, so the binary is checked before it is installed.

1. Download the binary and its signature, and the public key by its fingerprint:

   <!-- verify: requires=network timeout=180 -->

   ```bash exec target=docker
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "${GITEA_URL}/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64" "${GITEA_URL}/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64.asc" && \
   wget -q "${GITEA_KEYS_URL}/${GITEA_GPG_FINGERPRINT}" -O gitea-key.asc
   ```

2. Compare the fingerprint of the key with the one of the documentation, then verify the signature.
   `gpg` warns that the key is not certified by anyone the machine trusts, which only says that the fingerprint above is what vouches for it:

   <!-- verify: timeout=60 expect="Good signature from" -->

   ```bash exec target=docker
   cd ~/lab && \
   gpg --show-keys --with-colons gitea-key.asc 2> /dev/null | grep -q "fpr:::::::::${GITEA_GPG_FINGERPRINT}:" && \
   gpg --import gitea-key.asc 2> /dev/null && \
   gpg --verify "gitea-${GITEA_VERSION}-linux-amd64.asc" "gitea-${GITEA_VERSION}-linux-amd64" 2>&1 | grep -E "Good signature|Primary key"
   ```

3. Install it, and check the version:

   <!-- verify: expect="built with go" -->

   ```bash exec target=docker
   cd ~/lab && \
   install -m 0755 "gitea-${GITEA_VERSION}-linux-amd64" /usr/local/bin/gitea && \
   rm "gitea-${GITEA_VERSION}-linux-amd64" "gitea-${GITEA_VERSION}-linux-amd64.asc" gitea-key.asc && \
   gitea --version
   ```

## The Git server

Gitea refuses to run as `root`, so it has a system user of its own, `git`, and its data lives in `/var/lib/gitea`.
The configuration is one file.
Gitea writes the secrets it generates into it at the first start, so the file belongs to the group `git`, which can write to it.

1. Create the user, the folders and the configuration.
   The database is SQLite, the web server listens on the loopback only, the installer is skipped (`INSTALL_LOCK`), and nobody can register:

   <!-- verify: expect="root:git 660" -->

   ```bash exec target=docker
   adduser --system --group --disabled-password --home /home/git --shell /bin/bash git > /dev/null && \
   install -d -o git -g git -m 750 /var/lib/gitea /var/lib/gitea/custom /var/lib/gitea/data /var/lib/gitea/log && \
   install -d -o root -g git -m 770 /etc/gitea && \
   tee /etc/gitea/app.ini <<EOT
   APP_NAME = Lab Git
   RUN_USER = git
   WORK_PATH = /var/lib/gitea
   RUN_MODE = prod

   [server]
   HTTP_ADDR = 127.0.0.1
   HTTP_PORT = 3000
   ROOT_URL = ${GITEA_BASE_URL}/
   DISABLE_SSH = true

   [database]
   DB_TYPE = sqlite3
   PATH = /var/lib/gitea/data/gitea.db

   [security]
   INSTALL_LOCK = true

   [service]
   DISABLE_REGISTRATION = true

   [log]
   MODE = console
   EOT
   chown root:git /etc/gitea/app.ini && chmod 660 /etc/gitea/app.ini && \
   stat -c '%U:%G %a' /etc/gitea/app.ini
   ```

2. Start the server.
   The machine runs no init system, so it is started in the background, as the user `git`.
   `runuser` keeps the current folder, which the user `git` cannot read, so the command moves to the folder of Gitea first:

   ```bash exec target=docker
   cd /var/lib/gitea
   nohup runuser -u git -- env GITEA_WORK_DIR=/var/lib/gitea gitea web --config /etc/gitea/app.ini > /var/log/gitea.log 2>&1 &
   ```

3. Wait until it answers:

   <!-- verify: timeout=90 expect="pass" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do wget -qO- "${GITEA_BASE_URL}/api/healthz" > /dev/null 2>&1 && break; sleep 1; done; \
   wget -qO- "${GITEA_BASE_URL}/api/healthz" | grep -m 1 '"status"'
   ```

4. Create the account of the lab, an administrator:

   <!-- verify: expect="successfully created" -->

   ```bash exec target=docker
   cd /var/lib/gitea && \
   runuser -u git -- env GITEA_WORK_DIR=/var/lib/gitea gitea admin user create --config /etc/gitea/app.ini \
     --admin --username "${GITEA_ADMIN_USER}" --password "${GITEA_ADMIN_PASSWORD}" --email "${GITEA_ADMIN_EMAIL}" --must-change-password=false
   ```
