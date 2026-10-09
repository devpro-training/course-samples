# Discover

[Artifact Hub](https://artifacthub.io/) is a project of the Cloud Native Computing Foundation (CNCF) that indexes Helm charts and other cloud native packages.
It hosts nothing: it lists what publishers declare, links to their repositories, and scans the images their charts reference.

## Search

1. Search the Helm charts (`kind=0`) named after PostgreSQL, and keep the answer in a file:

   <!-- verify: requires=network timeout=60 -->

   ```bash exec
   mkdir -p ~/lab/discover && cd ~/lab/discover && \
   wget -qO search.json "${ARTIFACTHUB_API}/packages/search?ts_query_web=postgresql&kind=0&limit=20"
   ```

2. Print, for each chart, its repository, its version, its two badges, whether it is signed, and the critical and high vulnerabilities found in its images:

   <!-- verify: expect="bitnami" -->

   ```bash exec
   cd ~/lab/discover && \
   jq -r '.packages[] | [
       .repository.name, .version,
       (if .repository.verified_publisher then "verified" else "-" end),
       (if (.official or .repository.official) then "official" else "-" end),
       (if .signed then "signed" else "-" end),
       (.security_report_summary | if . then "\(.critical // 0) critical, \(.high // 0) high" else "not scanned" end)
     ] | @tsv' search.json | \
   awk -F '\t' '{printf "%-20s %-14s %-9s %-9s %-7s %s\n", $1, $2, $3, $4, $5, $6}'
   ```

   These are 20 of several hundred charts that match the name, published by companies, projects and individuals.

## What the badges mean

Artifact Hub defines its two badges in its [documentation](https://artifacthub.io/docs/topics/repositories/):

Badge                | Means                                                      | Does not mean
---------------------|------------------------------------------------------------|--------------------------------------
**Verified publisher** | the publisher "owns or has control over the repository"  | that the chart is maintained, reviewed or safe
**Official**         | the publisher "owns the software a package primarily focuses on" | that the images are patched or supported

1. Look for a chart of PostgreSQL that is official:

   <!-- verify: requires=network timeout=60 expect="official postgresql charts: 0" -->

   ```bash exec
   echo "official postgresql charts: $(wget -qO- "${ARTIFACTHUB_API}/packages/search?ts_query_web=postgresql&kind=0&official=true&limit=60" | \
     jq '[.packages[] | select(.name == "postgresql")] | length')"
   ```

   The PostgreSQL project publishes no Helm chart, so none is official.
   A repository can still be named `postgresql`, and be verified: the badge only says that its publisher controls it.

## What a chart points to

A chart installs images, and the image is what runs.

1. Read the most used chart: where it comes from, its version, and the images it declares:

   <!-- verify: requires=network timeout=60 expect="bitnami/postgresql:" -->

   ```bash exec
   wget -qO- "${ARTIFACTHUB_API}/packages/helm/bitnami/postgresql" | \
   jq -r '"repository: \(.repository.url)", "chart: \(.version)", "application: \(.app_version)", "signed: \(.signed)", (.containers_images[] | "image: \(.image)")'
   ```

   The chart has a version, and the PostgreSQL image it installs has the tag `latest`.
   The next steps look at what is behind each of these names.
