# Summary

---

## Cheat sheet

Idea                    | Means
------------------------|----------------------------------------------------------------------------
Infrastructure as Code  | the environment described in files that are versioned, reviewed and applied
Imperative              | the commands to run, in order
Declarative             | the final state, the tool finds the steps
Idempotent              | running it again gives the same result
Plan                    | the list of changes, with nothing changed yet
Apply                   | make the changes of the plan
State                   | what the tool remembers it manages
Drift                   | a difference between the code and the environment, made outside the tool
`trivy config <folder>` | scan Terraform, Kubernetes, Helm, Dockerfile... before anything exists
`--exit-code 1`         | fail the job on a finding of the chosen severity

---

## Good practices

- **Change the code, not the environment**, and when an emergency fix is made by hand, bring it back to the code the next day.

- **Read the plan**, in a review, before every apply.

- **Keep the state safe**: shared, locked, and out of the repository, since it can hold secrets.

- **Scan the code in the pipeline** with a gate that names the severities that fail the build.

- **Pin the version of the tool and of its providers**, since a tool has a licence, an owner and a roadmap that change.

- **Small files, one purpose each**, so a plan stays readable.

---

## Further reading

- [What is infrastructure as code](https://learn.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code), Microsoft Learn.
- [Terraform introduction](https://developer.hashicorp.com/terraform/intro), and [OpenTofu](https://opentofu.org/docs/intro/).
- [Ansible glossary](https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html) and [check mode](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html).
- [What is Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview).
- [Sensitive data in state](https://developer.hashicorp.com/terraform/language/state/sensitive-data).
- [Trivy: IaC coverage](https://trivy.dev/docs/latest/guide/coverage/iac/).
- [IBM completes acquisition of HashiCorp](https://newsroom.ibm.com/2025-02-27-ibm-completes-acquisition-of-hashicorp,-creates-comprehensive,-end-to-end-hybrid-cloud-platform), 27 February 2025.

---

## Next

- Terraform: the same workflow with the real tool, its providers and its state.
