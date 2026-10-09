# Summary

---

## Choosing

Need                                  | Base
--------------------------------------|----------------------------------------------------------
A static binary (Go, Rust)            | `scratch`, or `distroless/static`
A glibc application, no shell         | `distroless/base`, `bci-micro`, `ubi-micro`
An application that needs packages    | `bci-base`, `ubi-minimal`, `debian:slim`
A support contract, same system as the servers | SUSE BCI with a SUSE subscription, UBI on Red Hat platforms
Small and simple, and musl is fine    | `alpine`

---

## Good practices

- **Pin** the base: a version tag at least, a digest for a build that must be reproducible, and update it on purpose.

- **Multi-stage**: build in one stage, ship the result on a small base.

- **Order the layers**: what changes rarely first, so the cache works, and delete files in the instruction that created them.

- **Run as a user that is not root**, with a read-only filesystem and no capabilities that the application does not use.

- **No secret in an image**: it is readable by everyone who pulls it.

---

## Independence

- Prefer a base **maintained by a community or by several parties**, with public builds, over one whose pipeline only its vendor can see.

- Know the **exit**: can the image be rebuilt, mirrored and kept if the free offer changes, and who patches it then?

- Keep a **mirror** in a registry of the team, so a build does not depend on a vendor's availability.

- Read the offers with a scanner and a licence, and not with a brochure.

- Further reading: [The siren's call of secure images](https://devpro.fr/the-sirens-call-of-secure-images-community-linux-versus-vendor-specific-distributions/), [SUSE Linux BCI](https://opensource.suse.com/bci-docs/), [Red Hat UBI](https://catalog.redhat.com/en/software/base-images), [distroless](https://github.com/GoogleContainerTools/distroless), [Docker build best practices](https://docs.docker.com/build/building/best-practices/).

---

## Next

- Container security: who runs the image, what it can do, and how it is isolated.

- Trivy: scan an image for vulnerabilities, and compare the bases of this course.
