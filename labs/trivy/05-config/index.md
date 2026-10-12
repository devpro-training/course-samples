# Config

`trivy config` reads the files that describe how something runs: Dockerfile, Kubernetes manifests, Helm charts, Terraform, CloudFormation and others.
Its checks are Rego policies, downloaded as an OCI artifact like the vulnerability database.

## A Dockerfile and a manifest

1. Create both, with the defaults most examples show:

   ```bash exec
   mkdir -p ~/lab/config && cd ~/lab/config && \
   cat > Dockerfile <<'DOCKERFILE'
   FROM alpine:3.22
   RUN apk add --no-cache python3
   COPY . /app
   CMD ["python3", "/app/main.py"]
   DOCKERFILE
   cat > deployment.yaml <<'MANIFEST'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: web
     template:
       metadata:
         labels:
           app: web
       spec:
         containers:
           - name: web
             image: nginx:latest
             securityContext:
               privileged: true
   MANIFEST
   ```

   [Open Dockerfile](:open:config/Dockerfile)
   [Open deployment.yaml](:open:config/deployment.yaml)

2. Scan the folder, for the high and critical findings:

   <!-- verify: requires=network timeout=240 expect="KSV-0017" -->

   ```bash exec
   cd ~/lab/config && \
   trivy config --severity HIGH,CRITICAL . 2>&1 | grep -E "^(DS|KSV)-"
   ```

   Each finding has an identifier, a severity, and a page that explains the risk and the fix.
   They are the risks of the Container security course: a container that runs as root, one that is privileged, and a file system that is writable.

## Fix

1. Rewrite the two files with what the findings ask for:

   ```bash exec
   cd ~/lab/config && \
   cat > Dockerfile <<'DOCKERFILE'
   FROM alpine:3.22
   RUN apk add --no-cache python3 && adduser -D -u 10001 app
   COPY . /app
   USER app
   HEALTHCHECK CMD ["python3", "--version"]
   CMD ["python3", "/app/main.py"]
   DOCKERFILE
   cat > deployment.yaml <<'MANIFEST'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: web
     template:
       metadata:
         labels:
           app: web
       spec:
         securityContext:
           runAsNonRoot: true
           runAsUser: 10001
           seccompProfile:
             type: RuntimeDefault
         containers:
           - name: web
             image: nginx:1.29-alpine
             securityContext:
               privileged: false
               allowPrivilegeEscalation: false
               readOnlyRootFilesystem: true
               capabilities:
                 drop: ["ALL"]
   MANIFEST
   ```

2. Scan again, as a gate that fails on a high or critical finding:

   <!-- verify: expect="status 0" -->

   ```bash exec
   cd ~/lab/config && \
   trivy config --severity HIGH,CRITICAL --exit-code 1 . > /dev/null 2>&1; \
   echo "status $?"
   ```

   Status 0 says the files follow the checks of Trivy, not that the application works under them: a read-only file system needs a volume for what the application writes.
