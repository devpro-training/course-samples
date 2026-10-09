# Chainguard

[Chainguard Containers](https://edu.chainguard.dev/chainguard/chainguard-images/overview/) are minimal images, built from source and rebuilt often to pick up fixes, and signed by the pipeline that builds them.
A set of them is free and anonymous on `cgr.dev/chainguard`, on the `latest` tag only, and every other tag and image is part of a paid offer.

## The tags

1. List the tags of the free PostgreSQL image, without the ones that hold signatures and attestations:

   <!-- verify: requires=network timeout=60 expect="latest-dev" -->

   ```bash exec
   crane ls "${CHAINGUARD_IMAGE%:*}" | grep -v '^sha256-'
   ```

   `latest`, and `latest-dev`, the same image with a shell and a package manager.

2. Read when `latest` was built:

   <!-- verify: requires=network timeout=60 expect="built on 20" -->

   ```bash exec
   crane config --platform linux/amd64 "${CHAINGUARD_IMAGE}" | jq -r '"built on \(.created[:10])"'
   ```

   `latest` is rebuilt continuously, and the major version of PostgreSQL behind it changes when Chainguard moves it.
   It is fine to try and to test, and not for production: a deployment cannot hold a version with it, and a digest taken from it holds one build that the free offer never patches.

## Who signed it

Chainguard signs with Sigstore's keyless signing: the certificate names the workflow that built the image, and the signature is recorded in a public transparency log.

1. Verify the signature, and require that it comes from Chainguard's release workflow:

   <!-- verify: requires=network timeout=120 expect="chainguard-images/images" -->

   ```bash exec
   cosign verify \
     --certificate-oidc-issuer "${GITHUB_OIDC_ISSUER}" \
     --certificate-identity "${CHAINGUARD_SIGNER}" \
     "${CHAINGUARD_IMAGE}" 2> /dev/null | \
   jq -r '.[0].optional | "repository: \(.["1.3.6.1.4.1.57264.1.5"])", "workflow: \(.["1.3.6.1.4.1.57264.1.4"])", "commit: \(.["1.3.6.1.4.1.57264.1.3"])"'
   ```

   The numbered fields are extensions of Sigstore's certificates: the repository, the workflow and the commit that signed.
   Any other identity fails the command, which is what a pipeline or an admission controller checks before running an image.

## The Linux behind it

1. Read the distribution of the image:

   <!-- verify: requires=network timeout=300 expect="Wolfi" -->

   ```bash exec
   crane export --platform linux/amd64 "${CHAINGUARD_IMAGE}" - | tar -xO --wildcards '*os-release' | grep -m1 '^PRETTY_NAME'
   ```

   Wolfi: a distribution for containers, created by Chainguard, which builds its `apk` packages from source.
   Wolfi and Alpine both use `apk`, and their packages are not compatible.

2. Verify the SBOM attached to the `x86_64` image, with the same identity, and count where its packages come from:

   <!-- verify: requires=network timeout=120 expect="apk/wolfi" -->

   ```bash exec
   mkdir -p ~/lab/chainguard && cd ~/lab/chainguard && \
   digest=$(crane digest --platform linux/amd64 "${CHAINGUARD_IMAGE}") && \
   cosign verify-attestation --type spdxjson \
     --certificate-oidc-issuer "${GITHUB_OIDC_ISSUER}" \
     --certificate-identity "${CHAINGUARD_SIGNER}" \
     "${CHAINGUARD_IMAGE%:*}@${digest}" 2> /dev/null | jq -r .payload | base64 -d > sbom.json && \
   jq -r '"\(.predicate.packages | length) entries",
     ([.predicate.packages[].externalRefs[]?.referenceLocator | select(startswith("pkg:apk/")) | split("/")[0:2] | join("/")] | group_by(.) | map("  \(length) packages from \(.[0])")[])' sbom.json
   ```

   Every system package comes from Wolfi: the image, its Linux, its build and its signature are all Chainguard's.

## The free offer and what follows

Plan                | What it gives                                                     | Conditions
--------------------|-------------------------------------------------------------------|-----------------------------------------
Free images         | a set of images, `latest` only, anonymous                         | no SLA, no version to hold
Catalog Starter     | five non-FIPS images of the catalog, the same as paying customers get; "any Helm charts that depend on those images are included and count toward the five-image limit" | a corporate email, a pull token that expires (30 days by default, one year at most), no CVE SLA, no support tickets
Catalog or per image | the catalog or a set of images, FIPS images, end-of-life versions, a contractual CVE remediation SLA | a paid subscription, which replaces Catalog Starter

The figures are from [Catalog Starter](https://edu.chainguard.dev/chainguard/containers/reference/catalog-starter/), in beta, and checked on the day this course was written.
A team on a paid plan pulls from `cgr.dev/<organization>/`, a path of its own: every chart, Dockerfile and pipeline names Chainguard's registry, and Chainguard's Linux.
