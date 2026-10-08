# GitHub Actions

A workflow is a YAML file in `.github/workflows/`, which GitHub runs when an event happens in the repository, a push or a pull request for example.
It holds **jobs**, each run on a **runner**, a machine GitHub provides, as an ordered list of **steps**: a shell command (`run`) or a reusable **action** (`uses`).

## The file

The workflow is part of the repository, so it is read like any other file, at the version of a tag.

1. In the [terminal](:panel:terminal), fetch the tag, and write the workflow out of it:

   <!-- verify: requires=network timeout=120 -->

   ```bash exec
   mkdir -p ~/lab/checkout && \
   cd ~/lab/checkout && \
   (git rev-parse --git-dir >/dev/null 2>&1 || git init -q) && \
   (git remote add origin https://github.com/${SAMPLE_REPO}.git 2>/dev/null || true) && \
   git fetch --depth 1 origin tag ${SAMPLE_TAG} && \
   git show ${SAMPLE_TAG}:${SAMPLE_WORKFLOW} > test.yml
   ```

2. Read it:

   [Open test.yml](:open:checkout/test.yml)

   Part       | Does
   -----------|----------------------------------------------------------
   `name`     | The name displayed in the **Actions** tab
   `on`       | The events that start a run: `pull_request`, and a `push` to `main` or a `releases/*` branch
   `jobs`     | The jobs, here `build`, run on the `ubuntu-latest` runner
   `uses`     | An action: `actions/setup-node@v4`, and `actions/checkout` pinned to a version
   `run`      | A shell command: `npm ci`, `npm run build`, `npm test`

3. Check that the events and the runner are in the file:

   <!-- verify: expect="runs-on: ubuntu-latest" -->

   ```bash exec
   cd ~/lab/checkout && \
   grep -n -E "^on:|pull_request|runs-on" test.yml
   ```

## The runs

Go to the [browser](:panel:vnc), which shows the [runs of this workflow](:navigate:github:https://github.com/actions/checkout/actions/workflows/test.yml).

1. The **Workflows** list on the left has one entry per file, and **All workflows** shows the runs of every one.

2. Each run is a row with the event that started it, its branch and its status.
   **Event**, **Status**, **Branch** and **Actor** above the list filter the rows.

3. A run opens on its jobs and, for each of them, the output of every step.

The API lists the same runs:

<!-- verify: requires=network expect="event: pull_request" -->

```bash exec
wget -q -O - \
  --header="Accept: application/vnd.github+json" \
  "${GITHUB_API}/repos/${SAMPLE_REPO}/actions/workflows/test.yml/runs?per_page=1&status=success" | \
python3 -c '
import json, sys
run = json.load(sys.stdin)["workflow_runs"][0]
print("event:", run["event"])
print("conclusion:", run["conclusion"])'
```

> [!NOTE]
> A workflow that writes to the repository, or uses a secret, runs with a token GitHub creates for the run.
> Third-party actions are pinned to a full commit SHA, since a tag can be moved.
