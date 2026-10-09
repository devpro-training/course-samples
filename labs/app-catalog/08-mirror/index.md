# Mirror

Whatever the catalog, a team keeps control with two habits: it deploys a digest, never a moving tag, and it pulls from a registry of its own, never from the publisher at run time.
The copy goes on working when the publisher's terms change, its rate limits are reached, or its repository disappears, as MinIO's did.

## A registry of the team

crane carries a small registry, enough to show the idea; a team runs Harbor, a cloud registry, or the registry of its Git platform.

1. Start it in the background, storing its files in the lab folder, and wait until it answers:

   ```bash exec
   mkdir -p ~/lab/registry
   ```

   ```bash exec
   nohup crane registry serve --address "${MIRROR}" --disk ~/lab/registry > ~/lab/registry.log 2>&1 &
   ```

   <!-- verify: timeout=60 expect="registry status 0" -->

   ```bash exec
   wget -qO /dev/null --retry-connrefused --tries=20 --waitretry=1 "http://${MIRROR}/v2/"; echo "registry status $?"
   ```

## Pin, then copy

1. Resolve the moving tag to the digest of today's build:

   <!-- verify: requires=network timeout=60 expect="sha256:" -->

   ```bash exec
   cd ~/lab/registry && \
   crane digest --platform linux/amd64 "${CHAINGUARD_IMAGE}" | tee digest.txt
   ```

2. Copy that digest, with its signature and its attestations, under a name and a tag the team chooses.
   `cosign copy` copies the image and what Sigstore attached to it:

   <!-- verify: requires=network timeout=300 expect=".sig" -->

   ```bash exec
   cd ~/lab/registry && \
   cosign copy "${CHAINGUARD_IMAGE%:*}@$(cat digest.txt)" "${MIRROR}/mirror/postgres:tested" 2>&1 | tail -1 && \
   crane ls "${MIRROR}/mirror/postgres"
   ```

   The tag `tested` is the team's, and moves only when the team decides: after a scan, a test, and a review of what changed.

## Verify the copy

1. The digest is the hash of the content, so it is the same in the mirror:

   <!-- verify: expect="same=yes" -->

   ```bash exec
   cd ~/lab/registry && \
   echo "same=$([ "$(crane digest "${MIRROR}/mirror/postgres:tested")" = "$(cat digest.txt)" ] && echo yes || echo no)"
   ```

2. The signature came with it, and still names Chainguard's workflow:

   <!-- verify: timeout=120 expect="The cosign claims were validated" -->

   ```bash exec
   cosign verify --allow-insecure-registry \
     --certificate-oidc-issuer "${GITHUB_OIDC_ISSUER}" \
     --certificate-identity "${CHAINGUARD_SIGNER}" \
     "${MIRROR}/mirror/postgres:tested" 2>&1 > /dev/null | grep -- '-'
   ```

   `--allow-insecure-registry` is only needed because this registry speaks HTTP, inside the lab.

> [!NOTE]
> A mirror is not a fork: the team still depends on the publisher for the next fix.
> It buys the time to choose, and the evidence that what runs is what was verified.
> Licences still apply to the copy: an image that a contract allows to pull is not always one it allows to redistribute.
