# SUSE Application Collection

[SUSE Application Collection](https://docs.apps.rancher.io/) is "a curated, trusted and up-to-date collection of developer and infrastructure applications built, packaged, tested and distributed by SUSE", as images and Helm charts.
Its web pages and its metadata API are public, and pulling an image or a chart needs an account.

## In the browser

The browser of the lab shows the page of PostgreSQL.
[Open it again](:navigate:appco:https://apps.rancher.io/applications/postgresql) at any time.

1. Under the name, read **Subscription: Free**: the minimum subscription to pull it.
   The command below it is the `helm pull` of the latest chart, and the **VERSIONS** tab lists every chart, with the PostgreSQL version it installs.

2. Select the **COMPONENTS** tab.
   PostgreSQL comes in one branch per major version, and the branches that PostgreSQL no longer maintains are marked **Inactive**.

3. Under PostgreSQL, select **VIEW ALL REVISIONS**, and select the first row of the newest version with the architecture `x86_64`.

4. Read the page of the image:

   - **Signed**, and a **Vulnerability score**, from 1 to 5, computed from its last scan;
   - **Base image**: SLE BCI-micro, the SUSE Linux BCI image with no package manager, and the operating system, SUSE Linux Enterprise;
   - **Attestation**: two SBOMs (CycloneDX and SPDX), a SLSA provenance, two vulnerability scans (NeuVector and Trivy), and an antivirus scan;
   - the **VULNERABILITIES**, **SYSTEM PACKAGES** and **OCI ANNOTATIONS** tabs.

## The same, from the API

1. List the applications of the Free subscription:

   <!-- verify: requires=network timeout=60 expect="HELM_CHART" -->

   ```bash exec
   wget -qO- "${APPCO_API}/v1/applications?subscriptions=FREE&page_size=100" | \
   jq -r '"\(.total_size) applications", (.items[] | "  \(.type)  \(.slug_name)")'
   ```

   PostgreSQL, Redis and NGINX among applications, and the SUSE Linux BCI base images, FIPS variants included.

2. Read the subscription, the licence and the branches of PostgreSQL, with the date each one becomes inactive:

   <!-- verify: requires=network timeout=60 expect="end of life 20" -->

   ```bash exec
   wget -qO- "${APPCO_API}/v1/applications/postgresql" | \
   jq -r '"subscription: \(.subscriptions | join(", "))",
     "licence: \(.labels[] | select(startswith("license:")) | ltrimstr("license:"))",
     (.branches[] | "branch \(.branch_name)  end of life \(.inactive_at[:10])")'
   ```

   The dates are the ones of the PostgreSQL project: the catalog follows the lifecycle of the upstream branches, and says when each one ends.

3. Find the latest image of the branch of this course, for `x86_64`, and list the documents attached to it:

   <!-- verify: requires=network timeout=60 expect="SBOM SPDX" -->

   ```bash exec
   mkdir -p ~/lab/suse && cd ~/lab/suse && \
   wget -qO- "${APPCO_API}/v1/artifacts?component_slug_name=postgresql&packaging_formats=CONTAINER&architecture=x86_64&page_size=100" | \
   jq "[.items[] | select(.version | startswith(\"${APPCO_BRANCH}.\")) | select(.flavor == null)] | sort_by(.registered_at) | last" > artifact.json && \
   jq -r '"image: \(.name)", "digest: sha256:\(.digest.value)", "linux: \(.operating_system.family) \(.operating_system.version)", (.resources[] | "  \(.type) \(.format)")' artifact.json
   ```

## The evidence

Each document is downloaded by the digest of the image, with no account.

1. The SBOM lists every package of the image, and who supplies it:

   <!-- verify: requires=network timeout=60 expect="Organization: SUSE" -->

   ```bash exec
   cd ~/lab/suse && \
   wget -qO sbom.spdx.json "${APPCO_API}/v1/artifacts/$(jq -r .digest.value artifact.json)/resources?type=SBOM&format=SPDX" && \
   jq -r '"\(.packages | length) packages", ([.packages[].supplier] | group_by(.) | map("  \(length)  \(.[0])")[])' sbom.spdx.json
   ```

   The packages are SUSE Linux Enterprise packages, built by SUSE: the Linux behind the image is the one SUSE sells support for.

2. The provenance says how and from what the image was built:

   <!-- verify: requires=network timeout=60 expect="open-build-service.org" -->

   ```bash exec
   cd ~/lab/suse && \
   wget -qO provenance.json "${APPCO_API}/v1/artifacts/$(jq -r .digest.value artifact.json)/resources?type=PROVENANCE&format=SLSA" && \
   jq -r '"build: \(.buildDefinition.buildType)", "sources: \(.buildDefinition.externalParameters.source)", "inputs: \(.buildDefinition.resolvedDependencies | length)"' provenance.json
   ```

   The Open Build Service, SUSE's build system, with the sources published on `sources.suse.com` and every input recorded by its hash.

3. The vulnerability scan holds its date, its target and its findings:

   <!-- verify: requires=network timeout=60 expect="target: postgresql" -->

   ```bash exec
   cd ~/lab/suse && \
   wget -qO trivy.json "${APPCO_API}/v1/artifacts/$(jq -r .digest.value artifact.json)/resources?type=VULNERABILITY_SCAN&format=TRIVY" && \
   jq -r '"scanned: \(.metadata.scanFinishedOn[:10])", "target: \(.scanner.result.Results[0].Target)", "vulnerabilities: \([.scanner.result.Results[].Vulnerabilities[]?] | length)"' trivy.json
   ```

   A scan is true on its date, with its database: the course Trivy runs the same scanner on the images of the team.

## The subscriptions

Every pull needs an account, even of a free application, and the [subscriptions](https://docs.apps.rancher.io/get-started/subscriptions) set the limits, per 24 hours:

Subscription | Comes with                         | Content                 | User accounts | Pulls per user | Service accounts | Pulls per service account
-------------|------------------------------------|-------------------------|---------------|----------------|------------------|--------------------------
Free         | a SUSE Customer Center account     | Free                    | 1             | 100            | 0                | none
Prime        | SUSE Rancher Prime                 | Free, Prime             | 10            | 200            | 5                | 2000
Extended     | SUSE Rancher Suite + SUSE AI Suite | Free, Prime, Extended   | 100           | 500            | 10               | 5000
SUSE AI      | SUSE AI Suite                      | Free, Prime, SUSE AI    | 100           | 500            | 10               | 5000

The Free subscription has one user, 100 pulls a day, and no service account, which is the identity a pipeline or a cluster pulls with.
A team that runs on it pulls through a mirror of its own, as in the step Mirror, or with a paid subscription.

## With an account

These commands need the `APPCO_USERNAME` and `APPCO_TOKEN` secrets of the lab, an account of the Free subscription and one of its access tokens.
They follow the [Helm](https://docs.apps.rancher.io/get-started/deploy-a-helm-chart) and [cosign](https://docs.apps.rancher.io/developer-toolkit/verify-signatures-with-cosign) guides of the collection.

1. Log in to the registry, pull the chart, and list the images it runs:

   <!-- verify: skip reason="needs an Application Collection account" -->

   ```bash exec
   cd ~/lab/suse && \
   echo "${APPCO_TOKEN}" | helm registry login "${APPCO_REGISTRY}" --username "${APPCO_USERNAME}" --password-stdin && \
   helm pull "oci://${APPCO_REGISTRY}/charts/postgresql" --untar && \
   helm template db ./postgresql | grep 'image:' | sort -u
   ```

2. Verify the signature of the image with SUSE's public key:

   <!-- verify: skip reason="needs an Application Collection account" -->

   ```bash exec
   cd ~/lab/suse && \
   cosign verify --key "${APPCO_PUBLIC_KEY}" \
     --registry-username "${APPCO_USERNAME}" --registry-password "${APPCO_TOKEN}" \
     "${APPCO_REGISTRY}/containers/postgresql@sha256:$(jq -r .digest.value artifact.json)" | jq .
   ```

   SUSE signs with a key, which it publishes, where Chainguard, in the next step, signs with the identity of its build.
