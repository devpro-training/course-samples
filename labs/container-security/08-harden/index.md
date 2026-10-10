# Deny by default

The options of the previous steps are combined in one command, then the root of the container is made a user of the host.

## One command

1. A web server made to run as a user that is not root, started with nothing it does not need:

   Option                           | Denies
   ---------------------------------|----------------------------------------------
   `--user 101:101`                 | root
   `--cap-drop ALL`                 | every capability
   `--security-opt no-new-privileges` | a gain of rights through `setuid`
   `--read-only --tmpfs /tmp`       | writes, but for a temporary directory
   `--pids-limit 100 --memory 128m` | a runaway process
   `-p 127.0.0.1:8080:8080`         | access from other machines

   <!-- verify: requires=network timeout=180 -->

   ```bash exec target=docker
   docker run -d --name web \
     --user 101:101 --cap-drop ALL --security-opt no-new-privileges \
     --read-only --tmpfs /tmp \
     --pids-limit 100 --memory 128m \
     -p 127.0.0.1:8080:8080 \
     "${NGINX_UNPRIVILEGED_IMAGE}" > /dev/null
   ```

2. It answers:

   <!-- verify: timeout=60 expect="Welcome to nginx" -->

   ```bash exec target=docker
   for i in $(seq 1 15); do wget -qO- http://127.0.0.1:8080 && break; sleep 1; done
   ```

3. The settings are in the configuration of the container, which a review, or a script, can check:

   <!-- verify: expect="user=101:101" -->

   ```bash exec target=docker
   docker inspect web --format 'user={{.Config.User}} readonly={{.HostConfig.ReadonlyRootfs}} drop={{.HostConfig.CapDrop}} opt={{.HostConfig.SecurityOpt}}'
   ```

4. Inside, the process holds nothing:

   <!-- verify: expect="0000000000000000" -->

   ```bash exec target=docker
   docker exec web grep CapEff /proc/self/status
   ```

5. The image was chosen for this: it listens on 8080, which a user may bind, and it writes where `--tmpfs` allows.
   The ordinary `nginx` image needs root and three capabilities for its first steps, which `--cap-add CHOWN --cap-add SETGID --cap-add SETUID` give back, and that is one more list to keep.

6. Remove it:

   ```bash exec target=docker
   docker rm -f web
   ```

## A root that is not root

Whatever is dropped, a process that escapes as root in the container is root on the host.
A **user namespace** maps the user numbers of the container to others on the host: root of the container becomes an unprivileged number outside.

1. Ask the daemon to remap, with the user `dockremap` that it creates, and restart it.
   The machine runs no init system, so the daemon is stopped and started by hand:

   ```bash exec target=docker
   mkdir -p /etc/docker && \
   echo '{ "userns-remap": "default" }' > /etc/docker/daemon.json && \
   pkill -f "^dockerd" ; sleep 3 ; \
   nohup dockerd > /var/log/dockerd.log 2>&1 &
   ```

   <!-- verify: expect="name=userns" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do docker info > /dev/null 2>&1 && break; sleep 1; done; \
   docker info --format '{{.SecurityOptions}}'
   ```

2. The range of numbers given to it:

   <!-- verify: expect="dockremap:100000:65536" -->

   ```bash exec target=docker
   grep dockremap /etc/subuid
   ```

3. A container shows itself as root, and the host sees the process under a number with no right:

   <!-- verify: requires=network timeout=120 expect="100000" -->

   ```bash exec target=docker
   docker run -d --name remapped "${ALPINE_IMAGE}" sleep 60 > /dev/null && \
   docker exec remapped id -u && \
   ps -o user:12,pid,args -C sleep && \
   docker rm -f remapped > /dev/null
   ```

4. The same root can no longer write to a directory of the real root:

   <!-- verify: requires=network timeout=60 expect="Permission denied" -->

   ```bash exec target=docker
   { docker run --rm -v ~/lab/host:/data "${ALPINE_IMAGE}" sh -c 'echo again >> /data/secret.txt' || true; }
   ```

## The limits

- **The daemon still runs as root** with `userns-remap`, and **rootless mode** removes that too, at the price of its own restrictions: the documentation lists the ones to check against the workload.

- **Existing images and containers are hidden** when remapping is enabled, and come back when it is disabled: it is a decision of the installation, not an option of a command.

- **Incompatible with `--privileged`**, `--network host` and `--pid host` unless `--userns=host` is given for that container, and a bind mount needs files owned by the mapped range.

- **Podman** runs rootless by default, with the same idea, and Kubernetes has user namespaces for pods as a feature that the cluster must enable.
