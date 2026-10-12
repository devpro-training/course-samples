# Image

Trivy reads an image from its registry, layer by layer, and needs no container engine.
The first scan downloads the vulnerability database, which the next ones reuse.

## The database

1. Scan a supported image, with a summary of the high and critical findings:

   <!-- verify: requires=network timeout=240 expect="alpine 3.22" -->

   ```bash exec
   cd ~/lab && \
   trivy image --no-progress --severity HIGH,CRITICAL "${ALPINE_IMAGE}" 2>&1 | grep -v INFO
   ```

   Trivy detects the Linux behind the image, and its packages, then looks each one up.
   A supported, minimal Linux can come out clean: zero findings is the result of the day, not a guarantee.

2. Read what the first scan downloaded:

   <!-- verify: expect="Vulnerability DB:" -->

   ```bash exec
   trivy version
   ```

   The database is dated: `UpdatedAt` is the day of its data, and a scan of tomorrow can find what today's does not.
   Its numbers change between two runs, which is why the course never counts on one.

## An end of life Linux

1. Scan an image of a release that its distribution no longer maintains:

   <!-- verify: expect="no longer supported" -->

   ```bash exec
   trivy image --no-progress --severity HIGH,CRITICAL "${ALPINE_OLD_IMAGE}" 2>&1 | grep -E "WARN|Total"
   ```

   The warning says the detection "may be insufficient because security updates are not provided".
   An empty report on such an image is not a clean one: nobody publishes the advisories Trivy would look for.

## Unfixed vulnerabilities

Debian's security tracker lists vulnerabilities that have no fix yet, which a team can only accept or work around.

1. Print the findings of a Debian image as JSON, and count them by status:

   <!-- verify: requires=network timeout=240 expect="affected:" -->

   ```bash exec
   trivy image --no-progress --quiet --format json "${DEBIAN_IMAGE}" | \
   jq -r '[.Results[].Vulnerabilities[]?.Status] | group_by(.) | map("\(.[0]): \(length)") | .[]'
   ```

   `affected` has no fix yet, `fix_deferred` is a fix the maintainers postponed, `will_not_fix` a fix they declined, and `fixed` a fix that is published.

2. Compare the high and critical findings with all of them, and with the fixable ones only:

   <!-- verify: requires=network timeout=240 expect="Total:" -->

   ```bash exec
   for option in "" "--ignore-unfixed"; do
     echo "options: ${option:-none}"
     trivy image --no-progress ${option} --severity HIGH,CRITICAL "${DEBIAN_IMAGE}" 2>&1 | grep "Total"
   done
   ```

   `--ignore-unfixed` makes a report shorter and actionable, and also less complete: the choice is stated, not hidden.
