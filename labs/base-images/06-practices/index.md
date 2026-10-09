# Best practices

Three habits go with the choice of a small base: the order of the layers, a user that is not root, and a base that is pinned.

## Layers and the cache

Docker reuses a layer when its instruction and every one before it are unchanged.
What changes rarely goes first, what changes often goes last.

1. Write a Dockerfile in the wrong order: the sources are copied before the dependencies are downloaded:

   ```bash exec target=docker
   cd ~/lab/hello && \
   tee Dockerfile.bad <<EOT
   FROM ${GOLANG_IMAGE} AS build
   WORKDIR /src
   COPY . .
   RUN go mod download
   RUN CGO_ENABLED=0 go build -o /hello .

   FROM scratch
   COPY --from=build /hello /hello
   ENTRYPOINT ["/hello"]
   EOT
   ```

2. Build both Dockerfiles, change the source, and build both again, counting the steps that were reused:

   <!-- verify: timeout=300 expect="3 steps reused, dependencies first" -->

   ```bash exec target=docker
   cd ~/lab/hello && \
   docker build -q -f Dockerfile.bad -t hello:bad . > /dev/null && \
   docker build -q -t hello:good . > /dev/null && \
   sed -i 's/small image/small image, version 2/' main.go && \
   echo "$(docker build --progress=plain -f Dockerfile.bad -t hello:bad . 2>&1 | grep -c CACHED) steps reused, sources first" && \
   echo "$(docker build --progress=plain -t hello:good . 2>&1 | grep -c CACHED) steps reused, dependencies first"
   ```

   The dependencies layer is rebuilt every time a source file changes in the first Dockerfile, and reused in the second.
   A `.dockerignore` file keeps the files an image does not need (`.git`, test data, secrets) out of the build context, so they cannot invalidate a `COPY` or end up in a layer.

## A user that is not root

A process that runs as root in a container is root on the files it can reach, and the first step of many escapes.
The `nonroot` variant of distroless sets the user 65532, and any image can do the same.

1. Run the application on `bci-micro`, which runs as root by default, and ask for the user of the process:

   <!-- verify: timeout=60 expect="user=root" -->

   ```bash exec target=docker
   docker run -d --name as-root hello:bci > /dev/null && sleep 1 && \
   docker top as-root -o pid,user,args | awk 'NR > 1 {print "user=" $2}' && \
   docker rm -f as-root > /dev/null
   ```

2. Add the user to the Dockerfile.
   `COPY --chown` gives the binary to it, and `USER` switches to it:

   ```bash exec target=docker
   cd ~/lab/hello && \
   tee Dockerfile.user <<EOT
   FROM ${GOLANG_IMAGE} AS build
   WORKDIR /src
   COPY go.mod ./
   RUN go mod download
   COPY main.go ./
   RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /hello .

   FROM ${BCI_MICRO_IMAGE}
   COPY --from=build --chown=65532:65532 /hello /hello
   USER 65532:65532
   EXPOSE 8080
   ENTRYPOINT ["/hello"]
   EOT
   ```

3. Build, run it, and ask again.
   The port is above 1024, so no privilege is needed to listen on it:

   <!-- verify: timeout=120 expect="user=65532" -->

   ```bash exec target=docker
   cd ~/lab/hello && \
   docker build -q -f Dockerfile.user -t hello:user . > /dev/null && \
   docker run -d --name as-user hello:user > /dev/null && sleep 1 && \
   docker top as-user -o pid,user,args | awk 'NR > 1 {print "user=" $2}' && \
   docker rm -f as-user > /dev/null
   ```

4. A container can also lose the rights it does not use: a read-only filesystem, and no Linux capabilities:

   <!-- verify: timeout=60 expect="Hello from a small image" -->

   ```bash exec target=docker
   docker run -d --name locked --read-only --cap-drop ALL -p 8081:8080 hello:user > /dev/null && \
   for i in $(seq 1 10); do wget -qO- http://127.0.0.1:8081 && break; sleep 1; done; \
   docker rm -f locked > /dev/null
   ```

## A base that is pinned

A tag is a name the publisher moves: `alpine:3.22` is a different image after each patch release.
A digest is the hash of the content, which never changes.

1. Read the digest of a base image, and build on it:

   <!-- verify: timeout=120 expect="sha256:" -->

   ```bash exec target=docker
   cd ~/lab/hello && \
   digest=$(docker buildx imagetools inspect "${ALPINE_IMAGE}" --format '{{.Manifest.Digest}}') && \
   echo "${digest}" && \
   docker build -q --build-arg BASE="docker.io/library/alpine@${digest}" -t hello:pinned . > /dev/null && \
   docker images hello:pinned --format '{{.Repository}}:{{.Tag}}'
   ```

   The build is the same today and in a year, and an update becomes a change in a file, which a tool such as Dependabot or Renovate proposes as a pull request.
   The price is the same: nobody updates the base for the team.
