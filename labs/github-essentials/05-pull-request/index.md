# A pull request

A pull request asks for the commits of one branch to be merged into another, and keeps the review of them.
It is a GitHub feature, not a Git one, but its commits are stored as a Git reference.

## In the browser

[Open the first pull request](:navigate:github:https://github.com/actions/checkout/pull/1) of `actions/checkout`, merged long ago, so its page never changes.

1. The title, and the number that identifies it in the repository, are at the top.
   **Merged** says it was accepted.

2. **Conversation** is the discussion and its events.
   **Commits** lists the commits to merge, and **Files changed** the difference they make, to be reviewed line by line.

3. **Checks** lists the automated runs of the pull request, the workflows of the next step.

## As a Git reference

GitHub keeps the commits of the pull request `<n>` in `refs/pull/<n>/head`, a reference that can be fetched but not pushed to.

1. In the [terminal](:panel:terminal), list it:

   <!-- verify: requires=network timeout=60 expect="bf8f62083c41b3cb36f52c4100ad20ba98400ea6" -->

   ```bash exec
   git ls-remote https://github.com/${SAMPLE_REPO}.git refs/pull/${SAMPLE_PR}/head
   ```

2. Fetch it into a local branch, with the 7 commits of the pull request:

   <!-- verify: requires=network timeout=120 expect="-> pr-" -->

   ```bash exec
   mkdir -p ~/lab/checkout && \
   cd ~/lab/checkout && \
   git init -q && \
   git remote add origin https://github.com/${SAMPLE_REPO}.git && \
   git fetch --depth 7 origin pull/${SAMPLE_PR}/head:pr-${SAMPLE_PR}
   ```

3. Read the commits, the list of the **Commits** tab:

   <!-- verify: expect="Update action.yml" -->

   ```bash exec
   cd ~/lab/checkout && \
   git log --oneline pr-${SAMPLE_PR}
   ```

4. The same pull request through the API, with its state and the commit it ends on:

   <!-- verify: requires=network expect="merged: True" -->

   ```bash exec
   wget -q -O - \
     --header="Accept: application/vnd.github+json" \
     "${GITHUB_API}/repos/${SAMPLE_REPO}/pulls/${SAMPLE_PR}" | \
   python3 -c '
   import json, sys
   pr = json.load(sys.stdin)
   for key in ("title", "state", "merged", "commits", "changed_files"):
       print(key + ":", pr[key])
   print("head:", pr["head"]["sha"])'
   ```

   > [!NOTE]
   > To propose a change to a repository that is not owned, the change goes to a **fork**, a copy owned by the account, and the pull request is opened from it.
   > This needs an account, so it is not part of this lab.
