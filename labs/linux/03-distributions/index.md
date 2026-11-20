# Distributions

---

## What a distribution is

- A kernel, the userland, a package manager, an init system and defaults, built, tested and updated together.

- Distributions differ by their **package format and manager**, their **release model**, the **length of their support**, and who stands behind them.

- A command that is not about packages, services or paths works the same on all of them.

---

## Families

Family  | Distributions                                                     | Package        | Manager
--------|-------------------------------------------------------------------|----------------|----------------
Debian  | Debian, Ubuntu                                                    | `.deb`         | `apt`, `dpkg`
Red Hat | Fedora, CentOS Stream, RHEL, AlmaLinux, Rocky Linux               | `.rpm`         | `dnf`, `rpm`
SUSE    | openSUSE Leap and Tumbleweed, SUSE Linux Enterprise Server (SLES) | `.rpm`         | `zypper`, `rpm`
Arch    | Arch Linux                                                        | `.pkg.tar.zst` | `pacman`
Alpine  | Alpine Linux                                                      | `.apk`         | `apk`

---

## How they relate

![Debian, Red Hat and SUSE families, from their community distribution to their enterprise one](../assets/linux-distributions-dark.svg#gh-dark-mode-only)
![Debian, Red Hat and SUSE families, from their community distribution to their enterprise one](../assets/linux-distributions.svg#gh-light-mode-only)

---

## Debian and Ubuntu

- **Debian** is a community project.
  Debian 13 "trixie" is the stable release since 2025-08-09, and Debian 12 "bookworm", the one of this lab, was released on 2023-06-10 and has long term support until 2028-06-30.

- **Ubuntu**, from Canonical, is built on Debian, and releases every six months, with a long term support (LTS) release every two years.
  Ubuntu 26.04 LTS has five years of standard security maintenance.

- Both use `apt` and `dpkg`: **this lab uses Debian, and every command works the same on Ubuntu.**

- Ubuntu is also the distribution that `wsl --install` sets up by default.

---

## Red Hat

- **Fedora**: the community distribution, a new release about every six months, where new technology arrives first.

- **CentOS Stream**: the upstream development branch of RHEL, slightly ahead of it.

- **Red Hat Enterprise Linux (RHEL)**: sold with a subscription, for ten years of life cycle per major release (8, 9 and 10 are supported at the time of writing).

- **AlmaLinux** and **Rocky Linux**: free distributions compatible with RHEL.

---

## Red Hat and its source code

Date       | What happened
-----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
2019-07-09 | IBM completes the acquisition of Red Hat, for about 34 billion dollars.
2020-12-08 | The CentOS Project moves its focus to CentOS Stream: CentOS Linux 8, a rebuild of RHEL 8, ends at the end of 2021.
2023-06-21 | Red Hat announces that CentOS Stream is the sole repository for public RHEL-related source code. Customers and partners keep their access through the Red Hat Customer Portal.
2023-06-22 | AlmaLinux reads the portal's agreements as forbidding to re-publish the sources it gets there.
2023-06-26 | Red Hat answers that the code built into RHEL is public in CentOS Stream, and that it sees no more value in a downstream rebuilder.

---

## What it changed

- The packages keep their open source licences.
  What changed is where the sources are published, and the agreement that comes with the portal.

- A free RHEL clone can no longer rebuild RHEL 1:1 from public sources.
  **Rocky Linux** and **AlmaLinux** both announced they would carry on, by different means, and AlmaLinux now describes itself as binary compatible with RHEL instead of a rebuild.

- To choose a distribution for a company, the licence is read together with who publishes the sources, and for how long the updates last.

- Sources: [Red Hat](https://www.redhat.com/en/blog/red-hats-commitment-open-source-response-gitcentosorg-changes), [AlmaLinux](https://almalinux.org/blog/impact-of-rhel-changes/), [CentOS](https://blog.centos.org/2020/12/future-is-centos-stream/).

---

## SUSE

- **SUSE Linux Enterprise Server (SLES)**: the commercial distribution, with a subscription.
  SLES 16.0 was released on 2025-11-04, SLES 16 is supported until 2035, with long term service until 2038, and SLES 15 SP7 until 2031.

- **openSUSE Leap**: the stable community distribution.
  **Tumbleweed** is its rolling release, which always has the latest versions.
  **MicroOS** and **Leap Micro** are small systems whose root filesystem is read only.

- Packages are `.rpm`, managed with `zypper`.

---

## Which one

Need                                 | Choice
-------------------------------------|-------------------------------------------------------------------------------------
Learning, servers, containers        | Debian, Ubuntu
Support contract, certified software | RHEL (or the compatible AlmaLinux and Rocky), SLES
Latest software on a desktop         | Fedora, Ubuntu, Tumbleweed, Arch
Smallest container image             | Alpine, built on musl and BusyBox, a container of at most 8 MB according to its site
