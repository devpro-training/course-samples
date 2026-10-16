# Writing courses

How a course of this repository is researched, written and tested.
The sidelab reference is its `docs/courses.md`, this page only holds the choices made here and the lessons learned.

## Principles

- One topic per course, its key elements only, in about 10 minutes of video and 20 minutes of lab.
- A course is named after its topic, with no suffix: `labs/docker`, titled "Docker".
  This repository holds the introductory courses, advanced content lives in another repository.
- Nothing is hidden: every tool is installed by a visible step, so the lab can be reproduced on any machine.
- The content is the test: a lab is done when `course verify` is green, not when it reads well.
- Shared content is written once, in `labs/shared/`, and included where needed.
- Every value that can change, a version, a URL, an identity, is a variable.

## Course shape

```txt
labs/<course>/
├── lab.yaml
├── assets/            ← diagrams, a dark and a light SVG each
├── 01-setup/          ← installs the tools, from shared fragments
├── 02-intro/          ← slides: what, why, a diagram, what the lab covers
├── 03-.../            ← one step per key element, terminal and editor
└── 0n-summary/        ← slides: cheat sheet, good practices, next course
```

`01-setup/index.md` starts with `<!-- include: ../../shared/setup.md -->`, then includes one `labs/shared/setup-<tool>.md` per tool.

## Lab environment

The default lab image (`sidelab-app`) is Debian 12, run as `labuser`, with no root access and no `sudo`.
It carries node, wget, python3, dpkg-deb and Google Chrome, and no npm, curl, git, less, editor or unzip.
It sets `NODE_ENV=production`, with which npm skips the development dependencies.

- A Debian package is unpacked with `dpkg-deb -x <file>.deb ~/.local/`, rather than installed with `apt`.
- A zip is expanded with `python3 -m zipfile -e`.
- npm is unpacked from its registry tarball, which carries its dependencies, by `labs/shared/setup-npm.md`.
- A tool released as a single binary goes in `~/.local/bin`, which `labs/shared/setup-local-bin.md` creates and adds to the `PATH` once, before the fragments of the tools (`setup-jq.md`, `setup-crane.md`, `setup-cosign.md`,
  `setup-helm.md`), each checked against the checksums of its release.
- Terraform and OpenTofu are single binaries from a release zip, installed by `labs/shared/setup-terraform.md` (GPG key, signed checksums) and `labs/shared/setup-opentofu.md` (cosign),
  which need `HASHICORP_GPG_FINGERPRINT` and the `*_VERSION` variables under `env:`.
- A Python tool is installed in a virtual environment of the home directory, `python3 -m venv --without-pip ~/.<tool>-venv`,
  filled by the wheel of pip run as a zip (`python3 pip-<version>-py3-none-any.whl/pip --python ~/.<tool>-venv/bin/python install <package>`), which `labs/shared/setup-ansible.md` checks against the SHA-256 of the package index,
  and the `PATH` gets the `bin` folder of the environment.
- The Azure CLI is a pip package of the virtual environment (`labs/shared/setup-azure-cli.md`), Bicep a single binary compared with the digest GitHub shows for the asset (`setup-bicep.md`),
  and Azurite an npm package installed with `npm install --prefix ~/.azurite` (`setup-azurite.md`, which needs `setup-npm.md` first).
- Debian's own programs call `pager`, which is `more` in the image, so `PAGER=less` is exported once `less` is unpacked.

The terminal is reset when moving to another step, and a tool such as VS Code reads its environment from a new login shell,
so every `export` is also appended to `~/.bashrc`:

```bash
export PATH="$HOME/.local/usr/bin:$PATH" && \
echo 'export PATH="$HOME/.local/usr/bin:$PATH"' >> ~/.bashrc
```

A `${...}` that is not an `env:` name, such as `${workspaceFolder}` in a VS Code file, is left to the shell: it stays literal in a quoted heredoc, and is escaped (`\${...}`) in an unquoted one that expands an `env:` value.

Checking what the image carries, before depending on it:

```bash
docker run --rm --entrypoint bash sidelab-app:latest -lc 'id; cat /etc/debian_version; command -v git less curl'
```

When a course needs root, a kernel or systemd (Docker, Kubernetes), it declares a `runtime: vm` host instead, see [Virtual machine hosts](#virtual-machine-hosts).

## Virtual machine hosts

```yaml
backend: container
hosts:
  - name: control
  - name: docker
    runtime: vm
    cores: 2
    memory: 2048
    disk: 8192
```

- The first host is the lab container and stays a container, the machine of the course comes after it, and its blocks and panels say `target: <host>`.
- `backend: container` is declared by the course, since only that backend provisions a virtual machine.
  The launcher itself can stay on `local`, which is what `task verify:course` starts.
- The machine is Debian 12 on the lab image, its shell is `root`, so the course uses `apt-get`, with `DEBIAN_FRONTEND=noninteractive`.
- `disk` is declared when anything is installed: the default leaves about 226 MiB.
- The machine runs no init system, so a daemon is started with `nohup ... &`.
- The `env:` variables of `lab.yaml` reach the shell of the machine, as `${NAME}`, which a setup step checks by printing them (linux, docker).
- `HOME` is `/tmp` and `localhost` does not resolve there, so a command reaches a published port at `127.0.0.1`.
- The editor panel shows the files of the lab container only, so the files of the course are written by a command that shows their content.
- Docker Engine is installed by `labs/shared/setup-docker.md`, which a course includes after its own "On a workstation" section, and which needs the `DOCKER_*` variables under `env:` (docker, base-images).
- k3s is installed by `labs/shared/setup-k3s.md`, which needs `K3S_VERSION` and `K3S_RELEASE_URL` under `env:`, and a machine of 3072 MiB (a k3s server asks for 2 cores and 2 GiB at least) (kubernetes, k3s).
- k3d and kubectl are installed by `labs/shared/setup-k3d.md` and `labs/shared/setup-kubectl.md`, included after `setup-docker.md`, whose blocks target a host named `docker`:
  they need `K3DCLI_VERSION`, `K3DCLI_URL`, `KUBECTL_VERSION` and `KUBECTL_URL` under `env:`, and the course adds the image of its nodes (`NODE_IMAGE`) and a disk of 10240 MiB (k3d).
- A course on routing needs no more than k3d and kubectl, and k3s's own Traefik: `labs/shared/setup-k3d.md` and `setup-kubectl.md` after `setup-docker.md`,
  and the names of the lab mapped to `127.0.0.1` in `/etc/hosts` of the machine (ingress-controller).
- Gitea is installed by `labs/shared/setup-gitea.md`, after `setup-docker.md`: Git from apt, the release binary checked with GPG, a `git` system user, an `app.ini` and an admin account,
  with `GITEA_*` and `GIT_USER_*` variables under `env:` (gitops).
- Helm and kube-linter are installed in the machine by `labs/shared/setup-helm-machine.md` and `labs/shared/setup-kube-linter.md`, included after `setup-kubectl.md`,
  with `HELM_VERSION`, `KUBELINTER_VERSION` and `KUBELINTER_SHA256` under `env:`:
  `setup-helm.md` installs in `~/.local/bin` of the lab container, which is not the machine that reaches the cluster (helm).
- The Argo CD command line and Terraform are installed in the machine by `labs/shared/setup-argocd-cli.md` (`ARGOCDREL_VERSION`, `ARGOCDREL_URL`)
  and `labs/shared/setup-terraform-machine.md` (`TERRAFORM_VERSION`, `HASHICORP_GPG_FINGERPRINT`),
  and a web UI of the machine is published with a k3d port mapping and a NodePort, since `kubectl port-forward` dies on the first reset connection (argocd).
- A pod reaches Gitea of the machine as `http://host.k3d.internal:3000`, so the course makes Gitea listen on `0.0.0.0` after `setup-gitea.md` (argocd).
- The Flux command line is installed in the machine by `labs/shared/setup-flux-cli.md` (`FLUXREL_VERSION`, `FLUXREL_URL`), and SOPS with age by `labs/shared/setup-sops.md` (`SOPS_VERSION`, `SOPS_URL`, age from apt),
  after `setup-gitea.md` and the `labs/shared/setup-gitea-clusters.md` fragment that makes Gitea listen on `0.0.0.0` (flux).
- Rancher runs in a k3d cluster of the host `docker` (4 cores, 8192 MiB: the Rancher Pod alone uses about 1.7 GiB), published on the port 443 of the machine, with the name of the machine as its hostname,
  which the browser of the lab and the other hosts resolve,
  and a second host `kube` runs k3s from `labs/shared/setup-k3s.md`, included in the step that imports it (rancher).
- Several `runtime: vm` hosts of a course reach each other by their names (`https://kube:6443` from the host `agent`), and each has its own terminal, which a step shows with one `terminal` panel per `target` (k3s).
- Kubernetes, Podman and any other iptables user need the guest kernel of sidelab built from `scripts/firecracker_kernel.fragment` (`vmlinux-sidelab-<version>.bin`, `task setup:firecracker:bin`), and `FIRECRACKER_KERNEL` pointing at it:
  the CI kernel has no `xt_comment`, `xt_mark`, `multiport`, `statistic` or `recent` (kubernetes).
- The host needs the bridge pool of Firecracker (`task setup:firecracker` in a sidelab checkout, which needs `sudo`, and is lost on a restart of WSL).

## Variables

Every version, package name, URL or identity a block uses is declared under `env:` in `lab.yaml`, with the page it comes from in a comment:

```yaml
env:
  # https://packages.debian.org/bookworm/git
  GIT_DEB: git_2.39.5-0+deb12u3_amd64.deb
```

A block refers to `${GIT_DEB}`, never to the value.
A shared fragment uses the name only, and each course sets its own value.
The value in `lab.yaml` is a default, which a sidelab tenant (**Admin > Tenants > Environment**) or an account (**Profile > Environment**) can override.

A tool installed with its own script, such as the .NET SDK, goes under `~/.<tool>` and is added to `PATH` the same way, with the variables the tool reads (`DOTNET_ROOT`).
Its script and its signature are downloaded and verified in a visible step.

## Steps

- A component of a cluster, cert-manager, a controller or an operator, is installed with its Helm chart, its version pinned in an `env:` variable, as a real installation does, so it can be listed, upgraded and rolled back.
  `kubectl apply` of the manifest of a release is the exception, when that manifest is the subject of the step or the project publishes no chart, and the step says why.
- A step with a terminal also has an editor panel when files are created or changed.
- A file is shown with a link, `[Open hello.txt](:open:demo/hello.txt)`, relative to the course `workdir`, never with `cat` or `more`.
- The first block of a step moves to its folder explicitly (`cd ~/lab/demo && ...`).
  `course verify` runs every block in one shell without entering the steps, so a step `workdir:` is not applied there.
- A command that waits for input, a pager or an editor, stalls `course verify` until it times out, and the following blocks fail with it.
  `git commit -m` avoids the editor, `PAGER=less` exits on output shorter than the screen.
- A server the lab starts runs in the background with `nohup ... &`, and the block waits until it answers, with `wget --retry-connrefused`.
  It is stopped with `pkill -f "<command line>"`, not with a pid file.
- A block that waits is a bounded `for` loop, not an `until` loop, and it ends by printing the state it waited for:
  a loop that never ends holds the terminal, the next blocks are typed into it, and the whole run fails after a timeout that hides the first cause (k3d).
- A command that talks to a node, `kubectl exec` right after a restart for instance, runs with `timeout 20`, so one stuck attempt does not use the whole loop (k3d).
- A Markdown table has no pipe at the start or the end of a row.

## Web applications

An application started in the lab, such as code-server, is shown in a `vnc` panel: a Chrome running inside the lab, where `http://localhost:<port>` is the application.
A named tab keeps it open across steps:

```yaml
layout:
  - type: vnc
    url: http://localhost:8080/
    page: vscode
  - type: terminal
```

A `vnc` panel with no `url` opens empty, and a `[..](:navigate:<page>:<url>)` link in the step shows the application once it runs.

A `browser` panel reaches an application only through the `/app/<host>/<port>/` proxy, which does not carry WebSockets.

Instructions in a web UI are written against the real UI, checked with Playwright in the lab image before being written:

- a menu path or a command name, never an icon position, since extensions add icons;
- `course verify` cannot see what is done in the UI, so a terminal block that depends on it is marked `skip` with a reason.

The lab image has Chrome, and Playwright comes from a sidelab checkout, mounted read-only:

```bash
docker run --rm \
  -v "$PWD/probe.mjs:/p/probe.mjs:ro" \
  -v "<sidelab>/node_modules/playwright-core:/p/node_modules/playwright-core:ro" \
  --entrypoint bash sidelab-app:latest -c '<start the application> && cd /p && node probe.mjs'
```

`automation.yaml` can drive the same UI from the instructions, with links that click, fill or check for the learner.

## Checks

A directive in an HTML comment, right before the block, says what the block must produce:

```markdown
<!-- verify: requires=network timeout=180 expect="git version 2." -->
```

- `expect` names text only the output contains, since the terminal also echoes the command.
- `requires=network` goes on every block that downloads something.
- A failure in an early block cascades: the first failure of a run is the one to read.

## Diagrams

A course has at least one diagram, which shows how the topic works, whatever the topic: the parts and what moves between them.
One SVG per diagram for the dark lab, `<name>-dark.svg`, and one for the light PDF, `<name>.svg`, shown with:

```markdown
![Description](../assets/<name>-dark.svg#gh-dark-mode-only)
![Description](../assets/<name>.svg#gh-light-mode-only)
```

The light version is generated from the dark one by swapping colors:

Dark      | Light     | Use
----------|-----------|---------------
`#0f172a` | `#ffffff` | Background
`#1e293b` | `#f1f5f9` | Box
`#e2e8f0` | `#0f172a` | Text
`#94a3b8` | `#475569` | Secondary text
`#334155` | `#cbd5e1` | Separator
`#38bdf8` | `#0284c7` | Accent, blue
`#4ade80` | `#16a34a` | Accent, green
`#a78bfa` | `#7c3aed` | Accent, purple
`#fbbf24` | `#b45309` | Accent, amber

Rendering a diagram to check it:

```bash
google-chrome --headless=new --screenshot=diagram.png --window-size=1040,430 "file://$PWD/<name>-dark.svg"
```

## Workflow

1. Research the topic in the official documentation, and note the current version and recent changes.
2. Run every command by hand in the lab image, before writing a step.
3. Write the steps, then lint without a launcher:

   ```bash
   npx sidelab-cli course lint labs/<course>
   ```

4. Verify against a disposable launcher, from a sidelab checkout:

   ```bash
   task verify:course COURSE=<path>/labs/<course> CLI_ARGS="--capabilities network"
   ```

   When its build fails on a missing module, the checkout needs `npm install` first.

5. Review the slides with `course pdf`, and rehearse with `course record`.
6. Add what was learned to this page.

## Lessons learned

- Debian's Git calls `pager`, not `less`, so installing `less` is not enough without `PAGER=less` (git).
- Each step moves to its folder in its first block, so the commands can be run anywhere, not only in the lab (git).
- `git init` warns about missing templates when Git is unpacked outside `/usr`, which `init.templateDir` fixes (git).
- `git pull` on a diverged branch fails until `pull.rebase` is set, so the configuration step sets it (git).
- VS Code reads `PATH` from a login shell, so a tool only exported in the terminal is not found by it: "Git installation not found" (vscode).
- code-server opens a folder in Restricted Mode, where debugging and most extensions are disabled, so the course trusts it first (vscode).
- The Workspace Trust window stays open after **Trust**, and has to be closed with its **✕** (vscode).
- code-server's `/healthz` answers `expired` until a browser connects, so a check waits for the answer, not for `alive` (vscode).
- The lab image no longer carries npm (vscode).
- Checked in the image, Debian 12 already carries the libraries the .NET SDK needs (`libicu72`, `libssl3`, `tzdata`), so no ICU workaround is part of the course (dotnet).
- `dotnet-install.sh` does not set `DOTNET_ROOT` and does not touch the `PATH` of new shells, so the setup does both and appends them to `~/.bashrc` (dotnet).
- `dotnet test` prints `Passed!` without a terminal and a `Test summary: total: ...` line in one, so a check on its output names the part both runs share, or the one the terminal prints, since `course verify` types into a terminal (dotnet).
- A CLI-first tool, such as `dotnet`, is taught in the terminal with the lab editor for files, with no code-server: Visual Studio and Rider are a closing slide, not a dependency (dotnet).
- A web app the lab starts is run with `--no-launch-profile --urls`, since `launchSettings.json` holds a developer machine's ports and opens a browser, and `ASPNETCORE_ENVIRONMENT=Development` is set explicitly:
  it is `Production` otherwise, and the OpenAPI document is not served (dotnet).
- `kill $(cat <file>.pid)` on the `dotnet run` process stops its child too, so a step can free its port itself (dotnet).
- A link such as `:navigate:` is plain markdown, so its port cannot be an `env:` variable: the value is written in the link and kept equal to the variable by hand (dotnet).
- A `verify` directive's `expect` takes a double-quoted text, since single quotes are not parsed (dotnet).
- `$!` of a `nohup ... &` typed in the lab terminal was not the pid of `dotnet run`:
  `kill $(cat <file>.pid)` left the server running, which then answered the next step on the same port, with the old code, so a step stops its server with `pkill -f` (test-pyramid).
- A script that starts a server, checks it and stops it uses `trap 'kill $pid; wait $pid' EXIT`: without `wait`, the old process still holds the port when the script is run again at once (test-pyramid).
- A test of a bug needs the proof that it fails: the step breaks the code on purpose, expects the failure in a `verify` directive, restores the code, and expects the pass (test-pyramid).
- `dotnet test` of a solution prints `failed: 0, succeeded: 6` in the terminal, with the total of every project, and one `Passed!` line per project without a terminal (test-pyramid).
- Headless Chrome of the lab image needs `--no-sandbox`, since the container does not allow the namespaces of its sandbox, and `--dump-dom` prints the page after its script has run,
  with `--virtual-time-budget` to let it finish (test-pyramid).
- A test of a course that uses the real clock must hold on every day of the week: the end-to-end check accepts the total of a Friday as well as of other days (test-pyramid).
- `WebApplicationFactory` needs the web SDK in the test project, the `Microsoft.AspNetCore.Mvc.Testing` package at the ASP.NET Core patch version, and a public `Program` class (`public partial class Program;`) (test-pyramid).
- A course that has no instruction in a web UI, only links and a terminal, needs no Playwright probe: the browser of an end-to-end test is Chrome in the terminal (test-pyramid).
- A `verify` directive's `expect` is not expanded: a `${VAR}` in it stays literal, so it names text that does not depend on a variable, and not text that appears in the command, which the terminal echoes (github).
- A course that reads a service it does not own pins what it checks: a tag, a merged pull request or a commit never changes, a branch, a count of issues or the last run does (github).
- The repository of the course itself cannot be a fixture beyond its first commit and its default branch, since what is pushed to it changes, so checks on it are limited to the ones that hold forever (github).
- The GitHub API is read without a token at 60 requests per hour and per IP address, `/rate_limit` is not counted, and a request without a `User-Agent` is refused, which `wget` sends by itself: a course keeps to a few calls per run,
  and verifies on a shared address can hit the limit (github).
- A pull request is fetched with `git fetch origin pull/<n>/head:<branch>`, and `--depth` bounds the download to the commits of the pull request (github).
- On github.com, an anonymous visitor sees the tabs **Code**, **Issues**, **Pull requests**, **Actions**, **Projects** or **Discussions**, **Security and quality** and **Insights**, according to what the owner enabled,
  and the filter menus of the **Actions** page answer "Sorry, something went wrong" until signed in, so the instructions only name the buttons (github).
- A course taught with `gh` would need a token, which `course verify` has not, so GitHub is taught with Git, a browser and `wget`, which show what `gh` relies on (github).
- A course about a hosted service, GitHub Actions or GitLab CI, does not log in to it: the concept is taught with what runs in the lab, here a bare repository with a `post-receive` hook as the CI server,
  and the services appear as a file checked offline and a table of equivalent keys (cicd).
- The pipeline logic lives in a script of the repository, and the hook and the service file only call it, so the course is not tied to one product (cicd).
- A `post-receive` hook cannot refuse a push, and its output comes back to the pusher as `remote:` lines, which a `verify` directive reads like any other output (cicd).
- The lab image's default directory is not writable by `labuser`: a block run from `/` fails with "Permission denied", so every block starts with `cd ~/lab` or its step folder, also when it is tried by hand in `docker run` (cicd).
- A release archive is checked with `sha256sum --check --ignore-missing <name>_checksums.txt`, which skips the other platforms listed in the file (cicd).
- A file with `${{ ... }}`, such as a GitHub Actions workflow, written by an unquoted heredoc that expands `env:` values escapes it as `\${{ ... }}` (cicd).
- A step finds its artifacts with `git rev-parse --short=7 <commit>`, the length the pipeline cuts the commit to, since a bare `--short` can grow with the repository (cicd).
- A course whose instructions are a terminal and an editor, with no web UI, needs no Playwright probe, as for test-pyramid (cicd).
- `NODE_ENV=production` in the lab image makes `npm install --save-dev` print "up to date, audited 1 package" and install nothing, so `npx` then downloads the tool on its own, and a config that imports it fails with `MODULE_NOT_FOUND`:
  the setup exports `NODE_ENV=development` (playwright).
- npm is not in the image, and its registry tarball unpacks and runs with `bin/npm-cli.js`, since it bundles its dependencies: the setup compares its `sha512` with the `dist.integrity` of the registry metadata (playwright).
- `npx playwright install --only-shell chromium` downloads the headless Chromium only, about 120 MB, where `chromium` alone is more than 400 MB (playwright).
- `npx playwright show-report` listens on `localhost`, which `wget` and a probe reach on `127.0.0.1` only with `--host 127.0.0.1` (playwright).
- `a && b &` puts the whole chain in the background, `cd` included, so a command that starts a server is on a line of its own (playwright).
- A step that fails on purpose is written `{ <command> || true; }`, and its `expect` names a line of the failure, since a non zero exit status fails the block (playwright).
- The tests of a Playwright course are themselves the probe of the app, and the probe of the HTML report and the trace viewer found that the links of the report render late,
  so a probe waits for the first **View Trace** link before counting them (playwright).
- A `verify` directive checks the count of a run, so adding a test file changes the `expect` of every later step that runs the whole project (playwright).
- npm 12 prints `npm notice run <project> <event>` and `npm notice run <command>` before any command it runs with the terminal attached, `npx` included, from `@npmcli/run-script`:
  it replaces the `> project@1.0.0 script` banner and only disappears with `--loglevel=warn`, so the course explains the two lines where they first appear instead of hiding them (playwright).
- A `runtime: vm` host named `image: debian:bookworm-slim` never got a shell ("The shell never became ready"), where the lab image did, so the Docker host uses the lab image, which also carries `wget`, `gpg` and `python3` (docker).
- `env:` values are not set in the shell of a `runtime: vm` host, so every `${NAME}` was empty and the apt source file was written without its URL: the setup step defines them in the machine (docker).
- A port published by Docker accepts the connection before the server answers, then resets it, which `wget --retry-connrefused` does not retry: a loop of `wget ... && break; sleep 1` does (docker).
- `docker compose exec` fails in `course verify` with "cannot attach stdin to a TTY-enabled container", so a command read by a script uses `exec -T` (docker).
- `docker compose` and `docker pull` print progress with changing spaces and carriage returns when there is no terminal to redraw, so a check names a word such as `stack_default`, not a whole line (docker).
- Docker 29 stores images with the containerd snapshotter: `docker images` prints `IMAGE`, `DISK USAGE` and `CONTENT SIZE`, and `.NetworkSettings.IPAddress` is gone, the address is under `.NetworkSettings.Networks.<network>` (docker).
- Docker's package signing key is checked with `gpg --show-keys --fingerprint` against the fingerprint of the installation page, which the setup keeps in a variable (docker).
- A course whose instructions are a terminal needs no Playwright probe, as for cicd (docker).
- A disposable launcher kept with `KEEP=1` holds port 3151 until its process group is killed: `kill -- -$(cat /tmp/sidelab-verifycourse-*/launcher.pid)` (docker).
- A `verify` directive's `expect` is refused by the linter when its text is in the command, a heredoc included: the check names a count (`wc -l` prints `8 access.log`), a status (`echo "status $?"`) or a path only the output prints (linux).
- A course that needs root, users, `sudo` or `apt` runs all of its steps in one `runtime: vm` host, whose shell is `root`: `adduser`, `runuser -u <user> --`, `apt-get install sudo` and `systemd-analyze verify` all work there (linux).
- `runuser -u <user> -- <command>` acts as another user from a root script, and `sudo -S` reads the password from its input, so `echo "<password>" | runuser -u <user> -- sudo -S <command>` runs without a person typing (linux).
- `/etc/sudoers` separates its fields with a tab, so a check names `parsed OK`, the line `visudo -c` prints, and not the rule (linux).
- The machine has no init system, so `systemctl` answers "System has not been booted with systemd as init system", and a systemd course writes a unit file and checks it with `systemd-analyze verify`,
  which needs no running systemd and reports `is not executable` for a missing program (linux).
- bash remembers where it ran a command, so `command -v tree` still prints `/usr/bin/tree` after the package is removed until `hash -r` (linux).
- Debian 12 merged `/bin`, `/sbin` and `/lib` into `/usr`: `dpkg -S /bin/ls` finds `coreutils`, and `dpkg -S /usr/bin/ls` finds nothing (linux).
- As `labuser`, `apt-get update` fails on `/var/lib/apt/lists`, and works with `Dir::State`, `Dir::Cache` and `Debug::NoLocking` set in a file named by `APT_CONFIG`,
  after which `apt-get download` and `dpkg-deb -x` give a package without root, with one harmless `rm: cannot remove` line from the image's `docker-clean` hook (linux).
- Some pages of the official sources, the Red Hat blog and the freedesktop.org manuals, refuse the fetch tool (404 or 403): a claim taken from a search excerpt of such a page is worded as the excerpt says,
  with the page linked in the slide (linux).
- Dates and versions in slides, Debian and Ubuntu releases, the lifecycle of RHEL and SLES, age quickly: each is stated with its date and checked again when the course is revisited (linux).
- A privileged lab-image container run as root (`docker run --privileged --user root --cgroupns=host`) is enough to try `chroot`, `unshare`, cgroups and Podman before writing a step,
  and only `course verify` proves the steps in the machine itself (containers).
- `busybox --install -s /bin` run from the host writes symlinks to the host's path, which dangle in the new root, so `chroot <root> /bin/busybox --install -s /bin` creates them from inside (containers).
- A cgroup memory limit does not kill the process while swap is available: `memory.swap.max` is set to 0 as well, and the process then ends with status 137 (containers).
- `podman` resolves a short image name only with a `registries.conf`, so a course writes the full name, `docker.io/library/alpine:3.22` (containers).
- `docker create <image> /unused` is needed for an image with no command, and `docker export <container> | tar -t` lists the files of an image that has no shell (base-images).
- `command -v` of busybox `ash` takes one name, so a list of programs is tested with a `for` loop, and `docker top` needs the `pid` field: `-o pid,user,args` works, `-eo user,args` fails with "Couldn't find PID field" (base-images).
- `ARG BASE` before the first `FROM` makes the base image a build argument, and in an unquoted heredoc that expands `env:` values it is written `FROM \${BASE}` (base-images).
- A comparison of vendors states what their own pages state and flags the rest: a free tier, a CVE count or a reduction rate is a claim until measured, and a product with no public page (WizOS,
  in private preview) is described by what its announcement does not say (base-images).
- Offers change within months:
  Chainguard's free images are `latest` only, Docker Hardened Images answer `unauthorized` to an anonymous pull from `dhi.io`, and SlimToolkit's last release stops with "client version 1.33 is too old" against Docker 29,
  so a slide dates every claim and the lab only pulls what is anonymous (base-images).
- A course that is the prerequisite of another is written first: Containers explains the kernel and the OCI standards once, and Docker and Container base images refer to it (containers, base-images).
- The courses of this series with no web UI need no Playwright probe, as for docker (containers, base-images).
- A course about images and registries needs no container engine:
  `crane` lists tags and reads manifests and configurations, `cosign` reads and verifies what is attached, and `helm template` renders a chart with no cluster, all as `labuser` in the lab container (app-catalog).
- `crane export <image> - | tar -xO --wildcards '*os-release'` names the Linux behind an image of any distribution, since `/etc/os-release` is a symlink on Debian and a file on others,
  and the labels of `crane config` give the declared base image with no download of the layers (app-catalog).
- `crane registry serve --address 127.0.0.1:5000 --disk <dir>` runs a registry as `labuser`, `cosign copy` copies an image with its signature and attestations,
  and `cosign verify --allow-insecure-registry` checks the copy over HTTP (app-catalog).
- `cosign verify-attestation` on a multi-platform tag reads the attestation of the index, an SBOM of three entries, so the SBOM of an image is read at the digest of its platform, from `crane digest --platform linux/amd64` (app-catalog).
- Docker Hub answers `UNAUTHORIZED: authentication required` for a repository that does not exist, and `MANIFEST_UNKNOWN` for a tag that does not exist: a check of something gone names these words (app-catalog).
- A `jq` filter that prints `"label: \(.value)"` holds the label in the command, which the linter refuses as an `expect`: the check names the label with the start of its value, `publisher: library`,
  `entrypoint: docker-entrypoint` (app-catalog).
- SUSE Application Collection serves its metadata API and the documents of each image, SBOMs, SLSA provenance and scans, with no account, and its registry only with one: the pull and signature blocks read declared optional `secrets:`,
  and are `skip` with a reason, the rest of the step being verified (app-catalog).
- The GitHub API refused anonymous calls after a few dozen requests during research, and `curl -sI https://github.com/<owner>/<repo>/releases/latest` gives the latest version in its `location` header with no API call (app-catalog).
- Testing a step block by block with `docker exec <container> bash -c` misses `~/.bashrc`, which Debian's version leaves early for a shell that is not interactive, so the blocks are run with `bash -ic`,
  as the lab terminal does (app-catalog).
- The probe of the Application Collection found its subscription chip twice in the page, the cells of a table row joined with no space (so `\b` does not match inside a row's text), and tab names that end with a count, `VULNERABILITIES 0`,
  so a probe uses `.first()`, plain patterns, and checks the tab texts (app-catalog).
- A course that compares publishers, a community project, a vendor or an individual maintainer, states what each one's pages state, measures the rest in the lab, and judges none of them:
  each is a dependency with its own way to fail (app-catalog).
- A course that depends on a vendor's catalog pins what it reads, chart versions and image branches, as variables, since the vendor's `latest` and its terms change between two runs (app-catalog).
- Docker can be tried before writing a step in a lab-image container run as root and privileged (`docker run --privileged --user root --cgroupns=host`), built from `sidelab-app` with Docker Engine installed,
  and with a host directory mounted on `/var/lib/docker` so the images pulled by the inner daemon stay between runs, which only `course verify` then confirms in the machine itself (container-security).
- A course on risks shows each one working before the option that closes it, in the order risk, logic, solution, limit, and states for each solution what it needs and what it ties the team to (container-security).
- A talk or slides of the author are an input for the course: their principles and their order of concerns come first, and the official documentation checks every fact (container-security).
- The default seccomp profile is shown by `unshare --user`, refused with `Operation not permitted` and allowed with `--security-opt seccomp=unconfined`, where `unshare --pid` is refused in both cases,
  since it needs `CAP_SYS_ADMIN` which the default capabilities lack (container-security).
- `docker run --cap-add SYS_ADMIN` is enough for `mount` to work with the default seccomp profile, which adapts to the capabilities added: only `--privileged` removes the profile (container-security).
- The `alpine` image cannot run the Docker client copied from the host, so a container that receives the socket uses the `docker:<major>-cli` image (container-security).
- `capsh --decode=<mask>` from `libcap2-bin` names the capabilities of a `CapEff` line of `/proc/self/status`, which is `a80425fb` for the fourteen default ones of Docker (container-security).
- `docker history --no-trunc` shows a build argument twice (the `ARG` and the `RUN` that uses it), and nothing for a `RUN --mount=type=secret`, so a check counts the lines with `grep -c` (container-security).
- `userns-remap: default` in `/etc/docker/daemon.json` creates `dockremap` with `dockremap:100000:65536` in `/etc/subuid`, and the daemon is restarted with `pkill -f "^dockerd"` then `nohup dockerd`,
  the anchor keeping the pattern from matching the shell that types it (container-security).
- The permission check of the agent refused to download and run Docker Bench for Security, a script from GitHub, so it is described in the slides with the facts of its README and not run in a step (container-security).
- The page of the Kubernetes documentation on cloud native security now follows the lifecycle of the CNCF (develop, distribute, deploy, runtime), and the four layers (cloud, cluster, container, code) are its older model:
  a fetch of such a page truncates after 100000 characters, so a claim taken from its end is checked with an offset (container-security).
- The kernel of a WSL probe or of a lab machine can lack AppArmor and SELinux (`/sys/kernel/security/lsm` absent), so a step cannot depend on them, and they stay in the slides with their limits (container-security).
- Trivy needs no container engine: `trivy image <registry>/<name>:<tag>` reads the registry, and its vulnerability database and check bundle are OCI artifacts downloaded on the first scan from `mirror.gcr.io/aquasec/` (trivy).
- Trivy releases carry a `.sigstore.json` bundle per asset since v0.68.1,
  checked with cosign 3 as `cosign verify-blob <archive> --bundle <archive>.sigstore.json --certificate-oidc-issuer <issuer> --certificate-identity <reusable-release.yaml>@refs/tags/v<version>`, which prints `Verified OK` (trivy).
- A tool with a supply chain incident of its own is installed as the release binary, with a pinned version, a checksum and a signature, and the course states the incident with its dates from the vendor's advisory:
  the sources disagreed on the count of moved tags of the action (75 or 76), so the advisory's figure is quoted (trivy).
- A pipeline pins the SHA-256 of the archive in the repository, since the checksum file of a release is published beside the archive and changes with it, and an action by its full commit SHA,
  which `git ls-remote <repository> 'refs/tags/<tag>^{}'` gives for an annotated tag (trivy).
- Scan numbers change every day with the database: a check names a status (`affected:`), a format (`UNKNOWN:`), or a finding of an old pinned version that never goes away (`CVE-2020-14343` for `pyyaml==5.3.1`),
  and a gate is set on `CRITICAL` so that a new medium finding in a fixed version does not break the course (trivy).
- A supported minimal image (Alpine 3.22) can scan clean, an end of life one prints "no longer supported by the distribution", and only Debian showed the statuses `affected`, `fix_deferred` and `will_not_fix`,
  so the unfixed findings are shown on `debian:12-slim` (trivy).
- `trivy config` has no `--no-progress` flag, and prints only a table and a legend when clean, so a clean result is checked with `--exit-code 1` and `echo "status $?"` (trivy).
- A secret fixture is built by `printf 'token = "ghp_%s"' "<36 characters>"`, so the repository holds no complete token for a push protection to flag (trivy).
- Three scanners on one `requirements.txt` list `pyyaml` and `requests` for Trivy and Grype, and also `idna` and `urllib3` for OSV-Scanner, which resolves transitive dependencies through the OSV service,
  and Trivy names a weakness `CVE-2020-14343` where Grype names it `GHSA-8q59-q68h-6hv4`: a course that compares tools compares what they find, and states that none is the source of truth (trivy).
- The linter refuses an `expect` text that the command contains, a `echo "... components: ..."` included, so the label of an `echo` is written around the value (trivy).
- The courses of this series with no web UI need no Playwright probe, as for docker (trivy).
- A course on a tool that needs a cloud account teaches the idea on a local environment, a folder of files, with a small tool the learner reads (87 lines of Python: plan, apply, a state of managed paths),
  and shows the real tools as files that are only read, since they run in the next courses (iac).
- A script that fails on its first command still exits with the status of its last one:
  `mkdir` printed "File exists" and `echo "status $?"` printed `status 0`, which makes a better demonstration of the imperative style than any explanation (iac).
- A fingerprint of a folder, `find ... | sort | xargs sha256sum | sha256sum`, kept in two files and compared with `sort -u | wc -l`, proves that a second run changed nothing,
  with an `expect="distinct: 1"` that the command does not contain (iac).
- `trivy config` reads Terraform with no cloud and no plan: a security group open on port 22 to `0.0.0.0/0`, a public ACL and a bucket with no public access block gave seven HIGH findings (`AWS-0086` to `AWS-0132`),
  and the fix that reaches zero needs the public access block, a KMS key with rotation, and an SSE-KMS configuration, so a step lists the findings with `grep -E "^AWS-"` (iac).
- A Terraform file is no longer clean of lower severities after the fix (versioning, access logs), so the gate names `HIGH,CRITICAL` and the step says the gate is a decision (iac).
- A playbook of `ansible.builtin.copy` put in the folder of a scan produced no result, although the coverage page of Trivy lists Ansible, and Bicep is not on that list: the course scans Terraform only and states what the page names (iac).
- The Terraform registry page of a provider returns only its title to the fetch tool, and the same documentation is read from `raw.githubusercontent.com/hashicorp/terraform-provider-<name>/main/docs/resources/<resource>.md`,
  where `local_file` has `file_permission` with a default of `"0777"` (iac).
- A folder bind-mounted from the host is not writable by `labuser` (uid 1001), so a render of a diagram in the lab image to a mounted folder runs with `--user root` besides `--no-sandbox` (iac).
- A vendor event is dated from the vendor's own page and not from a summary: the license change of 10 August 2023 (HashiCorp),
  the announcement of OpenTofu of 20 September 2023 (Linux Foundation) and the completion of the acquisition of 27 February 2025 (IBM), where one search result gave 2024 (iac).
- The courses of this series with a terminal and an editor only, and no web UI, need no Playwright probe, as for docker (iac).
- A course on a tool that needs a cloud account is taught with providers that need none:
  `hashicorp/local` and `hashicorp/random` make files and names, `terraform init` downloads them from the registry, and everything runs as `labuser` in the lab container (terraform).
- Terraform has no Debian package and no signed script: the release zip is checked with `gpg --show-keys --with-colons ... | grep -q "fpr:::::::::<fingerprint>:"` against the fingerprint of HashiCorp's security page,
  then `gpg --verify` of the `SHA256SUMS.sig`, then `sha256sum --check --ignore-missing`, and `gpg` is in the lab image (terraform).
- `python3 -m zipfile -e` drops the executable bit, so a binary unpacked from a zip is installed with `install -m 0755` (terraform).
- OpenTofu's checksums are signed keylessly:
  `cosign verify-blob --signature ... --certificate ...` with the identity `<workflow>@refs/heads/v<major.minor>`,
  which prints a deprecation notice for `--signature` and `--certificate` that the step filters with `grep -v deprecated` (terraform).
- `terraform` prints colors in the lab terminal, and they cut a line such as `Plan: 1 to add` in separate spans, so a check names text inside one span (`1 to add, 0 to change, 0 to destroy`,
  `Apply complete! Resources: 1 added`) (terraform).
- A step that runs `terraform plan` or `apply` with no value for a variable waits for an answer, so `-input=false` and `-auto-approve` are on every block, and a failure on purpose is `{ ... || true; }` (terraform).
- A change of the content of a `local_file` is `-/+` with `# forces replacement`, and a file edited by hand is reported by the refresh as deleted, so the drift of this provider shows as a resource to create again (terraform).
- The list of versions of the registry API (`registry.terraform.io/v1/providers/<namespace>/<type>/versions`) is not sorted:
  `hashicorp/local` listed 2.6.2 last while the latest was 2.9.1, so a version is taken from a sorted list or from `.../providers/<namespace>/<type>` (terraform).
- `terraform init -upgrade` is the only way past a lock file that holds an older version than the constraint allows,
  and a constraint that excludes the locked version fails with "locked provider ... does not match configured version constraint" (terraform).
- A backend block cannot use variables, and `terraform init -backend=false` then `validate` checks a block for a backend that the lab cannot run, such as the HTTP backend of terraform-backend-mongodb,
  which needs MongoDB and a container engine (terraform).
- The tier of a provider is read in the registry API (`tier` is `official`, `partner` or `community`), the page of the Terraform documentation on tiers answered 404, so the claim is worded as the provider overview page says (terraform).
- `tofu` reads the state and the code written by Terraform and plans no change, rewrites the lock file for `registry.opentofu.org` and keeps the versions, and writes its own version in the `terraform_version` field of the state (terraform).
- The `type` argument of an `output` is accepted by Terraform 1.16, and left out here so the same files run with OpenTofu (terraform).
- The courses of this series with a terminal and an editor only, and no web UI, need no Playwright probe, as for docker (terraform).
- The image has Python 3.11, no pip and no `ensurepip`, and `pip install --user` is refused (PEP 668): pip comes from its wheel, run as a zip, and installs into a virtual environment made with `--without-pip` (ansible).
- A tool pinned to what the lab runs states why:
  `ansible-core` 2.20 and 2.21 need Python 3.12 or newer on the control node, so the course uses 2.19, whose end of life is November 2026 in the support matrix, and the slide dates it (ansible).
- A lab with no SSH server reaches its hosts with `ansible_connection: local`, set once in `group_vars/all.yml`, and each host owns a folder computed from `playbook_dir` and `inventory_hostname`:
  the only difference with a real node is the connection (ansible).
- `interpreter_python = auto_silent` in `ansible.cfg` removes the "discovered Python interpreter" warning that Ansible prints for each host (ansible).
- An inventory source of truth is taught with a small one the lab owns: a JSON document served by `python3 -m http.server`, read by an executable script that prints `--list` with `_meta` and `hostvars`, so no call per host is made,
  while the plugins of NetBox (`netbox.netbox.nb_inventory`) and ServiceNow (`servicenow.itsm.now`) are only read, since they need a server and credentials (ansible).
- A group of an inventory is an identifier, so the CMDB environment `prod` becomes `env_prod`, and `group_vars/env_prod.yml` then carries what differs per environment (ansible).
- `command` and `shell` always report `changed`, and are skipped by `--check`: showing them next to `file` and `copy` is the shortest proof of idempotence, with `changed=2` twice, then `changed=0` (ansible).
- `ansible-playbook` colors its recap in the lab terminal, so a check names one token (`changed=0`, `skipped=2`) and not the spacing between two of them (ansible).
- `ansible-doc` pages its output, so a block pipes it to `head`, and `-s` prints the snippet of a module (ansible).
- `ansible-lint` without a `.ansible-lint` file warns that `/.ansible` is not writable, and with one containing `profile: production` the project passes, the playbook with a bare `shell` fails (ansible).
- Handlers run once at the end of the play and only when a notifying task changed something: the second apply shows `changed=0` and no `RUNNING HANDLER` (ansible).
- `ansible-vault encrypt_string` with a `vault_password_file` in `ansible.cfg` encrypts a value into `group_vars/all/vault.yml`, beside the plain `vars.yml` of the same group, with `no_log: true` on the task that uses it (ansible).
- The courses of this series with a terminal and an editor only, and no web UI, need no Playwright probe, as for docker (ansible).
- A cloud course needs no account when it teaches what the cloud answers to anyone: the sign-in service publishes the tenant of a domain (`login.microsoftonline.com/<domain>/v2.0/.well-known/openid-configuration`),
  Resource Manager answers `401` with a `WWW-Authenticate` header to a call with no token, `az rest --skip-authorization-header` reads its public metadata, and the Retail Prices API lists the prices (azure).
- `az account show` prints "Please run 'az login' to setup account." with no account, and `terraform plan` with the `azurerm` provider stops at "unable to build authorizer for Resource Manager API" naming the same command:
  the failure shows that the provider is a client of Resource Manager and takes its identity from the CLI (azure).
- ARM names the service, Azure Resource Manager, and its JSON template format, and `azurerm` and the `ARM_` environment variables of the Terraform provider are named after the service: the course says so where each appears,
  and that it is not the Arm processor (azure).
- `terraform init` of `hashicorp/azurerm` 5.9.0 and `terraform validate` need no account, `plan` needs `ARM_SUBSCRIPTION_ID` and a token, and a provider block with no `subscription_id` takes the first from the environment,
  so the file holds no identifier (azure).
- Azure CLI 2.91.0 needs Python 3.10 or newer, so it runs on the 3.11 of the image, and installs in about 40 seconds with pip into `~/.azure-venv`, 705 MB,
  with `az config set core.collect_telemetry=false` to turn its usage data off (azure).
- Bicep releases carry no checksum file, so the course pins the SHA-256 that GitHub shows for the asset `bicep-linux-x64` in a variable, as for Trivy:
  `az bicep install` would download the same binary into `~/.azure/bin`, with no check (azure).
- `bicep build` of a file with `targetScope = 'subscription'` and a module gives a nested deployment of type `Microsoft.Resources/deployments` in the template, and `bicep decompile` of the result fails on the `dependsOn` it wrote,
  which is why the course does not teach it (azure).
- Azurite 3.37.0 needs Node.js 22 or newer, is started with `azurite-blob` only (the `azurite` program also opens the queue and table ports), accepts the requests of Azure CLI 2.91.0 with no `--skipApiVersionCheck`,
  puts the account name in the path of the URL, and answers an anonymous read of a private container with `403` and `x-ms-error-code: AuthorizationFailure` (azure).
- The published key of Azurite's built-in account, `devstoreaccount1`, is flagged by gitleaks as a generic API key, so the emulator step makes a key with `head -c 64 /dev/urandom | base64 -w0`,
  and `AZURITE_ACCOUNTS="<account>:<key>"` replaces the built-in account, which then answers `404` (azure).
- The emulator holds the data plane only: `az storage account list` still answers "setup account", which makes the difference with the control plane visible (azure).
- Azurite stops with `pkill -f "^node .*azurite-blob"`: the program is a Node.js script, and the anchor keeps the pattern from matching the shell that types it (azure).
- The Azure Retail Prices API needs no account:
  `$filter` is written `%24filter` in the URL, and `jq -rn --arg f "<expression>" '$f|@uri'` encodes the OData expression, a Windows price carrying the license,
  so the Linux line is selected with `select(.productName | test("Windows") | not)` (azure).
- A figure about a vendor is quoted from its primary source with its date: 80+ regions and 500+ datacenters from Microsoft's page, which states no date, and 28%, 20% and 15% from the release of Synergy Research of 30 July 2026,
  since search summaries and secondary pages disagreed on the figures of the previous year (azure).
- The rename of Windows Azure to Microsoft Azure is dated March 2014 by one source and April 2014 by others, so the slide gives the year only;
  the rename of Azure Active Directory to Microsoft Entra ID is dated 11 July 2023 by the page of Microsoft (azure).
- A course on a cloud with no account has no instruction in a web UI, since the portal needs a sign-in, so it needs no Playwright probe: the portal is described in the slides and the steps are a terminal and an editor,
  as for docker (azure).
- A course on Kubernetes runs a distribution, k3s, in a `runtime: vm` host: it is one binary, started with `nohup k3s server`, ready in about a minute, and it carries `kubectl`, which a link named `kubectl` runs,
  so the course installs one verified binary and nothing else (kubernetes).
- The `k3s` release publishes `sha256sum-amd64.txt` beside the binary, the `+` of `v1.36.5+k3s1` is written `%2B` in the URL (`${K3S_VERSION/+/%2B}`),
  and the version is the stable channel of `https://update.k3s.io/v1-release/channels` (kubernetes).
- With the guest kernel built without netfilter extensions, k3s logs `Extension comment revision 0 not supported, missing kernel module?` and `RULE_APPEND failed ... FLANNEL-FWD`, the Pods start,
  CoreDNS stays at `0/1` with a readiness probe at 503, and `nslookup`, a ClusterIP and a NodePort all time out: only a kernel built from the fragment passes (kubernetes).
- `.env` of the sidelab checkout can still point `FIRECRACKER_KERNEL` at an older kernel than the one built, so `FIRECRACKER_KERNEL=<path> task verify:course ...` tries another kernel for one run,
  and `uname -r` ends with `+` for both (kubernetes).
- A k3s server runs the API server, the scheduler and the controller manager in its own process, so `kube-system` holds CoreDNS, the local path provisioner, metrics-server and Traefik, and no Pod for the control plane,
  where kubeadm clusters have static Pods (kubernetes).
- The node shows the role `<none>` for the first seconds and `control-plane` after, so the wait loop runs `grep ' Ready.*control-plane'` (kubernetes).
- k3s keeps the objects of the cluster in SQLite behind Kine:
  `/var/lib/rancher/k3s/server/db/state.db` has one table, `kine`, with a row per revision of a key (`/registry/namespaces/kube-system`), `deleted` and `id`, and a value in the binary format of Kubernetes that starts with `k8s`,
  read with the `sqlite3` module of the image's Python in read-only mode (`file:...?mode=ro`, `uri=True`), where `sqlite3` the program is absent (kubernetes).
- A Secret created with `kubectl create secret generic --from-literal` is found in clear in that file, as the Kubernetes documentation says of etcd, and k3s enables encryption at rest with `--secrets-encryption` (kubernetes).
- `kubectl wait` fails at once with `no matching resources found` when the Pods do not exist yet, so a step right after the start of the server first loops until `kubectl get pods --selector ... --no-headers | grep -q .` (kubernetes).
- busybox `nslookup web` resolves the Service, then asks the search domains of the Pod and exits with status 1 on their NXDOMAIN lines: the name is given complete with a final dot, `web.default.svc.cluster.local.` (kubernetes).
- `kubectl run --rm -i --restart=Never` prints `couldn't attach to pod, falling back to streaming logs` when the command ends before the attach, which does not change the output (kubernetes).
- `course verify` prints the output of a failed block only: a temporary course in the repository, whose blocks expect a text that never appears, shows what a command printed,
  and it has to be inside the repository since an include outside the working directory is refused (kubernetes).
- A privileged container with `--cgroupns=host` is a bad probe for k3s: the kubelet creates `kubepods` in the cgroup tree of the host, which stays after the container is removed,
  and the next k3s fails with `cannot enter cgroupv2 "/sys/fs/cgroup/kubepods" ... invalid state`, so the machine of `course verify` is the test (kubernetes).
- The fetch tool returned the Russian translation of the Kubernetes blog post on Borg, and nothing on the CNCF page about its foundation date:
  the dates of 21 July 2015 (version 1.0 and the donation) and 6 March 2018 (the first graduated project) come from the announcements of the CNCF,
  the 2014 open sourcing and the 15 years of experience from the Kubernetes documentation (kubernetes).
- A claim that depends on the build, such as Kubernetes being written in Go, is shown by the lab: `kubectl version -o json` prints `goVersion` for the client and the server (kubernetes).
- The words of the course are control plane and worker node, as in the Kubernetes documentation, and the page of k3s calls them server and agent, which the slides say once (kubernetes).
- The courses of this series with a terminal and no web UI need no Playwright probe, as for docker (kubernetes).
- An `env:` variable is read by the tools of the lab when its name is theirs:
  `K3S_URL` made `k3s server` try to join the GitHub release URL and exit, `KUBE_BENCH_VERSION` made kube-bench refuse `--benchmark`, so the variables of a course are named apart (`K3S_RELEASE_URL`, `KUBEBENCH_VERSION`),
  and the `K3S_TOKEN` of the course is one k3s reads on purpose (k3s).
- A block that waits is a loop with the exit it needs and nothing else:
  `grep -q traefik` also matched the `Completed` Jobs of the Helm controller and the loop ended only with its timeout, and a loop that breaks on `kubectl` failing breaks while the API restarts,
  so a restart is followed by `until kubectl get --raw /readyz` (k3s).
- `course verify --show-output` prints the output of a block when it ends, so a log that stops on an empty prompt is a block still running, and the k3s course (67 blocks, two machines) runs in about three minutes,
  the Kubernetes course in about one: a run that is much longer is a loop waiting for something that never happens (k3s).
- When a block times out, the next blocks are typed into the terminal that still runs it and wait behind it, so the first failure is the only one to read (k3s).
- The state of a `runtime: vm` host is read from the host without a shell in it: `debugfs -R "cat /var/log/k3s.log" ~/.local/share/sidelab/firecracker/run/<id>-kube/rootfs.ext4` prints a file of a running machine (k3s).
- The install script of k3s does not stop on a machine with no init system, since it only looks for a `systemctl` program: with no option it downloads and replaces the binary, then fails on the service,
  and `INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_SKIP_ENABLE=true INSTALL_K3S_SKIP_START=true` makes it write the symlinks, the service file, the environment file (mode 0600,
  with the `K3S_` variables) and the killall and uninstall scripts only, which a step reads and the removal step runs (k3s).
- With `K3S_URL` set, the script installs an agent: `k3s-agent-uninstall.sh` and a `k3s-agent.service`, and `K3S_URL="${CLUSTER_URL}" nohup k3s agent` starts it as the service would, `K3S_TOKEN` coming from the environment (k3s).
- A restarted k3s server needs a wait before the API answers (`kubectl get --raw /readyz`), and `k3s secrets-encrypt status` answers `Internal error` a little longer: the containers keep running while the server is down,
  `ps` shows `nginx: master process` (k3s).
- `disable: [traefik, servicelb]` in `/etc/rancher/k3s/config.yaml` removes the chart through a `helm-delete-traefik` Job, the `traefik.yaml` manifest, and the Pods, and leaves the `Completed` Pods of the install Jobs (k3s).
- `config.yaml.d/*.yaml` is read after `config.yaml`, so the hardening is a second file and the first stays as it is (k3s).
- `wget` hides the body of an error status unless `--content-on-error` is given: the 404 of Traefik with no route prints `404 page not found` only with it (k3s).
- kube-bench with the profile `k3s-cis-1.9` (the newest k3s profile of v0.16.0, in the release archive next to the binary,
  checked with `kube-bench_<version>_checksums.txt`) reads the flags of the API server with `journalctl -m -u k3s | grep 'Running kube-apiserver'`, and filters roles with `jq`: with no journal and no `jq`,
  the result of the lab was 25 failures whatever the options, and with a stand-in `journalctl` that prints `/var/log/k3s.log` and `jq` from `apt-get`, 4 before the hardening and 2 after, 55 passes and 64 (k3s).
- The guide of k3s sets `protect-kernel-defaults`, `secrets-encryption`, an audit log, a Pod Security configuration and the kubelet timeouts in one block of `config.yaml`,
  `chmod 600` on the certificates (check 1.1.20) and a patch of the default service accounts (check 5.1.5) by hand: a Secret is then stored as `k8s:enc:aescbc:v1:` in `state.db`,
  a privileged Pod answers `violates PodSecurity "baseline:latest"`, and `k3s secrets-encrypt status` answers `Internal error` for a few seconds after a restart (k3s).
- The Pod Security configuration of the guide enforces `restricted`, which a plain `nginx` Pod violates (the lab prints the warning `would violate PodSecurity "restricted:latest"`): the lab enforces `baseline`,
  keeps `restricted` for audit and warnings, and says so (k3s).
- `k3s-uninstall.sh` and `k3s-agent-uninstall.sh` leave `/etc/rancher/node`, and a machine with no init system keeps `<defunct>` entries for the processes they kill, so the check looks at `/etc/rancher/k3s`,
  `/var/lib/rancher/k3s` and the running processes (`ps -eo stat=,args= | grep -v '^Z'`) (k3s).
- k3s writes the token of the cluster as `K10<hash of the CA>::server:<secret>` in `server/token` even when the token given is a short one (`K3S_TOKEN`), and the agent warns that it cannot check the CA (k3s).
- The Kubernetes network policy controller of k3s logs `Extension NFLOG revision 0 not supported` with the guest kernel of sidelab and keeps working for the lab (k3s).
- A talk about a platform is dated from several sources:
  Rancher announced k3s in February 2019 (26 February by one source, a day apart in another), the CNCF page gives 19 August 2020 for the sandbox, SUSE's own page says June 2020 for the donation,
  and SUSE completed the acquisition of Rancher Labs on 1 December 2020 (k3s).
- The k3s documentation says an SQLite cluster is converted to embedded etcd by restarting its server with `--cluster-init`, and the README says k3s removes only the in-tree storage drivers and cloud provider,
  with well under 1000 lines of patches: both were first written from memory in the slides, and one was wrong (k3s).
- The courses of this series with a terminal and no web UI need no Playwright probe, as for docker (k3s).
- k3d needs only Docker, and `kubectl` is a binary of its own: `dl.k8s.io/release/<version>/bin/linux/amd64/kubectl` comes with a `.sha256` file that holds the hash alone,
  so the check is `echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check` (k3d).
- The `checksums.txt` of a k3d release names its files `_dist/k3d-linux-amd64`, so `grep " _dist/k3d-linux-amd64$" checksums.txt | sed "s# _dist/# #" | sha256sum --check` checks the download (k3d).
- k3d reads `K3D_*` environment variables as options of its own, so the course names its variables `K3DCLI_VERSION` and `K3DCLI_URL`, and `k3d version` prints the k3s version k3d uses when none is given (v1.35.5-k3s1 for k3d v5.9.0),
  so the course pins the image of the nodes, `rancher/k3s:v1.36.5-k3s1`, where the tag writes the `+` of the k3s version as a `-` (k3d).
- A k3d cluster of one server is ready in 15 to 25 seconds in the lab machine once the images are pulled, an idle server uses about 750 MiB and its load balancer 6 to 20 MiB,
  and the node containers run privileged (`HostConfig.Privileged` is `true`) (k3d).
- The load balancer of k3d is an nginx in `stream` mode, `/etc/nginx/nginx.conf` lists one `upstream` per port with the server nodes only, and `docker port k3d-dev-serverlb` shows the published ports:
  `--port "8080:80@loadbalancer"` is enough for an Ingress to answer on the machine (k3d).
- A second `LoadBalancer` Service on the port 80 got an address when it was created seconds after the cluster, before the ServiceLB Pod of Traefik held the port, and a Pod `Pending` with "didn't have free ports" later:
  the result depends on the order, so the course uses the port 8000 and quotes the documentation of k3s for the rest (k3d).
- The external address of a `LoadBalancer` Service is the one of the node container, which answers from a Linux machine, and the Docker documentation says the `bridge` network is not reachable from the host on Docker Desktop,
  so the portable way is `k3d cluster edit <cluster> --port-add "8081:8000@loadbalancer"`, which replaces the load balancer container (k3d).
- `host.k3d.internal` is the gateway of the Docker network and is added to the DNS of the cluster, and CoreDNS answered it only a few minutes after the creation in one probe,
  so the step waits with `kubectl exec <pod> -- nslookup host.k3d.internal.`,
  the final dot being what makes busybox `nslookup` skip the search domains (k3d).
- The folder of a `local-path` volume is in the node container, on its Docker volume at `/var/lib/rancher/k3s`, and the volume of the PV is tied to that node by `nodeAffinity`:
  it survives a deleted Pod and a stop, and `k3d cluster delete` removes the volumes (`volumes left: 0`),
  where `--volume "${HOME}/lab/storage/keep:/var/lib/rancher/k3s/storage@all"` leaves the files on the machine (k3d).
- `k3d cluster stop` runs `kubectl drain "$HOSTNAME" --force --delete-emptydir-data --ignore-daemonsets --disable-eviction` in the entrypoint of each server (`/bin/k3d-entrypoint.sh`), which deletes the Pods that no controller owns:
  a bare Pod on the server was gone after the restart, and it survived in a probe only because the scheduler had put it on an agent, which is not drained.
  A step that stops a cluster uses a Deployment (k3d).
- A probe on the host kernel passed what the lab machine failed, since the placement of a Pod differed, so the machine of `course verify` is the test,
  and a temporary course in the repository that prints the state (`--show-output`) finds the cause (k3d).
- `k3d registry create registry.localhost --port 5000` starts the container `k3d-registry.localhost` from `registry:2`, the machine pushes to `127.0.0.1:5000`, which Docker accepts without TLS, a manifest uses `k3d-registry.localhost:5000`,
  `--registry-use` writes `/etc/rancher/k3s/registries.yaml` in the nodes and the name in CoreDNS, and `k3d registry delete` prints nothing, so the check counts the containers left (k3d).
- `k3d image import` of an image built on the machine works, and with Docker 29 an image that was pulled, `busybox:1.37`, ends with `ERRO ... failed to import images in node` followed by `ctr: content digest sha256:...: not found`,
  then "Successfully imported image(s)":
  the check names `content digest`, since the words `not found` are on the second line and also in the command (k3d).
- An image imported under a new name after a Pod pulled the same content from the registry stayed in `ErrImageNeverPull` with a pull policy of `Never`, although `crictl images` lists it, and an image with new content imports and runs,
  so the step imports a second build (k3d).
- The k3d documentation page has a footer of 2020-2023 and its install example pins v5.0.0, so the version, the date (2 June 2026) and the assets come from the release page, and the licence (MIT) from the repository;
  kind and minikube are quoted with their own sentences (k3d).
- The two first runs of this course went past ten minutes, which the tool that runs the command moves to the background, because blocks failed on their timeouts of 300 seconds and the next ones waited behind them:
  a run that is much longer than the previous courses (k3s, 67 blocks and two machines, about three minutes) is a loop waiting for something that never happens, so the first failure is read before anything is rerun (k3d).
- A course on a command line tool in Docker, with no web UI, needs no Playwright probe, as for docker (k3d).
- A cluster cannot be probed in a privileged lab-image container with Docker inside: k3s stops with `failed to find memory cgroup (v2)`, and `k3d cluster create` then waits until the tool moves it to the background,
  so the machine of `course verify` is the only test, and it is used from the first draft: a course written in stages, run each time with `--show-output` and `timeout 540`, was green in four runs of about three minutes (ingress-controller).
- `*.example.test` names, with one line in `/etc/hosts` of the machine, give the course real names, real TLS verification and no `Host` header typed by hand, and `.test` is reserved for tests so no DNS ever knows it (ingress-controller).
- k3s installs Traefik v3, its CRDs and the Gateway API definitions (v1.6.1 with k3s v1.36.5) with the chart, so `kubectl apply --server-side` of the release's `standard-install.yaml` fails with a conflict with `helm`:
  the course reads the `bundle-version` annotation of the CRD instead (ingress-controller).
- With the `HelmChartConfig` `traefik` setting `providers.kubernetesGateway.enabled: true`, the `GatewayClass` `traefik` (controller `traefik.io/gateway-controller`) appears within a minute,
  and a `Gateway` listener uses the port of the entry point in the Pod,
  8000 for `web` and 8443 for `websecure`, not 80 and 443 (ingress-controller).
- An Ingress with a `tls` section answers plain HTTP too in Traefik, and wins against a redirect Ingress on the same host:
  `traefik.ingress.kubernetes.io/router.entrypoints: websecure` on the first, `web` and a `redirectScheme` middleware on the second (ingress-controller).
- Traefik answers `404 page not found` for a host no rule has, and `wget` exits with 8 and hides the body unless `--content-on-error` is given, so the block is `{ wget --content-on-error ... || true; }` (ingress-controller).
- The linter refuses an `expect` text that is in the command, so a count is printed by `echo "answering Pods: $(...)"` and checked as `answering Pods: 3`:
  the command holds the label and the substitution, never the value (ingress-controller).
- A `for` loop that waits for an apply to succeed hides the `created` lines of the successful attempt when its output is discarded, so the block ends with a `kubectl get` and its column header is the check (`READY`) (ingress-controller).
- cert-manager v1.21.2 installs with `kubectl apply --server-side -f cert-manager.yaml` in about 15 seconds, a `selfSigned` ClusterIssuer signs a `Certificate` with `isCA: true`, a `ca` ClusterIssuer built on its Secret signs the rest,
  and the `cert-manager.io/cluster-issuer` annotation on an Ingress gives a Secret with `tls.crt`, `tls.key` and `ca.crt` in a few seconds, valid 90 days with `status.renewalTime` 30 days before the end (ingress-controller).
- Traefik serves a certificate named `TRAEFIK DEFAULT CERT` for a name it holds no certificate for, which `openssl s_client -servername` shows, and `wget` fails with status 5 on a certificate nobody signed (ingress-controller).
- `ingress-nginx` was retired in March 2026 (announced 11 November 2025), so the course teaches the controller k3s ships and the Gateway API, and the slides date the retirement from the Kubernetes blog (ingress-controller).
- A course on exposure names the tools that publish a local cluster, ngrok and cloudflared, in the slides only, with what their own pages state, since both need an account the lab has not (ingress-controller).
- The course on a topic with a web UI of its own would need a Playwright probe: this one has none, the controller has no UI in the lab, so it needs none, as for docker (ingress-controller).
- A GitOps course teaches the loop before the tools: Gitea as the Git server and a reconciliation script of a dozen lines, read by the learner, so Argo CD and Flux, in the next courses, are that loop with more care (gitops).
- `adduser --system --group --disabled-password` and `runuser -u git --` run Gitea as a user that is not `root`, which it refuses to be, from a folder that user can read:
  `runuser` keeps the current folder, `/root/lab` made Gitea exit at once with no message in the terminal, and a probe from `/tmp` in a container missed it, so the `cd` is its own line (gitops).
- Gitea writes its secrets into `app.ini` at the first start, so the file is `root:git` with mode 660 (the documentation says 770 for `/etc/gitea` during the installation), and `INSTALL_LOCK = true` skips the web installer,
  after which `gitea admin user create` makes the administrator (gitops).
- Gitea's signing key is checked with `gpg --show-keys --with-colons | grep -q "fpr:::::::::<fingerprint>:"` after downloading it from `keys.openpgp.org/vks/v1/by-fingerprint/<fingerprint>`, then `gpg --verify` of the `.asc`,
  which prints "Good signature" and a warning that the key is not certified (gitops).
- Gitea's `/api/v1/repos/<owner>/<repo>/commits` answered `409` right after the first push to a repository created empty, so a step asks the server with `git ls-remote origin` (gitops).
- `git config credential.helper store` saves the credentials of any URL that worked, so a clone with `http://user:<token>@host/...` replaced the account of the lab and the next push answered `403`:
  the reconciler runs `git -c credential.helper=` (gitops).
- A Gitea token is made with `POST /api/v1/users/<user>/tokens` and `{"name":..., "scopes":["read:repository"]}`, the answer carries it as `sha1`, it reads (`200`) and cannot write (`403`),
  which shows the least privilege of a pull reconciler (gitops).
- `kubectl apply -k <folder> --prune --selector <label>` without `--prune-allowlist` warns that pruning of non namespaced resources is deprecated:
  the Kubernetes documentation calls allowlist pruning alpha and strongly encourages the allowlist and a selector,
  so the loop lists `core/v1/Service`, `core/v1/ConfigMap` and `apps/v1/Deployment`, and a Namespace is never pruned (gitops).
- A deployment is read in a loop that ends with the value it waited for (`for ...; do [ "$(...)" = 2 ] && break; sleep 2; done; echo "replicas in the cluster: $(...)"`),
  and the reconciler of a step runs with `nohup bash -c 'while true; ...'` and stops with `pkill -f "^bash -c while true"` (gitops).
- The linter refused `expect="new branch"`, `Remove the password` and `cluster-admin`, all in the command: a check names `shop-v2 -> shop-v2` (what `git push` prints),
  `commits: 2` (a count) and `yes` (what `kubectl auth can-i` prints) (gitops).
- The talks of the author were the outline (push and pull, principles, environment strategies, secrets, tools, the levels of a journey), and the official pages checked each date:
  Argo CD joined the CNCF on 26 March 2020 and graduated on 6 December 2022,
  Flux was accepted on 15 July 2019 and graduated on 30 November 2022, and the origin of the word GitOps is credited to Weaveworks by the press only, so the slide says so (gitops).
- The pages of Argo CD, Flux and Fleet do not use the words "pull model", so the slides say what each page states, and the pull is the lab's demonstration (gitops).
- The course on GitOps has no UI in the lab: Gitea runs in the machine, which the editor and the browser panels do not reach, so everything is the terminal and the API, and no Playwright probe is needed, as for docker (gitops).
- A course for newcomers to a tool that every cloud native project uses starts with the use, then the creation: the same four commands (`repo add`, `search repo`, `install`, `upgrade`) on a public chart,
  then a chart from two plain manifests,
  then the quality, then the publication, and the reasons come first in the slides (helm).
- A chart is a recipe, not an image: it runs with the rights of the user and can create roles and hooks, so the first step reads a chart before installing it (`helm template | grep '^kind:'`, `helm pull --untar` and a search for
  `helm.sh/hook`),
  and the summary treats the chart and its images as two parts of the supply chain (helm).
- Helm 4.3.0 is a single archive checked with the `.sha256sum` file of its release, and `helm install --wait` is stricter than the Pod status: an upgrade to a missing image tag with `--rollback-on-failure --timeout 45s` fails with
  `UPGRADE FAILED: ... has been rolled back`, `helm history` lists revision 3 as `failed` and revision 4 as `deployed` with `Rollback to 2`, and the Pod of the good revision kept answering (helm).
- `helm rollback web 1` is revision 3 with the content of revision 1, so `helm get values` prints `null` when the first revision had no value, and the Secrets `sh.helm.release.v1.web.v1` to `v3` are all kept (helm).
- `helm test <release> --logs` prints `Phase:          Succeeded` with several spaces, so a check names `Succeeded`, and a chart test is a Pod with `helm.sh/hook: test` and the policy `before-hook-creation,hook-succeeded` (helm).
- `values.schema.json` makes `helm template --set replicaCount=0` fail with `values don't meet the specifications of the schema(s)`, before any cluster is involved (helm).
- kube-linter 0.8.3 finds four things in a plain Deployment, `no-read-only-root-fs`, `run-as-non-root`, `unset-cpu-requirements` and `unset-memory-requirements`, and none once the chart has a security context and resources;
  its release has no checksum file, so the SHA-256 of the archive is a variable (helm).
- `traefik/whoami` runs as a user that is not root with `readOnlyRootFilesystem` on a port above 1024 set with `WHOAMI_PORT_NUMBER` (helm).
- A chart repository is a folder of archives and the output of `helm repo index <folder> --url <url>`, served by `python3 -m http.server`, and a new version is `helm package`, then `helm repo index --merge <folder>/index.yaml`,
  then `helm repo update` (helm).
- `helm push <archive> oci://127.0.0.1:5000/charts --plain-http` against `registry:3` printed `Digest: sha256:...`, and `helm show chart oci://... --version <v> --plain-http` reads it back (helm).
- GitHub hosting is `helm/chart-releaser-action` (releases per chart version, `index.yaml` on the branch `gh-pages`, Pages served from that branch), and the checks are `helm/chart-testing-action` with `ct list-changed`, `ct lint`,
  and `ct install` in a `helm/kind-action` cluster: the workflows are written by the course as files with their actions pinned to full commits, and only checked offline, since a workflow runs on GitHub (helm).
- The terminal of `course verify` does not print the blank lines of a heredoc echoed by `tee`, and a count taken in the block (`ls | wc -l`) was wrong twice in the first draft (the folder `templates` is an entry of `ls`, `- main` is an item
  of a list like the steps),
  so a count names the pattern it counts, `grep -c '^      - \(uses\|name\)'` (helm).
- The first run of a course written in one go had seven failing blocks of 70, all from the checks and none from the commands, and the third was green in about four minutes (helm).
- The course on Helm has no UI in the lab, so it needs no Playwright probe, as for docker (helm).
- A course whose steps need a web UI and a command line that talk to a server in a `runtime: vm` host publishes that server with a k3d port mapping and a NodePort, never with `kubectl port-forward`:
  the command ends at the first connection the server resets (`lost connection to pod`), every later call is refused, and a restart loop loses the race against the next block.
  `k3d cluster create --port "<host>:<nodeport>@loadbalancer"` at creation, then a `NodePort` Service, gives `http://docker:<host>` to the browser panel and `127.0.0.1:<host>` to the machine (argocd).
- The `control` host reaches a service of the machine by the host name (`wget http://docker:8080/...`), which a block with no `target` checks, so the browser panel is known to work before the learner opens it (argocd).
- A hard failure of a long course is read from the log, not waited for: `course verify --show-output` of a 99 block course with two clusters ran in 6 minutes, and `grep -n "✗"` finds the first failure at once (argocd).
- Argo CD answers an empty `Sync Status:` for a second or two after an Application is created, so a wait loop ends on a value (`grep -q "^Sync Status: *[A-Z]"`), and a name already in the command cannot be the `expect` (argocd).
- Argo CD sees a new commit within 3 minutes, so a block that waits for a change in Git calls `argocd app get <app> --refresh` inside its loop, and so does the block that turns `prune` on:
  a change of policy is seen at the next look at the repository (argocd).
- Argo CD, started with `server.insecure: "true"`, accepts `argocd login --plaintext` through a NodePort, and not through `kubectl port-forward`, which dies on the reset (argocd).
- The Argo CD health of an `Application` is not assessed since v1.8: the waves of an app of apps create everything at once, and only the Lua of `resource.customizations.health.argoproj.io_Application` in `argocd-cm` makes a wave wait,
  with `Message: waiting for healthy state of argoproj.io/Application/<name>` in the sync of the root (argocd).
- A sync that waits is tied to the commit it started with: after the fix is pushed, `argocd app terminate-op <root>` then a new sync reads the fixed layers (argocd).
- A CRD-only Application stays `Progressing` until a hard refresh, and a CRD with its custom resource in one Application syncs fine, so the order of layers is shown with a Deployment and a broken path, not with a CRD (argocd).
- An `argocd cluster add` takes the server address from the kubeconfig, a port of the machine that a Pod does not reach, and the second k3d cluster joins the Docker network of the first (`--network k3d-hub`),
  so the cluster Secret names `https://k3d-<name>-server-0:6443`;
  the Secret is written by hand, and by Terraform in the next step, with a ServiceAccount token Secret (argocd).
- `--kubeconfig-switch-context=false` on every second cluster keeps `kubectl` on the hub, and every command names its `--context` (argocd).
- A `kubernetes_manifest` of an Argo CD `Application` fails at the plan before Argo CD exists, so Terraform installs the chart `argocd-apps` after the chart `argo-cd`, with `depends_on` (argocd).
- Environment variables named `ARGOCD_*` are read by the `argocd` command line, so the variables of the course are `ARGOCDREL_*`, `ARGOCDCHART_*`, `UI_PORT` (argocd).
- A docker run that mounts a scratch folder creates it as root: a file written with the editor tool then fails with `EACCES`, so the folder is made first,
  and a removal inside a `bash -c` of a container is refused by the permission check (argocd).
- Quick facts of the roster of a project are counted with a script from its own file, with the date: 42 people with a role on Argo CD, 16 organizations, read on 13 October 2026 (argocd).
- The course on Argo CD has a web UI, probed with Playwright against a k3d cluster of the host (Docker is there, the lab image runs Chrome with `--network host`):
  the button texts are `Sync` and `Synchronize` in the DOM, upper-cased by CSS, so a locator uses `hasText: /^\s*Sync\s*$/i` (argocd).
- A course with a web UI has an `automation.yaml`, with one page for the application, `goto` with a literal URL for each screen (the route of a single page application is reachable at once), and one `:action:` link per thing worth showing:
  the login (the password comes from `env:` as `${UI_ADMIN_PASSWORD}`, set by a step with `argocd account update-password`), the list, an application, its diff, a sync, a node of the tree and its logs, the history, the settings (argocd).
- The selectors of Argo CD v3.5.5: the DOM text is `Sync`, `Diff`, `History and rollback` in `span` elements and CSS upper-cases them,
  so a locator is `button:has(span:text-is("Sync"))`, the sync panel's button is `button[qe-id="application-sync-panel-button-synchronize"]`,
  a node of the tree is `.application-resource-tree__node:has(.application-resource-tree__node-kind:text-is("deploy"))`, and the tabs of its panel are `a` elements of `.tabs__nav` (`.tabs__nav a:has-text("Logs")`) (argocd).
- The **Diff** button of an application is disabled while it is `Synced`, so an action that clicks it runs when the application is `OutOfSync`, as in the step that shows the difference (argocd).
- A runner of a dozen lines that applies an `automation.yaml` with Playwright, in the lab image with `--network host` against a k3d cluster of the host (`k3d cluster create --port "18095:30095@loadbalancer"`, a NodePort Service),
  checks every action before a run of the lab,
  and `course record` runs them in the real lab, which the permission check of the agent did not let it start through a wrapper around the launcher script (argocd).
- The history of an application in the interface has one card per sync: when, how long, who started it (a person or `automated sync policy`), the commit and its author, and a GPG signature column (argocd).
- Argo CD refuses a team Application for a namespace the project does not list with the condition `application destination server '...' and namespace '...' do not match any of the allowed destinations in project '<name>'`,
  and still creates the Application (argocd).
- An account is `accounts.<name>: login` in `argocd-cm`, its password is set by `argocd account update-password --account <name>` with the password of `admin` as `--current-password`,
  and a role in `argocd-rbac-cm` (`policy.csv`) maps it to one project;
  `argocd --config <file> login` keeps its session apart from the one of `admin` (argocd).
- An Application whose manifests include a `SealedSecret` fails on a cluster that has not the controller, so the application of the second cluster is the one without secrets, and a cluster gets its platform before its applications (argocd).
- Sealed Secrets chart 2.20.0 installs by Argo CD from `https://bitnami.github.io/sealed-secrets` with `fullnameOverride: sealed-secrets-controller`, `kubeseal` 0.40.0 is checked against `sealed-secrets_0.40.0_checksums.txt`,
  and `helm list` has no release for it, since Argo CD renders the chart with `helm template` (argocd).
- A course can have several slide steps between lab steps (the design of many clusters comes before the lab of two clusters), each a `display: slides` step of several slides (argocd).
- A course that explains a tool without running it still shows code that was run: the Terraform of the registration was applied against two k3d clusters (four resources added), and the Helm provider file was validated (argocd).
- A full run of the lab with eleven steps, two clusters and 109 blocks took 5 minutes 30 seconds, and a first run with a failing wait took 9 minutes 36, just under the limit of a foreground command,
  so a failing wait is read from the log and fixed before another run (argocd).
- The courses of this series with a terminal and no web UI need no Playwright probe, as for docker (flux).
- A cluster can be tried before writing a step on the host: its Docker runs `k3d`, so a command is checked in seconds there, where a run of `course verify` costs about ten minutes:
  the first drafts of this course were written and fixed against the lab machine only, which took a day, and the lab is then the confirmation, not the place to find the command (flux).
- A course whose blocks wait for clusters, about 15 minutes in all, does not fit the ten minutes of a foreground command:
  it is verified in overlapping parts, a temporary copy in the repository with the steps that part needs (the folders are copied, the sections it does not need are cut),
  and each block is green in at least one part.
  The bootstrap of a cluster takes about 120 seconds, the pull of four controller images, and is run twice by this course (flux).
- `flux bootstrap git` over HTTP needs `--token-auth` (the token goes in `--password`), `--allow-insecure-http` for a server with no TLS and `--silent`, and the URL it commits into `gotk-sync.yaml` is the one the cluster reaches,
  so `host.k3d.internal` is mapped to `127.0.0.1` in `/etc/hosts` of the machine and the same name works from a Pod and from the command line (flux).
- A Gitea token made with `POST /api/v1/users/<user>/tokens` and the scope `write:repository` is enough for the bootstrap and for the reads that follow, and `flux` stores it in the Secret `flux-system` (`username`, `password`) (flux).
- A bootstrap pushes two commits made by `Flux` (the component manifests, then the sync manifests), so a clone made before it is behind, and `git pull --rebase` brings it back (flux).
- `flux reconcile kustomization <name> --with-source` waits for the object to be ready, so a broken or blocked layer holds the command for its whole `--timeout` (5 minutes): the blocks that expect a failure use `--timeout 20s` (flux).
- The `--timeout` of `flux create kustomization` is the time the command waits and not the field `spec.timeout`, which `--wait` sets to 2 minutes: the file is edited with `sed` to bound a health check at 40 seconds (flux).
- A `Kustomization` fails with a message on several lines when a dry run is refused, so `flux get ... | tail -1` shows an empty line and a check reads `.status.conditions[?(@.type=="Ready")].message` with `tr '\n' ' '` (flux).
- Flux applies a set after a server side dry run of all of it, so one refused object (a `ClusterRole` of a tenant) stops the others: the Deployment of the same folder was not created (flux).
- The Helm release of a `HelmRelease` with a `targetNamespace` is named `<targetNamespace>-<name>` and its Secrets are in the namespace of the `HelmRelease` object, so the course sets `releaseName` and looks in `flux-system` (flux).
- A `HelmRelease` is not corrected after `kubectl scale`, and is with `driftDetection: mode: enabled`, which the next reconciliation applies (flux).
- A `Kustomization` of another namespace than its source needs the namespace in the reference, `--source GitRepository/flux-system.flux-system`, or it fails with "GitRepository ... not found" (flux).
- `flux create tenant <name> --with-namespace <ns> --cluster-role admin --export` writes a namespace, a ServiceAccount and a RoleBinding, and the `Kustomization` of the tenant names `serviceAccountName`:
  a `ClusterRole` in its folder answers `dry-run failed (Forbidden): ... User "system:serviceaccount:team-a:team-a" cannot patch resource "clusterroles"` (flux).
- A SOPS file applied by a `Kustomization` with no `decryption` is refused by Flux with `Secret/shop/shop-db is SOPS encrypted, configuring decryption is required for this secret to be reconciled`,
  which the course shows before the fix (flux).
- `sops` indents the file it writes by 4 spaces whatever the input, so a `grep` of a key of an encrypted file allows any indentation, and `sops updatekeys --yes` adds a recipient from `.sops.yaml` without changing the values (flux).
- age is a Debian 12 package (`age-keygen`), which `apt` checks, where its releases have no checksum file, and SOPS publishes `sops-<version>.checksums.txt` (flux).
- Background of the project is dated from several pages: 15 July 2019, 12 March 2021 and 30 November 2022 from the CNCF page, the v1 repository archived and v2.0.0 on 5 July 2023 from GitHub,
  the closure of Weaveworks on 5 February 2024 from the press, and a maintainer roster of 9 read from `CORE-MAINTAINERS` of `fluxcd/community` with the date (flux).
- The Flux page on secrets management is the outline of a secrets slide: SOPS, decryption operators, external stores and CSI drivers, with the limits it states (flux).
- The Terraform provider of Flux was validated, and planned, in the lab image with no cluster (`terraform init`, `validate`, `plan`), and the examples of the author came from `../wiz-playground/terraform` (flux).
- A `<!-- include -->` fragment shared by two courses replaces a block that was inline in the first one: `labs/shared/setup-gitea-clusters.md` came from the Argo CD setup, whose steps are unchanged (flux).
- A course that mentions an integration, here Terraform and Flux, has a diagram of it, one per integration and not one per course: the first draft had three diagrams and none of the Terraform chain,
  which the slides described only in text (flux).
- The repositories the author points to at the start (here `../devpro-kubernetes-gitops` and `../fallstar`) are read for the layout of their files before the first step is written, not after:
  the `HelmRepository` file per repository, the `helmrelease.yaml` per folder, `releaseName`, `targetNamespace`, `createNamespace` and `sourceRef.namespace`
  were rewritten into the Helm step after a first version that did not follow them (flux).
- A course on a management layer is built as an architect would judge it: the problem, the value, how it works, the project and who decides, the editions, the capabilities and integrations in slides,
  then install, the layer's own resources, a cluster of another machine, access, GitOps, Cluster API and a detach in the lab, and getting started, lock-in and the alternatives at the end (rancher).
- The Instruqt tracks of the author (`learning-platform/archive/instruqt/tracks`, `rancher-keycloak`, `cloud-native-devops`) and the scripts of `../infrastructure-provisioning/scripts/rancher` gave the outline
  and the API calls (login, password, `server-url`),
  and the recipe of `../fallstar` the chart values, each checked again against Rancher v2.15.2 (rancher).
- `helm template` has no cluster to ask, and Helm 4.3 then assumes Kubernetes v1.37, which the Rancher chart refuses with `chart requires kubeVersion: < 1.37.0-0`: the step passes `--kube-version "${KUBECTL_VERSION}"` (rancher).
- Rancher v2.15.2 installs, after its own Deployment, Fleet, its webhook, the system upgrade controller, Rancher Turtles 0.27.2 and the core of Cluster API v1.13.3 as Helm releases of its own,
  about three minutes after the chart in the lab machine,
  so the install step waits for the four Deployments `1/1`, and an import declared before them took 204 seconds to be ready instead of 42 on a host probe (rancher).
- With `bootstrapPassword` set, the first login asks for the password only, and the next page for the server URL and the terms, even after `server-url` was patched; the later logins ask for the user too,
  so `automation.yaml` signs in once, in the install step, and the session of Chrome holds for the next steps (rancher).
- The certificate authority of Rancher is generated by Rancher (10 years), kept in the Secret `tls-rancher`, used by a cert-manager `Issuer` to sign the 90-day certificate of the hostname,
  served at `/cacerts`, and its SHA-256 is the `CATTLE_CA_CHECKSUM` of the import manifest: the course trusts it with `wget --ca-certificate`, never with `--no-check-certificate` past the first download (rancher).
- Chrome of the `vnc` panel stops at **Your connection is not private** for a certificate of a private authority, and a `goto` of the automation engine fails on that page with `ERR_CERT_AUTHORITY_INVALID`,
  so the `:navigate:` link opens it and an action with no `goto` clicks `#details-button` then `#proceed-link`; Chrome then keeps the exception for the session, and the later `goto` work (rancher).
- Rancher 2.15 keeps the registration token of a cluster in a Secret (`crt-token-default-token`), the `status` of the `ClusterRegistrationToken` shows `{token}`,
  and the API `/v3/clusterregistrationtokens?clusterId=<id>` gives the whole command to a signed-in user:
  the platform team declares the cluster with `kubectl`, and the administrator of the other machine reads the command with the API (rancher).
- A provisioning `Cluster` with `spec: {}` in `fleet-default` is a cluster to import, and the manifest of `/v3/import/<token>_<id>.yaml` applied in the other cluster made it ready in 42 seconds on a host probe,
  and Rancher then redeploys its agent and installs `fleet-agent` and the system upgrade controller (rancher).
- A Pod of a k3s cluster resolves through CoreDNS, which forwards to `1.1.1.1` in the lab machines and does not know their `/etc/hosts`: a `rancher.server` key of the ConfigMap `coredns-custom` with a `hosts` block gives the name,
  and CoreDNS is restarted, since it mounts that ConfigMap as an optional volume that stays empty in a Pod started before it existed (rancher).
- `kubectl auth whoami` through the kubeconfig of Rancher (`/k8s/clusters/<id>`) prints the user of Rancher with `principalid`, `requesthost` and `requesttokenid`, which shows the authentication proxy and impersonation in one command,
  and `cattle-impersonation-system` of the cluster holds one service account per user (rancher).
- A user of Rancher, its global role binding and a `ProjectRoleTemplateBinding` of `project-member` give `yes` to `auth can-i create deployments` in the namespace of the project and `no` elsewhere, checked by the RBAC of the cluster itself,
  and a namespace joins a project with the annotation `field.cattle.io/projectId: <cluster id>:<project>` (rancher).
- A label of the management cluster (`clusters.management.cattle.io`) reached the cluster of Fleet in seconds, and the same label on the provisioning `Cluster` did not in five minutes:
  the targets of a `GitRepo` select the first (rancher).
- The multi-cluster example of `rancher/fleet-examples`, pinned to a commit, shows targeting with one relabel: `env=dev` deploys the frontend and the Redis leader, `env=test` three frontends and two followers,
  in seconds once the images are there (rancher).
- Deleting an imported cluster from Rancher removed its `cattle-*` namespaces in about 80 seconds and left the workloads, the ones of Fleet and of the team, and a namespace `local`: the detach is the proof of the lock-in slide (rancher).
- The first page of the Extensions of the community edition is empty until **Add repositories** enables the partner repository,
  and the Rancher chart repository of v2.15.2 lists Longhorn, NeuVector, Rancher Backups, Rancher Compliance, Logging, Elemental and Rancher Turtles,
  so a slide names what the lab saw (rancher).
- The documentation site of Rancher truncates in the fetch tool, and `git clone --depth 1 --filter=blob:none --sparse https://github.com/rancher/rancher-docs` with `docs` gives the pages to read,
  `rancher-is-no-longer-needed.md` and the architecture among them (rancher).
- Vendor comparisons quote each page with its date: Red Hat ACM 2.16 has a hub on OpenShift only and lists and imports EKS, AKS, GKE and conformant clusters without creating or upgrading them,
  Tanzu Mission Control SaaS ended on 15 November 2025,
  and a vendor page that failed to load (Google fleets) is left out rather than described from memory (rancher).
- A course whose blocks wait for Rancher, about 15 minutes in all with two machines (76 blocks, green in the full run of the author), does not fit the ten minutes of a foreground command: it is verified in overlapping parts (setup and install, then up to Fleet without the long wait),
  and the full run is started by the author in a terminal of their own (rancher).
- `k3d cluster create` stopped once at `Starting node` for the whole timeout, in a run where the other runs took 25 to 30 seconds: a run that fails on a step that passed before is run again once before the course is changed (rancher).
- The courses of this series with a web UI have a Playwright runner of a dozen lines that replays `automation.yaml` in the lab image against a host cluster,
  as for argocd: all fifteen actions of Rancher passed before the first run of the lab (rancher).
- The first draft installed cert-manager with `kubectl apply` of its release manifest, copied from the ingress-controller course, while the examples of the author (the Instruqt track `rancher-keycloak`,
  `k8s_install_certmanager` of `../infrastructure-provisioning`) installed it with the Helm chart of Jetstack:
  the examples the author points to win over the habit of an earlier course, and a component of a cluster is a chart, as the section [Steps](#steps) says (rancher).
