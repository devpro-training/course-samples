# Free and enterprise

The same question for every base image: who builds it, who patches it, and what happens when the relationship ends.

---

## Why the choice matters

- **Security**: every file of the base image is code to patch, and every tool in it is a tool for an attacker.

- **Sovereignty**: the base image decides whose registry is pulled at every build, whose pipeline builds the packages, and whose decisions the product follows.

- **Independence**: an image built on a vendor's catalog is bound to the vendor's terms, price and lifetime. Starting free and being unable to leave is the cost to look at first.

- **Continuity**: the lifetime of the support, 5 years, 10 years or until the next release, is a property of the base image, and the application inherits it.

- Reading: [The siren's call of secure images: Community Linux versus vendor-specific distributions](https://devpro.fr/the-sirens-call-of-secure-images-community-linux-versus-vendor-specific-distributions/), by Bertrand Thomas, November 2025.

---

## The stack of an image

![An application image is the application, its runtime and the libraries of the base image, on the kernel of the host, which no image brings](../assets/image-layers-dark.svg#gh-dark-mode-only)
![An application image is the application, its runtime and the libraries of the base image, on the kernel of the host, which no image brings](../assets/image-layers.svg#gh-light-mode-only)

---

## Community distributions

Image                   | Maintained by                 | Libc  | Support
------------------------|-------------------------------|-------|-----------------------------------------------
`debian`, `debian:slim` | the Debian project            | glibc | community, with a published lifecycle
`ubuntu`                | Canonical                     | glibc | free security patching for 5 years from `main`, 10 years with Ubuntu Pro
`alpine`                | the Alpine Linux project      | musl  | community, several releases maintained at once
`distroless`            | Google                        | glibc | open source, signed with cosign, community
`scratch`               | nobody: it is empty           | none  | a static binary brings everything it needs

- Debian, Ubuntu and Alpine are Docker Official Images, curated by Docker, with the maintainers of each image.

- The Ubuntu figures are Canonical's, from the announcement of its chiselled images (November 2023): check the page of the day.

---

## Free to use, with an enterprise offer

Image                       | Free                                                       | Enterprise offer
----------------------------|------------------------------------------------------------|-------------------------------------------------
SUSE Linux BCI (`bci-base`, `bci-minimal`, `bci-micro`, `bci-busybox`) | The images and the SLE_BCI repository: free to use and to redistribute, under the SUSE BCI EULA, with community support | Support of a SUSE Linux Enterprise subscription, the SLES repositories through `container-suseconnect`, LTSS for certified FIPS
Red Hat UBI (`ubi`, `ubi-minimal`, `ubi-micro`, `ubi-init`) | The images and the UBI repositories: free to deploy and to redistribute, under the UBI EULA | Support when the container runs on a Red Hat platform with a subscription (RHEL, OpenShift); Red Hat supports the latest UBI version
Docker Hardened Images      | The Community catalog: Apache 2.0, signed SBOM, SLSA Build Level 3 provenance | Select and Enterprise: a 7-day SLA on critical and high CVEs, FIPS and STIG variants, customizations, extended lifecycle support
Chainguard                  | Five free images, with a `latest` tag only and no CVE remediation SLA | Per image: all upstream supported tags, a contractual SLA (7 days critical, 14 days others), pricing on request
Canonical, chiselled Ubuntu | The images, for .NET, Java and Python among others         | Ubuntu Pro, for the 10 years of security patching and the support

- Read the free column as "what is built and published", and the enterprise column as "what is promised, and by whom".

- SUSE BCI is the free offer closest to an enterprise distribution: the image of the lab, `bci-base:16.0`, reports "SUSE Linux Enterprise Server 16.0", and works with no subscription.

---

## Reading the offers

- **A free tier is a marketing choice**: Chainguard's free images are `latest` only, so a build cannot be pinned to a version, and a pinned digest receives no updates, which the vendor says itself.

- **"Near zero CVEs" is a claim about a scanner at a date**: it depends on the scanner, its database, and what is counted. Ask for the method, and measure with the scanner the team uses.

- **A hardened image from a vendor is still a vendor's image**: check the licence, the registry that serves it, what happens to a pinned image if the contract stops, and whether the build can be reproduced elsewhere.

- Docker Hardened Images are served by `dhi.io`, which answered `unauthorized` to an anonymous pull when this course was written, so the lab does not use them.

---

## WizOS

- **What**: Wiz's own container base images, "hardened, minimal, near-zero-CVE", used by Wiz's teams, and moved from Alpine's musl to glibc.

- **Availability**: private preview for Wiz customers, through the account team.

- **Not stated** in the announcement: the registry, the licence, the price, the date of general availability, the architectures and whether it is FIPS validated.

- The CVE result is Wiz's own, on its own services, without counts or method.

- A product to watch, and not an option to build on today.

- Reference: [Introducing WizOS](https://www.wiz.io/blog/introducing-wizos-hardened-near-zero-cve-base-images).
