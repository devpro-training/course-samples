# Application catalog

A team rarely builds the database, the cache or the message broker it runs.
It deploys an image and a Helm chart that someone else built, and inherits everything that comes with them.

---

## What an application catalog is

- **A set of ready-to-run applications**: container images and Helm charts of open source software, built and published by one party.

- **Its metadata**: the versions, the branches and their end of life, the licence, and the subscription each application needs.

- **Its evidence**: a signature, a software bill of materials (SBOM), a build provenance and vulnerability scans, attached to each image.

- **Examples**: the Docker Official Images, the Bitnami catalog, SUSE Application Collection, Chainguard Containers, Docker Hardened Images, Red Hat's ecosystem catalog, and Artifact Hub, an index of the charts others publish.

---

## A supply chain

![An application goes from its source, through the publisher's build on a Linux of its choice, to a registry with its signature, SBOM, provenance and scans, then to the team that verifies, pins, mirrors and deploys it](../assets/catalog-supply-chain-dark.svg#gh-dark-mode-only)
![An application goes from its source, through the publisher's build on a Linux of its choice, to a registry with its signature, SBOM, provenance and scans, then to the team that verifies, pins, mirrors and deploys it](../assets/catalog-supply-chain.svg#gh-light-mode-only)

---

## Why it is a compliance question

- **The EU Cyber Resilience Act** (Regulation (EU) 2024/2847) entered into force on 10 December 2024, its reporting obligations apply from 11 September 2026, and its main obligations from 11 December 2027.

- **Due diligence** (Article 13(5)): a manufacturer "shall exercise due diligence when integrating components sourced from third parties", free and open source software included.

- **An SBOM** (Annex I, Part II): the manufacturer identifies the components of its product, "including by drawing up a software bill of materials in a commonly used and machine-readable format".

- An image picked from a catalog is such a component: the evidence that comes with it, or its absence, becomes the team's.

---

## Why "official" is not enough

- **A label says who publishes**, not who maintains, for how long, or what the image contains.

- **A publisher can change its terms**: Bitnami moved its free versioned images to a frozen repository in August 2025, and MinIO stopped publishing its images in October 2025.

- **An image brings a Linux distribution** chosen by its publisher, with its packages, its patches and its lifecycle.

- **The same questions apply to everyone**: a community project, a vendor, and a single maintainer are each a dependency, with a different risk.

---

## In this lab

Step            | What it shows
----------------|-----------------------------------------------------------------------------
Setup           | jq, crane, cosign and Helm, as single binaries
Discover        | Artifact Hub, and what its badges mean
Official images | what a Docker Official Image proves, and the MinIO case
Bitnami         | a chart that still installs, and the image it points to that is gone
SUSE            | SUSE Application Collection, its evidence and its free subscription
Chainguard      | a signed image, its own Linux, and a `latest` tag only
Mirror          | pin a digest and keep a copy in a registry of the team
Choose          | the questions to ask any catalog

> No account and no container engine: every command reads a public registry or API.
