# Run a container

`docker run` creates a container from an image and starts it.
The image is pulled from the registry first when the daemon does not have it.

## In the background

1. Start a web server.
   `-d` detaches the container, `--name` names it, and `-p 8080:80` publishes port 80 of the container on port 8080 of the machine:

   <!-- verify: requires=network timeout=120 -->

   ```bash exec target=docker
   docker run -d --name web -p 8080:80 "${NGINX_IMAGE}"
   ```

2. List the running containers:

   <!-- verify: expect="0.0.0.0:8080->80/tcp" -->

   ```bash exec target=docker
   docker ps
   ```

3. Ask the server, through the published port.
   The published port accepts connections before nginx is ready, so the command tries again until it gets an answer.
   The address is `127.0.0.1`, since this machine does not resolve `localhost`:

   <!-- verify: timeout=60 expect="Welcome to nginx!" -->

   ```bash exec target=docker
   for i in $(seq 1 10); do wget -qO- http://127.0.0.1:8080 && break; sleep 1; done
   ```

4. Read the log of the container, which is what the process wrote to its output:

   <!-- verify: expect="GET / HTTP/1.1" -->

   ```bash exec target=docker
   docker logs web | tail -n 3
   ```

## Inside

1. Run a command in the running container.
   The process sees its own filesystem, and its own process list, where nginx is process 1:

   <!-- verify: expect="nginx version: nginx/1.29" -->

   ```bash exec target=docker
   docker exec web nginx -v && \
   docker exec web ps
   ```

2. The machine sees the same processes with other numbers, since a container is a process of the host:

   <!-- verify: expect="nginx: master process" -->

   ```bash exec target=docker
   ps -eo pid,args | grep "[n]ginx: master"
   ```

3. Show the memory the container uses, which the kernel counts for its cgroup:

   <!-- verify: expect="MiB /" -->

   ```bash exec target=docker
   docker stats --no-stream --format "{{.Name}} {{.MemUsage}}" web
   ```

## Stop and remove

1. A stopped container is kept, with its state, until it is removed:

   <!-- verify: expect="web Exited" -->

   ```bash exec target=docker
   docker stop web && \
   docker ps -a --format "{{.Names}} {{.Status}}"
   ```

2. Remove it, and the machine has no container left:

   <!-- verify: expect="CONTAINER ID" -->

   ```bash exec target=docker
   docker rm web && \
   docker ps -a
   ```

> [!TIP]
> `docker run --rm` removes the container as soon as it exits, which suits a command run once.
