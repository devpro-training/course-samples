# Summary

---

## Cheat sheet

Need                       | Option
---------------------------|-------------------------------------------------------------
Not root                   | `--user <uid>:<gid>`, or `USER` in the image
No capability              | `--cap-drop ALL`, then `--cap-add <one>` for each proof of need
No gain of rights          | `--security-opt no-new-privileges`
No writes                  | `--read-only --tmpfs /tmp`
Filter the system calls    | the default seccomp profile, never `seccomp=unconfined`
Never                      | `--privileged`, a mounted `docker.sock`, a bind mount of `/`
A secret at build          | `--secret id=<id>,src=<file>` and `RUN --mount=type=secret`
A secret at run            | a read-only file, or a manager, not `-e`
Closed network             | `docker network create --internal`, `-p 127.0.0.1:<port>:<port>`
A cap                      | `--pids-limit`, `--memory`, `--cpus`
Root that is not root      | `userns-remap`, rootless Docker, rootless Podman

---

## The limits, and what each ties to

Solution                 | Limit                                               | Tie
-------------------------|-----------------------------------------------------|--------------------------------
Options of `docker run`  | the application must work without the rights        | none, the same in Podman and Kubernetes
seccomp                  | a profile of the team is a file to maintain         | none, a feature of the kernel
AppArmor, SELinux        | one per distribution family, with its own language   | a distribution
User namespace, rootless | volumes, ports below 1024 and `--privileged` change | none
gVisor, Kata Containers  | compatibility and cost, or a virtual machine per workload | an open source runtime to run and update
Falco                    | detects, and an alert is not a block                | CNCF project, open source
NeuVector                | learns the behavior, then blocks it (prevention)     | open source (Apache 2.0), and supported by SUSE
Docker Bench for Security | checks a host against the CIS Docker Benchmark, and changes nothing | none, a shell script

- **Ask of every tool**: what does it prevent and what does it only detect, what does it need to run (root, a kernel feature, an agent), and how does a team leave it.

---

## To remember

- A container has the rights it is given, so give **none**, then add the ones the application proves it needs.

- Three things are a **gift of the host** to refuse by habit: `--privileged`, the Docker socket, and a bind mount wider than a directory of the application.

- A secret is **never** in an `ARG`, an `ENV`, or a layer.

- **Keep updating**: the kernel and the runtime are shared, and a fix of one is a fix for every container of the host.

- A hardened container is **checked** by a command (`docker inspect`), by a scanner, and by a tool that audits a host, such as Docker Bench for Security, which follows the CIS Docker Benchmark.

---

## Next

- Trivy: scan an image for vulnerabilities, misconfigurations and secrets.

- Kubernetes: the same controls as a `securityContext`, plus RBAC, network policies and admission.

- Zero trust and NeuVector: learn what a workload does, and allow only that.

- Further reading: [Docker security](https://docs.docker.com/engine/security/), [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html), [seccomp in Docker](https://docs.docker.com/engine/security/seccomp/), [user namespace remapping](https://docs.docker.com/engine/security/userns-remap/), [rootless mode](https://docs.docker.com/engine/security/rootless/), [Docker Bench for Security](https://github.com/docker/docker-bench-security).
