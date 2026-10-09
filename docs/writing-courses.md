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

- A step with a terminal also has an editor panel when files are created or changed.
- A file is shown with a link, `[Open hello.txt](:open:demo/hello.txt)`, relative to the course `workdir`, never with `cat` or `more`.
- The first block of a step moves to its folder explicitly (`cd ~/lab/demo && ...`).
  `course verify` runs every block in one shell without entering the steps, so a step `workdir:` is not applied there.
- A command that waits for input, a pager or an editor, stalls `course verify` until it times out, and the following blocks fail with it.
  `git commit -m` avoids the editor, `PAGER=less` exits on output shorter than the screen.
- A server the lab starts runs in the background with `nohup ... &`, and the block waits until it answers, with `wget --retry-connrefused`.
  It is stopped with `pkill -f "<command line>"`, not with a pid file.
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
----------|-----------|-------------------
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
- A web app the lab starts is run with `--no-launch-profile --urls`, since `launchSettings.json` holds a developer machine's ports and opens a browser, and `ASPNETCORE_ENVIRONMENT=Development` is set explicitly: it is `Production` otherwise, and the OpenAPI document is not served (dotnet).
- `kill $(cat <file>.pid)` on the `dotnet run` process stops its child too, so a step can free its port itself (dotnet).
- A link such as `:navigate:` is plain markdown, so its port cannot be an `env:` variable: the value is written in the link and kept equal to the variable by hand (dotnet).
- A `verify` directive's `expect` takes a double-quoted text, since single quotes are not parsed (dotnet).
- `$!` of a `nohup ... &` typed in the lab terminal was not the pid of `dotnet run`: `kill $(cat <file>.pid)` left the server running, which then answered the next step on the same port, with the old code, so a step stops its server with `pkill -f` (test-pyramid).
- A script that starts a server, checks it and stops it uses `trap 'kill $pid; wait $pid' EXIT`: without `wait`, the old process still holds the port when the script is run again at once (test-pyramid).
- A test of a bug needs the proof that it fails: the step breaks the code on purpose, expects the failure in a `verify` directive, restores the code, and expects the pass (test-pyramid).
- `dotnet test` of a solution prints `failed: 0, succeeded: 6` in the terminal, with the total of every project, and one `Passed!` line per project without a terminal (test-pyramid).
- Headless Chrome of the lab image needs `--no-sandbox`, since the container does not allow the namespaces of its sandbox, and `--dump-dom` prints the page after its script has run, with `--virtual-time-budget` to let it finish (test-pyramid).
- A test of a course that uses the real clock must hold on every day of the week: the end-to-end check accepts the total of a Friday as well as of other days (test-pyramid).
- `WebApplicationFactory` needs the web SDK in the test project, the `Microsoft.AspNetCore.Mvc.Testing` package at the ASP.NET Core patch version, and a public `Program` class (`public partial class Program;`) (test-pyramid).
- A course that has no instruction in a web UI, only links and a terminal, needs no Playwright probe: the browser of an end-to-end test is Chrome in the terminal (test-pyramid).
- A `verify` directive's `expect` is not expanded: a `${VAR}` in it stays literal, so it names text that does not depend on a variable, and not text that appears in the command, which the terminal echoes (github).
- A course that reads a service it does not own pins what it checks: a tag, a merged pull request or a commit never changes, a branch, a count of issues or the last run does (github).
- The repository of the course itself cannot be a fixture beyond its first commit and its default branch, since what is pushed to it changes, so checks on it are limited to the ones that hold forever (github).
- The GitHub API is read without a token at 60 requests per hour and per IP address, `/rate_limit` is not counted, and a request without a `User-Agent` is refused, which `wget` sends by itself: a course keeps to a few calls per run, and verifies on a shared address can hit the limit (github).
- A pull request is fetched with `git fetch origin pull/<n>/head:<branch>`, and `--depth` bounds the download to the commits of the pull request (github).
- On github.com, an anonymous visitor sees the tabs **Code**, **Issues**, **Pull requests**, **Actions**, **Projects** or **Discussions**, **Security and quality** and **Insights**, according to what the owner enabled, and the filter menus of the **Actions** page answer "Sorry, something went wrong" until signed in, so the instructions only name the buttons (github).
- A course taught with `gh` would need a token, which `course verify` has not, so GitHub is taught with Git, a browser and `wget`, which show what `gh` relies on (github).
- A course about a hosted service, GitHub Actions or GitLab CI, does not log in to it: the concept is taught with what runs in the lab, here a bare repository with a `post-receive` hook as the CI server, and the services appear as a file checked offline and a table of equivalent keys (cicd).
- The pipeline logic lives in a script of the repository, and the hook and the service file only call it, so the course is not tied to one product (cicd).
- A `post-receive` hook cannot refuse a push, and its output comes back to the pusher as `remote:` lines, which a `verify` directive reads like any other output (cicd).
- The lab image's default directory is not writable by `labuser`: a block run from `/` fails with "Permission denied", so every block starts with `cd ~/lab` or its step folder, also when it is tried by hand in `docker run` (cicd).
- A release archive is checked with `sha256sum --check --ignore-missing <name>_checksums.txt`, which skips the other platforms listed in the file (cicd).
- A file with `${{ ... }}`, such as a GitHub Actions workflow, written by an unquoted heredoc that expands `env:` values escapes it as `\${{ ... }}` (cicd).
- A step finds its artifacts with `git rev-parse --short=7 <commit>`, the length the pipeline cuts the commit to, since a bare `--short` can grow with the repository (cicd).
- A course whose instructions are a terminal and an editor, with no web UI, needs no Playwright probe, as for test-pyramid (cicd).
- `NODE_ENV=production` in the lab image makes `npm install --save-dev` print "up to date, audited 1 package" and install nothing, so `npx` then downloads the tool on its own, and a config that imports it fails with `MODULE_NOT_FOUND`: the setup exports `NODE_ENV=development` (playwright).
- npm is not in the image, and its registry tarball unpacks and runs with `bin/npm-cli.js`, since it bundles its dependencies: the setup compares its `sha512` with the `dist.integrity` of the registry metadata (playwright).
- `npx playwright install --only-shell chromium` downloads the headless Chromium only, about 120 MB, where `chromium` alone is more than 400 MB (playwright).
- `npx playwright show-report` listens on `localhost`, which `wget` and a probe reach on `127.0.0.1` only with `--host 127.0.0.1` (playwright).
- `a && b &` puts the whole chain in the background, `cd` included, so a command that starts a server is on a line of its own (playwright).
- A step that fails on purpose is written `{ <command> || true; }`, and its `expect` names a line of the failure, since a non zero exit status fails the block (playwright).
- The tests of a Playwright course are themselves the probe of the app, and the probe of the HTML report and the trace viewer found that the links of the report render late, so a probe waits for the first **View Trace** link before counting them (playwright).
- A `verify` directive checks the count of a run, so adding a test file changes the `expect` of every later step that runs the whole project (playwright).
- npm 12 prints `npm notice run <project> <event>` and `npm notice run <command>` before any command it runs with the terminal attached, `npx` included, from `@npmcli/run-script`: it replaces the `> project@1.0.0 script` banner and only disappears with `--loglevel=warn`, so the course explains the two lines where they first appear instead of hiding them (playwright).
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
- The machine has no init system, so `systemctl` answers "System has not been booted with systemd as init system", and a systemd course writes a unit file and checks it with `systemd-analyze verify`, which needs no running systemd and reports `is not executable` for a missing program (linux).
- bash remembers where it ran a command, so `command -v tree` still prints `/usr/bin/tree` after the package is removed until `hash -r` (linux).
- Debian 12 merged `/bin`, `/sbin` and `/lib` into `/usr`: `dpkg -S /bin/ls` finds `coreutils`, and `dpkg -S /usr/bin/ls` finds nothing (linux).
- As `labuser`, `apt-get update` fails on `/var/lib/apt/lists`, and works with `Dir::State`, `Dir::Cache` and `Debug::NoLocking` set in a file named by `APT_CONFIG`, after which `apt-get download` and `dpkg-deb -x` give a package without root, with one harmless `rm: cannot remove` line from the image's `docker-clean` hook (linux).
- Some pages of the official sources, the Red Hat blog and the freedesktop.org manuals, refuse the fetch tool (404 or 403): a claim taken from a search excerpt of such a page is worded as the excerpt says, with the page linked in the slide (linux).
- Dates and versions in slides, Debian and Ubuntu releases, the lifecycle of RHEL and SLES, age quickly: each is stated with its date and checked again when the course is revisited (linux).
