# Choose

---

## The same questions, for every source

Question                                  | Evidence                                              | Seen in this lab
------------------------------------------|-------------------------------------------------------|--------------------------------------------
Who maintains the software, under which licence? | the project, the licence of each package       | the licence label of SUSE's API
Who builds the image, on which Linux?     | `os-release`, the base image label, the SBOM suppliers | Debian, Photon OS, SLE, Wolfi
What proves it?                           | a signature by a known key or identity, an SBOM, a provenance | `cosign verify`, `cosign verify-attestation`
For how long is it maintained?            | the branches and their end of life, the tags, an SLA  | SUSE's branches, Chainguard's `latest`, `bitnamilegacy`
What does it cost, now and later?         | the subscription, the pull limits, the accounts       | SUSE's Free subscription, Chainguard's Catalog Starter
What happens if it stops?                 | a mirror, the sources, a second source                | MinIO, the Bitnami chart and its missing image

---

## Three kinds of publishers

Publisher                | Examples                                       | Brings                                   | To check
-------------------------|------------------------------------------------|------------------------------------------|------------------------------------------
A community project      | Debian, the Docker Official Images, an upstream chart | open processes, public builds, many maintainers | no contract and no SLA, and a project can stop publishing (MinIO)
A vendor                 | SUSE, Broadcom (Bitnami), Chainguard, Docker   | evidence, an SLA and support under contract | the terms follow the business (Bitnami, 2025), and the Linux and the registry are the vendor's
An individual maintainer | many charts of Artifact Hub, single-maintainer images | speed, and sometimes the only package that exists | one person's time, account security and continuity

- None of the three is safe by default, and none is unsafe by default: each is a dependency, with a different way to fail.

- A badge, a pull count or a vendor's name is not a measure: the evidence of the previous steps is, on the day it is checked.

---

## Three paths

Path                           | How                                                           | Cost
-------------------------------|---------------------------------------------------------------|------------------------------------------
A vendor catalog               | subscribe, pull from the vendor, verify its evidence          | the subscription, the vendor's Linux and registry, its terms
Upstream images, secured by the team | take the official or upstream images and charts, scan them, trim them, sign them | tooling and the time of the team: Trivy to scan, RapidFort or SlimToolkit to remove what the application does not use
Built by the team              | build from source on a base image the team chose              | the team maintains the build and patches it

- Most teams mix them: a vendor for the databases, upstream images for the tools, their own builds for their applications.

- The course Container base images showed the third path and RapidFort, and the course Trivy measures all three.

---

## The team as a publisher

A team that builds its own images gives its users the evidence it asks of others, from its pipeline:

Step in the pipeline        | Tool                                    | Gives
----------------------------|-----------------------------------------|---------------------------------------------
Build for each platform     | `docker buildx build --platform ... --push` | one digest per release, multi-platform
List what is inside         | Syft                                    | an SBOM, kept with the run
Sign the digest, keyless    | `cosign sign`, with the job's OIDC token (`id-token: write`) | a signature that names the repository, the workflow and the commit, as Chainguard's does

- An example: the reusable workflow [reusable-container-publication.yml](https://github.com/devpro/github-workflow-parts/blob/main/.github/workflows/reusable-container-publication.yml) of `devpro/github-workflow-parts`,
  with every tool downloaded and checked against its checksums.

- `cosign attest --type spdxjson` attaches the SBOM to the image as a signed attestation, so it travels with the image, to the mirror included.

---

## What compliance keeps

For each image that runs, a record the team can show:

- the **digest** that runs, and the registry it was pulled from;
- the **signature** check, with the key or the identity it expected;
- the **SBOM** and the **provenance**, as published, or as the team generated them;
- a **scan** with its date, and the decision taken on each finding;
- the **end of life** of the branch, and the **licence**.

- It is the due diligence that the Cyber Resilience Act asks for components "sourced from third parties", and the answer to an audit, or to the next MinIO.
