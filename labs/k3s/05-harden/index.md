# Harden and measure

The Center for Internet Security (CIS) publishes a benchmark of Kubernetes settings.
k3s passes many of its checks with the defaults, and the k3s documentation has a hardening guide for the others.
[kube-bench](https://github.com/aquasecurity/kube-bench) runs the checks of the benchmark against a node, so the effect of each change is measured.

## Measure

1. Download kube-bench, compare it with the checksums of its release, and install it with its profiles:

   <!-- verify: requires=network timeout=240 expect="OK" -->

   ```bash exec target=kube
   mkdir -p ~/lab/bench && cd ~/lab/bench && \
   wget -q "${KUBEBENCH_URL}/${KUBEBENCH_VERSION}/kube-bench_${KUBEBENCH_VERSION#v}_linux_amd64.tar.gz" \
         "${KUBEBENCH_URL}/${KUBEBENCH_VERSION}/kube-bench_${KUBEBENCH_VERSION#v}_checksums.txt" && \
   sha256sum --check --ignore-missing kube-bench_*_checksums.txt && \
   mkdir -p /etc/kube-bench && \
   tar -xzf kube-bench_*_linux_amd64.tar.gz -C /usr/local/bin kube-bench && \
   tar -xzf kube-bench_*_linux_amd64.tar.gz -C /etc/kube-bench cfg && \
   ls /etc/kube-bench/cfg | grep k3s
   ```

2. The checks need two things this machine does not have.
   The ones on the API server read the flags that k3s logged when it started, with `journalctl -u k3s`, and there is no systemd and no journal, so a stand-in prints the log file of the lab.
   The ones on roles filter JSON with `jq`.
   Without them the checks fail whatever the configuration:

   <!-- verify: requires=network timeout=240 expect="jq-1." -->

   ```bash exec target=kube
   tee /usr/local/bin/journalctl <<'EOT'
   #!/bin/sh
   cat /var/log/k3s.log
   EOT
   chmod +x /usr/local/bin/journalctl && \
   DEBIAN_FRONTEND=noninteractive apt-get update -q > /dev/null && \
   DEBIAN_FRONTEND=noninteractive apt-get install -y -q jq > /dev/null && \
   jq --version
   ```

3. Run the benchmark of k3s on this node, and keep the report.
   The profile is named: `k3s-cis-1.9` is the newest k3s profile of this release, and the benchmark version the hardening guide mentions:

   <!-- verify: timeout=180 expect="checks PASS" -->

   ```bash exec target=kube
   cd ~/lab/bench && \
   kube-bench run --benchmark "${KUBEBENCH_PROFILE}" --config-dir /etc/kube-bench/cfg --config /etc/kube-bench/cfg/config.yaml > before.txt 2>&1; \
   grep -A5 "== Summary total" before.txt
   ```

4. Each check is `PASS`, `FAIL`, `WARN` (to review by hand) or `INFO`.
   A failed check comes with its remediation:

   <!-- verify: expect="[FAIL]" -->

   ```bash exec target=kube
   cd ~/lab/bench && grep "^\[FAIL\]" before.txt | head -n 12
   ```

## Harden

The guide changes the host, the options of k3s, the policies of the cluster and the permissions of a few files.
Everything is a file, which can be kept in Git and applied to every node.

1. The kubelet exits when a kernel parameter differs from what it expects, with `protect-kernel-defaults`, so the host is set first:

   <!-- verify: expect="kernel.panic = 10" -->

   ```bash exec target=kube
   tee /etc/sysctl.d/90-kubelet.conf <<'EOT'
   vm.panic_on_oom=0
   vm.overcommit_memory=1
   kernel.panic=10
   kernel.panic_on_oops=1
   EOT
   sysctl -p /etc/sysctl.d/90-kubelet.conf
   ```

2. An audit policy that records the metadata of every request, and the admission configuration of the guide.
   The guide enforces the `restricted` Pod Security Standard, which refuses a Pod that runs as root with its default capabilities, as the images of this lab do,
   so this lab enforces `baseline` and keeps `restricted` for the warnings and the audit:

   ```bash exec target=kube
   mkdir -p -m 700 /var/lib/rancher/k3s/server/logs && \
   tee /var/lib/rancher/k3s/server/audit.yaml <<'EOT'
   apiVersion: audit.k8s.io/v1
   kind: Policy
   rules:
     - level: Metadata
   EOT
   tee /var/lib/rancher/k3s/server/psa.yaml <<'EOT'
   apiVersion: apiserver.config.k8s.io/v1
   kind: AdmissionConfiguration
   plugins:
     - name: PodSecurity
       configuration:
         apiVersion: pod-security.admission.config.k8s.io/v1beta1
         kind: PodSecurityConfiguration
         defaults:
           enforce: "baseline"
           enforce-version: "latest"
           audit: "restricted"
           audit-version: "latest"
           warn: "restricted"
           warn-version: "latest"
         exemptions:
           usernames: []
           runtimeClasses: []
           namespaces: [kube-system]
   EOT
   ```

3. The options of the guide go in a second file of the folder `config.yaml.d`, which is read after `config.yaml`, so the file of the previous step stays as it is.
   The `EventRateLimit` plugin of the guide is left out, since it needs limits of its own:

   ```bash exec target=kube
   mkdir -p /etc/rancher/k3s/config.yaml.d && \
   tee /etc/rancher/k3s/config.yaml.d/90-hardening.yaml <<'EOT'
   protect-kernel-defaults: true
   secrets-encryption: true
   kube-apiserver-arg:
     - 'admission-control-config-file=/var/lib/rancher/k3s/server/psa.yaml'
     - 'audit-log-path=/var/lib/rancher/k3s/server/logs/audit.log'
     - 'audit-policy-file=/var/lib/rancher/k3s/server/audit.yaml'
     - 'audit-log-maxage=30'
     - 'audit-log-maxbackup=10'
     - 'audit-log-maxsize=100'
     - 'service-account-extend-token-expiration=false'
   kube-controller-manager-arg:
     - 'terminated-pod-gc-threshold=100'
   kubelet-arg:
     - 'streaming-connection-idle-timeout=5m'
   EOT
   ```

   [The hardening guide](https://docs.k3s.io/security/hardening-guide) has the complete block, with the TLS cipher suites of the kubelet.

4. The certificates are readable by their owner only (check 1.1.20), then restart the server:

   ```bash exec target=kube
   chmod -R 600 /var/lib/rancher/k3s/server/tls/*.crt && \
   pkill -f "^k3s server"; sleep 5
   ```

   ```bash exec target=kube
   nohup k3s server > /var/log/k3s.log 2>&1 &
   ```

5. Wait for the node, then check that the secrets are encrypted:

   <!-- verify: timeout=240 expect="Encryption Status: Enabled" -->

   ```bash exec target=kube
   until k3s secrets-encrypt status > /dev/null 2>&1; do sleep 3; done; \
   k3s secrets-encrypt status
   ```

## What changed

1. A Secret is now stored encrypted in the datastore.
   The value in the SQLite file starts with the provider that encrypted it, and the password is not in it:

   <!-- verify: expect="k8s:enc:aescbc" -->

   ```bash exec target=kube
   kubectl create secret generic db --from-literal=PASSWORD=s3cr3t-pass && python3 - <<'EOT'
   import sqlite3
   db = sqlite3.connect("file:/var/lib/rancher/k3s/server/db/state.db?mode=ro", uri=True)
   name, value = db.execute("select name, value from kine where name = '/registry/secrets/default/db' order by id desc limit 1").fetchone()
   print(name, value[:19], b"s3cr3t-pass" in value)
   EOT
   ```

2. A Pod that asks for the host is refused by the admission configuration, before it is created:

   <!-- verify: expect="violates PodSecurity" -->

   ```bash exec target=kube
   { kubectl run intruder --image="${BUSYBOX_IMAGE}" --privileged -- sleep 60 || true; } 2>&1
   ```

3. The guide also lists controls that no option can set.
   Check 5.1.5 asks that the default service account of each namespace does not mount its token into the Pods:

   <!-- verify: expect="serviceaccount/default patched" -->

   ```bash exec target=kube
   for ns in default kube-node-lease kube-public; do kubectl patch serviceaccount default --namespace "${ns}" --patch '{"automountServiceAccountToken": false}'; done
   ```

4. The audit log records every request of the API server:

   <!-- verify: expect="Metadata" -->

   ```bash exec target=kube
   tail -n 1 /var/lib/rancher/k3s/server/logs/audit.log | cut -c1-200
   ```

## Measure again

1. Run the benchmark a second time, and compare the summaries:

   <!-- verify: timeout=180 expect="checks PASS" -->

   ```bash exec target=kube
   cd ~/lab/bench && \
   kube-bench run --benchmark "${KUBEBENCH_PROFILE}" --config-dir /etc/kube-bench/cfg --config /etc/kube-bench/cfg/config.yaml > after.txt 2>&1; \
   grep -h -A5 "== Summary total" before.txt after.txt
   ```

2. What still fails:

   <!-- verify: expect="[FAIL]" -->

   ```bash exec target=kube
   cd ~/lab/bench && grep "^\[FAIL\]" after.txt | head -n 12
   ```

   Neither is a setting of k3s.
   Check 1.2.26 asks for an etcd certificate authority, and this cluster has no etcd, since its datastore is SQLite.
   Check 5.1.6 is about workloads: a Pod mounts a service account token it does not need unless its own spec says `automountServiceAccountToken: false`.
   The checks marked `WARN` are manual, and are reviewed by a person.
