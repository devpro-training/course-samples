# Summary

---

## Cheat sheet

Command                                                         | Does
----------------------------------------------------------------|----------------------------------------------
`crane ls <repository>`                                         | list the tags of a repository
`crane digest --platform linux/amd64 <image>`                   | the digest of an image, for one platform
`crane config <image>`                                          | the configuration: user, entry point, labels
`crane export <image> - \| tar -xO --wildcards '*os-release'`   | the Linux behind an image
`helm template <name> oci://<chart> --version <v>`              | render a chart, with no cluster
`cosign tree <image>`                                           | what is attached: signatures, attestations
`cosign verify --key <key> <image>`                             | verify a signature by a key (SUSE)
`cosign verify --certificate-identity <id> --certificate-oidc-issuer <issuer> <image>` | verify a keyless signature (Chainguard)
`cosign verify-attestation --type spdxjson ...`                 | verify, then read, an SBOM
`cosign copy <image>@<digest> <mirror>/<name>:<tag>`            | mirror an image with its signature

---

## Good practices

- **Challenge every source**, official, vendor or individual, with the same questions: who builds, on which Linux, what proves it, for how long, at what cost, and what if it stops.

- **Deploy digests**, and never `latest` in production: a tag is a name the publisher moves.

- **Verify before running**: a signature by an expected key or identity, in the pipeline and at admission.

- **Keep the evidence**: SBOM, provenance and scans, with their dates.

- **Mirror** what runs, in a registry of the team.

- **Know the exit**: the sources, a second catalog, or a build of the team.

---

## Further reading

- [Bitnami catalog changes](https://github.com/bitnami/containers/issues/83267), August 2025.
- [MinIO container images gone? Best alternatives](https://devpro.fr/minio-container-images-gone-best-alternatives-2025/), Bertrand Thomas, October 2025.
- [SUSE Application Collection documentation](https://docs.apps.rancher.io/).
- [Chainguard Catalog Starter](https://edu.chainguard.dev/chainguard/containers/reference/catalog-starter/).
- [Artifact Hub repositories and badges](https://artifacthub.io/docs/topics/repositories/).
- [Cyber Resilience Act](https://digital-strategy.ec.europa.eu/en/policies/cyber-resilience-act), and its text, [Regulation (EU) 2024/2847](https://eur-lex.europa.eu/eli/reg/2024/2847/oj).

---

## Next

- Container security: who runs the image, what it can do, and how it is isolated.

- Trivy: scan the images of this course, and compare what each catalog claims with what a scanner finds.
