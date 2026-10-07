# Writing courses

How a course of this repository is researched, written and tested.
The sidelab reference is its `docs/courses.md`, this page only holds the choices made here and the lessons learned.

## Principles

- One topic per course, its key elements only, in about 10 minutes of video and 20 minutes of lab.
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
It carries node, npm, wget, python3 and dpkg-deb, and no curl, git, less, editor or unzip.

- A Debian package is unpacked with `dpkg-deb -x <file>.deb ~/.local/`, rather than installed with `apt`.
- A zip is expanded with `python3 -m zipfile -e`.
- Debian's own programs call `pager`, which is `more` in the image, so `PAGER=less` is exported once `less` is unpacked.

The terminal is reset when moving to another step, so every `export` is also appended to `~/.bashrc`:

```bash
export PATH="$HOME/.local/usr/bin:$PATH" && \
echo 'export PATH="$HOME/.local/usr/bin:$PATH"' >> ~/.bashrc
```

Checking what the image carries, before depending on it:

```bash
docker run --rm --entrypoint bash sidelab-app:latest -lc 'id; cat /etc/debian_version; command -v git less curl'
```

When a course needs root, a kernel or systemd (Docker, Kubernetes), it declares a `runtime: vm` host instead.

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

## Steps

- A step with a terminal also has an editor panel when files are created or changed.
- A file is shown with a link, `[Open hello.txt](:open:demo/hello.txt)`, relative to the course `workdir`, never with `cat` or `more`.
- The first block of a step moves to its folder explicitly (`cd ~/lab/demo && ...`).
  `course verify` runs every block in one shell without entering the steps, so a step `workdir:` is not applied there.
- A command that waits for input, a pager or an editor, stalls `course verify` until it times out, and the following blocks fail with it.
  `git commit -m` avoids the editor, `PAGER=less` exits on output shorter than the screen.

## Checks

A directive in an HTML comment, right before the block, says what the block must produce:

```markdown
<!-- verify: requires=network timeout=180 expect="git version 2." -->
```

- `expect` names text only the output contains, since the terminal also echoes the command.
- `requires=network` goes on every block that downloads something.
- A failure in an early block cascades: the first failure of a run is the one to read.

## Diagrams

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

- Debian's Git calls `pager`, not `less`, so installing `less` is not enough without `PAGER=less` (git-essentials).
- `course verify` does not apply a step `workdir:`, so each step moves to its folder in its first block (git-essentials).
- `git init` warns about missing templates when Git is unpacked outside `/usr`, which `init.templateDir` fixes (git-essentials).
- `git pull` on a diverged branch fails until `pull.rebase` is set, so the configuration step sets it (git-essentials).
