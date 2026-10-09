# Harden what exists

---

## Three ways to reduce an image

Way                    | Idea                                                  | Example
-----------------------|-------------------------------------------------------|------------------------------------------
Choose a smaller base  | start from fewer files                                | `distroless`, `ubi-micro`, `bci-micro`
Build in stages        | the compiler and the sources never reach the image    | multi-stage Dockerfile
Remove what is unused  | run the application, record the files it opens, drop the others | SlimToolkit, RapidFort

---

## Profile, then remove

- A **profile** is a run of the application, with its tests, during which the files, libraries and packages it opens are recorded.

- Anything absent from the profile is a candidate for removal: a shell, a compiler, a package manager, packages the application never loads.

- **RapidFort** does it as a commercial product, with a runtime profile (a runtime bill of materials) and presets that remove unused packages: all of them, the ones with known vulnerabilities, or the ones with high and critical vulnerabilities.

- **SlimToolkit** (now named `mint`) is the open source tool of the same idea, a CNCF Sandbox project, with a static analysis and a dynamic one.
  The release tried while writing this course stopped with `client version 1.33 is too old` against Docker 29: check that a tool follows the engine before building on it.

---

## The limits

- **Unused is not unneeded**: a path of the application that the profile did not run, a rare error branch or a monthly job, can fail once its file is gone. The quality of the profile is the quality of the result.

- **Removal does not patch**: a vulnerability in a library that the application uses stays.

- **The reductions published** by vendors, 90 percent for example, are results on selected images: measure on the images of the team.

- **A removal is a change to an image the vendor did not build**: the signature, the provenance and the support may not follow it.

---

## Hardening to a standard

- The CIS Benchmarks and the DISA STIGs are public standards, for the operating system and for containers.

- **OpenSCAP** checks a system against them, and Anchore's tools produce an inventory (SBOM) and a list of vulnerabilities of an image.

- The same tools apply to an image of any provenance, the one a vendor sells and the one a team builds, which is the way to compare them on the same measure.

- Next courses: Container security, then Trivy to scan an image.
