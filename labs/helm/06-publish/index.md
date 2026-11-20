# Host a chart repository for free

A chart repository is a static web server: the packaged charts, and an `index.yaml` that lists them.
Any place that serves files is enough, so GitHub can host it for free, with a workflow that packages and publishes every new version.
This step builds the repository by hand first, so the workflow is no surprise.

## A repository in two commands

1. Package the chart in a folder, and index the folder.
   `--url` is where the archives will be served from, and `index.yaml` records it:

   <!-- verify: expect="shop-0.2.0.tgz" -->

   ```bash exec target=docker
   mkdir -p ~/lab/repo && cd ~/lab/charts && \
   helm package shop --destination ~/lab/repo && \
   helm repo index ~/lab/repo --url http://127.0.0.1:8080 && \
   ls ~/lab/repo
   ```

2. Read the index.
   It holds the content of `Chart.yaml`, the address of the archive, and its digest:

   <!-- verify: expect="digest:" -->

   ```bash exec target=docker
   cat ~/lab/repo/index.yaml
   ```

3. Serve the folder, and wait until it answers:

   ```bash exec target=docker
   cd ~/lab/repo && nohup python3 -m http.server 8080 --bind 127.0.0.1 > ~/lab/repo.log 2>&1 &
   ```

   <!-- verify: timeout=60 expect="served: 1" -->

   ```bash exec target=docker
   for i in $(seq 1 20); do wget -qO- http://127.0.0.1:8080/index.yaml > /dev/null && break; sleep 1; done; \
   echo "served: $(wget -qO- http://127.0.0.1:8080/index.yaml | grep -c 'name: shop')"
   ```

## Use it like any catalog

1. Add the repository, search it, and install the chart from it.
   These are the commands of the first step, with another URL:

   <!-- verify: timeout=240 expect="CHART VERSION" -->

   ```bash exec target=docker
   helm repo add mine http://127.0.0.1:8080 && \
   helm search repo mine && \
   helm install fromrepo mine/shop --version 0.2.0 --namespace shop --wait --timeout 3m
   ```

2. The repository keeps every version.
   A new version is a package and an index with `--merge`, and users get it with `helm repo update`:

   <!-- verify: expect="shop-0.2.0.tgz" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   sed -i 's/^version: .*/version: 0.2.1/' shop/Chart.yaml && \
   helm package shop --destination ~/lab/repo && \
   helm repo index ~/lab/repo --url http://127.0.0.1:8080 --merge ~/lab/repo/index.yaml && \
   helm repo update mine && \
   helm search repo mine --versions && \
   ls ~/lab/repo
   ```

3. Stop the server:

   <!-- verify: expect="left: 0" -->

   ```bash exec target=docker
   pkill -f "^python3 -m http.server 8080"; sleep 1; \
   echo "servers left: $(pgrep -fc '^python3 -m http.server')"
   ```

## The same, on GitHub, for free

GitHub does both jobs.
The source of the charts is a branch like any other, the archives are the assets of GitHub releases, and `index.yaml` lives on the branch `gh-pages`, which GitHub Pages serves at `https://<owner>.github.io/<repository>`.
The action chart-releaser (`cr`) does what the two commands above do, on every push to `main`: it packages the charts whose version is new, creates a release per chart, and updates `index.yaml`.

Once, by hand: create the branch `gh-pages`, and in **Settings > Pages** set its source to that branch.

1. Write the workflow of the release.
   The actions are pinned to the full commit of a tag, since a tag can be moved.
   The job needs to write, to create the releases and push the index:

   <!-- verify: expect="actions pinned: 2" -->

   ```bash exec target=docker
   mkdir -p ~/lab/github/.github/workflows && cd ~/lab/github && \
   tee .github/workflows/release.yml <<'EOT'
   name: Release charts

   on:
     push:
       branches:
         - main

   permissions:
     contents: write

   jobs:
     release:
       runs-on: ubuntu-latest
       steps:
         # actions/checkout v7.0.1
         - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
           with:
             # chart-releaser compares the history to find the charts that changed
             fetch-depth: 0
         - name: Configure Git
           run: |
             git config user.name "$GITHUB_ACTOR"
             git config user.email "$GITHUB_ACTOR@users.noreply.github.com"
         # helm/chart-releaser-action v1.7.0, the charts are read from the folder charts/
         - uses: helm/chart-releaser-action@cae68fefc6b5f367a0275617c9f83181ba54714f
           env:
             CR_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   EOT
   echo "actions pinned: $(grep -c 'uses: .*@[0-9a-f]\{40\}' .github/workflows/release.yml)"
   ```

2. Write the workflow of the checks, which runs on every pull request.
   chart-testing (`ct`) finds the charts that changed, lints them with Yamale and yamllint, and installs each one in a throwaway [kind](https://kind.sigs.k8s.io/) cluster:

   <!-- verify: expect="steps: 8" -->

   ```bash exec target=docker
   cd ~/lab/github && \
   tee .github/workflows/ci.yml <<'EOT'
   name: Charts

   on:
     pull_request:
       branches:
         - main

   permissions:
     contents: read

   jobs:
     lint-test:
       runs-on: ubuntu-latest
       steps:
         # actions/checkout v7.0.1
         - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
           with:
             fetch-depth: 0
         # azure/setup-helm v4.3.1
         - uses: azure/setup-helm@1a275c3b69536ee54be43f2070a358922e12c8d4
         # actions/setup-python v6.2.0, which chart-testing needs for Yamale and yamllint
         - uses: actions/setup-python@a309ff8b426b58ec0e2a45f0f869d46889d02405
           with:
             python-version: "3.x"
         # helm/chart-testing-action v2.9.0
         - uses: helm/chart-testing-action@720270857a28afd41e2426521a7801db09e9b510
         - name: List the charts that changed
           id: list-changed
           run: |
             changed=$(ct list-changed --chart-dirs charts --target-branch ${{ github.event.repository.default_branch }})
             if [[ -n "$changed" ]]; then
               echo "changed=true" >> "$GITHUB_OUTPUT"
             fi
         - name: Lint
           if: steps.list-changed.outputs.changed == 'true'
           run: ct lint --chart-dirs charts --target-branch ${{ github.event.repository.default_branch }}
         # helm/kind-action v1.15.1
         - uses: helm/kind-action@1544676c07bb3570fcb70166beaa07c4528fd4aa
           if: steps.list-changed.outputs.changed == 'true'
         - name: Install and test
           if: steps.list-changed.outputs.changed == 'true'
           run: ct install --chart-dirs charts --target-branch ${{ github.event.repository.default_branch }}
   EOT
   echo "steps: $(grep -c '^      - \(uses\|name\)' .github/workflows/ci.yml)"
   ```

The users of the repository need one URL, the one of the pages:

```bash
helm repo add <name> https://<owner>.github.io/<repository>
```

`ct lint` checks a chart that changed: its version must be bumped, and `ct install` runs `helm install` and `helm test`, so the test of the previous step is run on every pull request.

## Or a registry

Helm also stores a chart in an OCI registry, as an image is, and `ghcr.io` hosts them for free next to the images.
There is no index: the address of the chart is the address of the artifact.

1. Start a registry, push the chart, and read it back.
   The registry listens on the loopback without TLS, hence `--plain-http`:

   <!-- verify: requires=network timeout=240 expect="Digest: sha256" -->

   ```bash exec target=docker
   cd ~/lab && \
   docker run -d --name registry -p 127.0.0.1:5000:5000 "${REGISTRY_IMAGE}" > /dev/null && \
   for i in $(seq 1 30); do wget -qO- http://127.0.0.1:5000/v2/ > /dev/null && break; sleep 1; done; \
   helm push repo/shop-0.2.1.tgz oci://127.0.0.1:5000/charts --plain-http
   ```

2. Show the chart from the registry, by its version:

   <!-- verify: expect="version: 0.2.1" -->

   ```bash exec target=docker
   helm show chart oci://127.0.0.1:5000/charts/shop --version 0.2.1 --plain-http
   ```

3. Remove the registry:

   <!-- verify: expect="left: 0" -->

   ```bash exec target=docker
   docker rm -f registry > /dev/null && \
   echo "registries left: $(docker ps -aq --filter name=^registry$ | wc -l)"
   ```
