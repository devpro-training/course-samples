# Keep secrets out of images

## The risk

An image is shared: it goes to a registry, to a cache, to every machine that pulls it.
A token written in a layer is readable by everyone who can read the image, and deleting the file in a later layer does not remove it from the earlier one.

## A build argument

1. A Dockerfile that receives a token as an argument, uses it, and removes the file:

   ```bash exec target=docker
   mkdir -p ~/lab/secrets && cd ~/lab/secrets && \
   echo "s3cr3t-token" > token.txt && \
   tee Dockerfile.arg <<EOT
   FROM ${ALPINE_IMAGE}
   ARG TOKEN
   RUN echo "\${TOKEN}" > /etc/app.conf && rm /etc/app.conf
   EOT
   ```

2. Build it.
   The history of the image, which anyone who pulls it can read, keeps the value:

   <!-- verify: requires=network timeout=120 expect="lines with the token: 2" -->

   ```bash exec target=docker
   cd ~/lab/secrets && \
   docker build -q --build-arg TOKEN="$(cat token.txt)" -f Dockerfile.arg -t leak:arg . > /dev/null && \
   echo "lines with the token: $(docker history --no-trunc leak:arg | grep -c 's3cr3t-token')"
   ```

   The documentation of Docker says the same: build arguments and environment variables persist in the final image.

## A secret mount

1. `--secret` gives the build a file, which `RUN --mount=type=secret` mounts for the duration of that instruction only, at `/run/secrets/<id>`:

   ```bash exec target=docker
   cd ~/lab/secrets && \
   tee Dockerfile.secret <<EOT
   FROM ${ALPINE_IMAGE}
   RUN --mount=type=secret,id=token wc -c < /run/secrets/token
   EOT
   ```

2. The build uses the token, and the image does not hold it:

   <!-- verify: timeout=120 expect="lines with the token: 0" -->

   ```bash exec target=docker
   cd ~/lab/secrets && \
   docker build -q --secret id=token,src=token.txt -f Dockerfile.secret -t leak:secret . > /dev/null && \
   echo "lines with the token: $(docker history --no-trunc leak:secret | grep -c 's3cr3t-token')"
   ```

3. Nor does a container of it, which has no `/run/secrets` directory:

   <!-- verify: expect="No such file" -->

   ```bash exec target=docker
   { docker run --rm leak:secret ls /run/secrets || true; }
   ```

## A secret at runtime

1. An environment variable is simple, and shows in the configuration of the container, for everyone who can use Docker, and in the page of a crash of the application that prints its environment:

   <!-- verify: expect="[DB_PASSWORD" -->

   ```bash exec target=docker
   docker run -d --name app -e DB_PASSWORD=hunter2 "${ALPINE_IMAGE}" sleep 60 > /dev/null && \
   docker inspect app --format '{{.Config.Env}}' && \
   docker rm -f app > /dev/null
   ```

2. A file, mounted read-only, is not part of the configuration, and the application reads it from a path:

   <!-- verify: expect="hunter2 read from" -->

   ```bash exec target=docker
   cd ~/lab/secrets && \
   echo "hunter2" > db_password && chmod 0444 db_password && \
   docker run --rm --mount type=bind,src="$PWD/db_password",dst=/run/secrets/db_password,ro "${ALPINE_IMAGE}" \
     sh -c 'echo "$(cat /run/secrets/db_password) read from a file"'
   ```

## The limits

- **A file on the host is still readable by whoever is root there**: it moves the secret out of the image and out of the configuration, not out of reach of the administrators.

- **A manager of secrets** (HashiCorp Vault, its open source fork OpenBao, the secret stores of the clouds, Kubernetes Secrets) gives rotation, access control and an audit.
  Each one is a dependency: the application reads from it, and a switch is a change of code or of configuration.

- **A secret that was in an image is lost**: it is rotated, and the image is deleted from every registry.

- **A scan finds them**: Trivy, in the next course, looks for secrets in the files of an image.
