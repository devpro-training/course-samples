# Compose

Docker Compose describes several containers, their networks and volumes in one file, and starts them with one command.

## The file

1. Write a `compose.yaml` of two services: the site of the previous step, and a cache.
   Compose creates a network for the project, so the services reach each other by name:

   ```bash exec target=docker
   mkdir -p ~/lab/stack && cd ~/lab/stack && \
   tee compose.yaml <<EOT
   services:
     web:
       image: site:2
       ports:
         - "8082:80"
     cache:
       image: ${REDIS_IMAGE}
   EOT
   ```

## Up and down

1. Start both services in the background:

   <!-- verify: requires=network timeout=180 expect="stack-web-1" -->

   ```bash exec target=docker
   cd ~/lab/stack && \
   docker compose up -d 2>&1 | grep Started ; \
   docker compose ps --format "{{.Name}} {{.Status}}"
   ```

2. Ask the web service through its published port:

   <!-- verify: timeout=60 expect="Version 2" -->

   ```bash exec target=docker
   for i in $(seq 1 10); do wget -qO- http://127.0.0.1:8082 && break; sleep 1; done
   ```

3. The web container resolves the cache by the name of its service.
   `-T` runs the command without a pseudo-terminal, which a script that reads its output needs:

   <!-- verify: timeout=60 expect="Name:" -->

   ```bash exec target=docker
   cd ~/lab/stack && \
   docker compose exec -T web nslookup cache
   ```

4. Stop and remove the containers and the network, in one command:

   <!-- verify: expect="stack_default" -->

   ```bash exec target=docker
   cd ~/lab/stack && \
   docker compose down 2>&1
   ```

> [!TIP]
> A volume of the file survives `docker compose down`, and `--volumes` removes it as well.
