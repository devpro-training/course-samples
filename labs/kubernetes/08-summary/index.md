# Summary

---

## Cheat sheet

Command                                          | Does
-------------------------------------------------|------------------------------------------------------
`kubectl get nodes`, `get pods -A`               | The nodes, the Pods of every namespace
`kubectl apply -f <file>`                        | Moves the cluster to what the file declares
`kubectl get <kind> [-o wide\|yaml\|jsonpath=...]` | Lists objects, or prints their actual state
`kubectl describe <kind> <name>`                 | The object and its events
`kubectl logs <pod>`, `exec <pod> -- <command>`  | The output of a container, a command in it
`kubectl wait --for=condition=Ready <kind>/<n>`  | Returns when the condition is true
`kubectl scale deployment <n> --replicas=<k>`    | Changes the number of Pods
`kubectl rollout status\|history\|undo deployment/<n>` | Follows, lists and reverts a rollout
`kubectl delete -f <file>`, `delete <kind> <n>`  | Removes objects
`kubectl api-resources`                          | The kinds of objects the API knows

---

## The ideas

- **Declare, do not command**: the manifest is the desired state, and the controllers work until the actual state matches it.

- **Everything is an object of the API**: Pods, Deployments, Services, ConfigMaps and Secrets are all read and written the same way.

- **A Pod is disposable**: a Deployment replaces it, a Service hides its address, and nothing depends on one Pod.

- **Labels and selectors** link the objects: a Deployment to its Pods, a Service to its backends.

- **A distribution is Kubernetes with the choices made**: k3s keeps the API, and changes the packaging and the datastore.

---

## Good practices

- Keep the manifests in a Git repository, and apply from there: the cluster should never be the only copy of what runs.

- Pin the tag of an image, and move it through a rolling update: `latest` hides what runs.

- Run at least two replicas of what must stay up, and say when a Pod is ready with a readiness probe.

- A Secret is encoded, not encrypted: limit who can read it, and enable encryption at rest.

- Choose a distribution or a managed service for what the team can operate, and write down the upgrade path.

---

## Next

- k3s: the distribution in depth, several servers and agents, the datastore and the upgrade.

- k3d: k3s clusters in containers, for development.

- Ingress controller: one address for many Services.

- Further reading: [Kubernetes documentation](https://kubernetes.io/docs/home/), [Kubernetes concepts](https://kubernetes.io/docs/concepts/), [k3s documentation](https://docs.k3s.io/) and [the CNCF landscape](https://landscape.cncf.io/).
