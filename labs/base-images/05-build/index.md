# Build on small bases

A Go program compiles to one static binary, so it is the cleanest case to see what a base image has to bring: nothing, or very little.
The same application is built here once, on seven different bases.

## The application

1. Write a small web server:

   ```bash exec target=docker
   mkdir -p ~/lab/hello && cd ~/lab/hello && \
   tee go.mod <<'EOT'
   module hello

   go 1.25
   EOT
   tee main.go <<'EOT'
   package main

   import (
   	"fmt"
   	"net/http"
   )

   func main() {
   	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
   		fmt.Fprintln(w, "Hello from a small image")
   	})
   	http.ListenAndServe(":8080", nil)
   }
   EOT
   ```

## A multi-stage Dockerfile

A multi-stage build has several `FROM`: the first stage holds the compiler and the sources, the last one starts from the base image and copies the result only.
What is not copied is not in the image.
`ARG BASE` makes the base image a parameter of the build:

1. Write the Dockerfile:

   ```bash exec target=docker
   cd ~/lab/hello && \
   tee Dockerfile <<EOT
   ARG BASE=scratch

   FROM ${GOLANG_IMAGE} AS build
   WORKDIR /src
   COPY go.mod ./
   RUN go mod download
   COPY main.go ./
   RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /hello .

   FROM \${BASE}
   COPY --from=build /hello /hello
   EXPOSE 8080
   ENTRYPOINT ["/hello"]
   EOT
   ```

   `CGO_ENABLED=0` makes the binary static: it needs no libc, so it runs on a base that has none.

2. Build it on each base.
   `scratch` is the empty image, the others are the ones of the previous steps:

   <!-- verify: requires=network timeout=900 -->

   ```bash exec target=docker
   cd ~/lab/hello && \
   build() { docker build -q --build-arg BASE="$2" -t "hello:$1" . > /dev/null; } && \
   build scratch scratch && \
   build distroless "${DISTROLESS_IMAGE}" && \
   build chainguard "${CHAINGUARD_IMAGE}" && \
   build alpine "${ALPINE_IMAGE}" && \
   build bci "${BCI_MICRO_IMAGE}" && \
   build ubi "${UBI_MICRO_IMAGE}" && \
   build debian "${DEBIAN_IMAGE}"
   ```

3. Compare the images, from the smallest to the largest.
   The application is the same 5 MB or so in each:

   <!-- verify: expect="hello:scratch" -->

   ```bash exec target=docker
   for t in scratch distroless chainguard alpine bci ubi debian; do docker image inspect "hello:$t" --format '{{.Size}} {{index .RepoTags 0}}'; done | sort -n | awk '{printf "%7.1f MB  %s\n", $1/1000000, $2}'
   ```

4. Compare with the stage that built it.
   The compiler and the sources stay in the first stage, which is not part of the result:

   <!-- verify: expect="golang:1.25-alpine" -->

   ```bash exec target=docker
   docker image inspect "${GOLANG_IMAGE}" --format '{{.Size}} {{index .RepoTags 0}}' | awk '{printf "%7.1f MB  %s\n", $1/1000000, $2}'
   ```

## Run it

1. The same binary answers on every base:

   <!-- verify: timeout=180 expect="Hello from a small image" -->

   ```bash exec target=docker
   for t in scratch distroless chainguard alpine bci ubi debian; do \
     docker run -d --name "hello-$t" -p 8081:8080 "hello:$t" > /dev/null; \
     for i in $(seq 1 10); do wget -qO- http://127.0.0.1:8081 && break; sleep 1; done; \
     docker rm -f "hello-$t" > /dev/null; \
   done
   ```

## No shell, no `exec`

1. Start the `scratch` and `distroless` images, and try to open a shell in the second:

   <!-- verify: timeout=60 expect="executable file not found" -->

   ```bash exec target=docker
   docker run -d --name hello -p 8081:8080 "hello:distroless" > /dev/null && \
   { docker exec hello sh || true; }
   ```

   The command fails on purpose: there is no `sh` in the image, and an attacker who gets into the process finds no tool either.

2. A tool is brought from outside, by a second container that shares the namespaces of the first:

   <!-- verify: expect="/hello" -->

   ```bash exec target=docker
   docker run --rm --pid=container:hello "${ALPINE_IMAGE}" ps
   ```

3. Remove it:

   ```bash exec target=docker
   docker rm -f hello
   ```

> [!NOTE]
> Google's distroless images have a `debug` tag that adds a busybox shell, for the days a shell is needed, and Docker Desktop and Docker Engine have `docker debug`, which attaches a toolbox the same way.
