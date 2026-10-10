# Isolate and limit

## The risk

A container started with the defaults can reach the network of the host, every other container of the default network, and the Internet, and it can use all the processes and the memory of the machine.
A compromised container then scans the neighbors, sends data out, or starts a denial of service that stops the others.

## The default is open

1. Two containers on the default bridge network reach each other by address:

   <!-- verify: requires=network timeout=120 expect="exit 0" -->

   ```bash exec target=docker
   docker run -d --name server "${ALPINE_IMAGE}" sleep 120 > /dev/null && \
   ip=$(docker inspect server --format '{{.NetworkSettings.Networks.bridge.IPAddress}}') && \
   docker run --rm "${ALPINE_IMAGE}" ping -c 1 -W 2 "${ip}" > /dev/null; echo "exit $?"; \
   docker rm -f server > /dev/null
   ```

2. A network of its own limits it to the containers attached to it, and `--internal` has no route outside.
   A container of that network does not reach the Internet:

   <!-- verify: expect="bad address" -->

   ```bash exec target=docker
   docker network create --internal isolated > /dev/null && \
   { docker run --rm --network isolated "${ALPINE_IMAGE}" wget -T 3 -q -O /dev/null http://example.com || true; }
   ```

3. The default network reaches it:

   <!-- verify: requires=network timeout=60 expect="exit 0" -->

   ```bash exec target=docker
   docker run --rm "${ALPINE_IMAGE}" wget -T 10 -q -O /dev/null http://example.com; echo "exit $?"
   ```

   This is the zero trust reading of a network: the containers of an application share a network, and the ones that must send out are the exception, with a rule that says where.
   Docker has no filter of outgoing addresses per container, so the next level is a firewall of the host, or the network policies of Kubernetes.

## Published ports

1. `-p 8080:80` publishes the port on every interface of the host, and Docker adds its own firewall rules, which a firewall tool such as UFW does not see.
   The address of the host to publish on is part of the option:

   <!-- verify: requires=network timeout=120 expect="-> 0.0.0.0:8081" -->

   ```bash exec target=docker
   docker run -d --name open -p 8081:80 "${ALPINE_IMAGE}" sleep 60 > /dev/null && \
   docker port open && \
   docker rm -f open > /dev/null
   ```

2. `127.0.0.1:` before the port limits it to the machine itself, which is the choice for a database, or for an application behind a reverse proxy of the same host:

   <!-- verify: expect="-> 127.0.0.1:8082" -->

   ```bash exec target=docker
   docker run -d --name local -p 127.0.0.1:8082:80 "${ALPINE_IMAGE}" sleep 60 > /dev/null && \
   docker port local && \
   docker rm -f local > /dev/null
   ```

## Resources

A control group caps what a container uses, as the course Containers shows, and the same files are set by options.

1. A container that starts more processes than allowed is refused by the kernel, and the other containers are not hurt:

   <!-- verify: expect="can't fork" -->

   ```bash exec target=docker
   docker run --rm --pids-limit 20 "${ALPINE_IMAGE}" sh -c 'for i in $(seq 1 40); do sleep 5 & done 2>&1 | head -n 3'
   ```

2. `--memory` and `--cpus` do the same for memory and processor time, and `docker stats` shows what a container uses against its limits.
   A limit too low ends the application with status 137, so it is set from a measure.

## The limits

- **The default network of Docker is flat**: the isolation is a choice of the person who writes the Compose file or the command, and nothing warns when it is not made.

- **Between hosts**, the question is no longer Docker's: an orchestrator's policies, or a tool that learns the traffic of an application and then allows only that (the approach of NeuVector, the subject of a later course), do the same job at the scale of a cluster.

- **Resource limits protect the host, not the data**: a neighbor that is compromised still reads what it can reach.
