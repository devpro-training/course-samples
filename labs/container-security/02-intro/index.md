# Container security

A practical guide: what can go wrong with a container, why, and what to switch off.

---

## The goal

- **Practical**: each step shows a risk that works, the logic behind it, and the option that closes it.

- **Open source tools**, and the standard features of Docker Engine and of the Linux kernel, so nothing here needs a licence.

- **No product pitch**: every solution comes with its limits, and with what it ties the team to.

- **Not exhaustive**: the lab covers the container itself, and the next courses cover the image scan (Trivy), the cluster (Kubernetes) and the runtime protection (Zero trust, NeuVector).

---

## A container is not a boundary by itself

- A container is a **process** of the host, in namespaces and a cgroup, as the Containers course shows.

- It shares the **kernel** of the host, so what the kernel allows to the process is what the container can do.

- A container run with the defaults is **allowed more than it needs**: root, fourteen capabilities, the writable disk, the network.

- Security here means the reverse of the defaults: **deny everything, then allow what the application needs**.

---

## Where it is attacked

![The four places a container is attacked, and the control of each: build, distribute, run, kernel and host](../assets/container-security-dark.svg#gh-dark-mode-only)
![The four places a container is attacked, and the control of each: build, distribute, run, kernel and host](../assets/container-security.svg#gh-light-mode-only)

---

## The lifecycle of an image

- The Kubernetes documentation on cloud native security follows the lifecycle of the CNCF: **develop**, **distribute**, **deploy** and **runtime**.

- A weakness at one stage reaches the next: a secret written in a layer is in every container, a base with known vulnerabilities runs in production.

- An older model of the same documentation stacks four layers, **cloud**, **cluster**, **container** and **code**, each one relying on the outer one.

- This lab works on the container layer, on one machine: a cluster adds its own controls on top, and cannot remove the need for these.

- Reference: [Cloud native security and Kubernetes](https://kubernetes.io/docs/concepts/security/cloud-native-security/).

---

## Principles

- **Least privilege**: a process gets the rights it needs, and no more.

- **Zero trust**: nothing is trusted because of where it runs, every right is granted on purpose, and an unexpected behavior is a signal.

- **Reduce the surface**: what is not in the container cannot be used against it, a shell, a package manager, a capability, a mounted socket.

- **Prevent, then detect**: a control that refuses an action is worth more than an alert after it, and both are needed, since a prevention rule always has a gap.

---

## The rules of this lab

The OWASP Docker Security Cheat Sheet is the checklist the lab follows, rule by rule.

Rule | Title                                    | Step
-----|------------------------------------------|----------------
#0   | Keep the host and Docker up to date      | summary
#1   | Do not expose the Docker daemon socket   | Host
#2   | Set a user                               | User
#3   | Limit capabilities                       | User
#4   | Prevent in-container privilege escalation | User
#5   | Be mindful of inter-container connectivity | Network
#6   | Use a Linux Security Module (seccomp, AppArmor, SELinux) | Kernel
#7   | Limit resources                          | Network
#8   | Set filesystem and volumes to read-only  | User, Host
#9   | Integrate container scanning tools in CI/CD | summary, Trivy
#11  | Run Docker in rootless mode              | Deny by default
#12  | Use secrets for sensitive data           | Secrets
#13  | Enhance supply chain security            | summary, Application catalog

---

## In this lab

Step            | Risk                                  | Control
----------------|---------------------------------------|--------------------------------------------
User            | root and fourteen capabilities        | `--user`, `--cap-drop ALL`, `--read-only`, `no-new-privileges`
Kernel          | a flaw reached through a system call  | seccomp, and what `--privileged` removes
Host            | the socket and the bind mounts        | no socket, `:ro`
Secrets         | a token in a layer or in the inspect  | `--mount=type=secret`, a file
Network         | open network and no limit             | internal network, `127.0.0.1`, `--pids-limit`
Deny by default | all of them at once                   | one `docker run`, then a user namespace

> Every command of this lab is run as root in a disposable virtual machine.
> On a real host, `docker` is reserved to administrators, since the step Host shows why.
