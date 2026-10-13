# Infrastructure as Code

Servers, networks, storage and their configuration are built by a person with a console, or by code that is read, reviewed and versioned like the rest.
Infrastructure as Code is the second way.

---

## What it is

- **A model of the environment, in files.**
  Microsoft defines it as using "DevOps methodology and versioning with a descriptive model to define and deploy infrastructure".

- **The same source gives the same environment.**
  The change is made in the source, not in the target.

- **It answers the snowflake.**
  Without it, each environment is configured by hand, becomes unique, and cannot be reproduced.

---

## Imperative and declarative

- **Imperative**: the sequence of commands, `mkdir`, `echo >>`, `chmod`.
  What it does depends on what is already there.

- **Declarative**: a description of the final state.
  The tool works out the steps, and shows them before it runs them.

- **Idempotent**: the result of running it once is the result of running it many times.
  Ansible's glossary says it this way: "the result of performing it once is exactly the same as the result of performing it repeatedly".

---

## How it works

![The code is compared with the state and the real environment, the plan lists the changes, apply makes them, and a change made by hand is drift](../assets/iac-loop-dark.svg#gh-dark-mode-only)
![The code is compared with the state and the real environment, the plan lists the changes, apply makes them, and a change made by hand is drift](../assets/iac-loop.svg#gh-light-mode-only)

---

## State and drift

- **State** is what the tool remembers it manages.
  Terraform "keeps track of your real infrastructure in a state file".
  Bicep has none: "Azure stores all states".
  Ansible keeps none either, it reads the machine.

- **Drift** is a difference between the code and the environment, made outside the tool.
  `terraform plan -refresh-only` reports it without changing anything.

- **A state file can hold secrets.**
  Terraform stores a secret placed in the configuration "in its state and plan files", readable by anyone who can read them.

---

## The tools

Tool        | What it is
------------|----------------------------------------------------------------------------------------------------------
Terraform   | declarative configuration (HCL) of cloud and on-premises resources: write, plan, apply, with a state file
OpenTofu    | an open source fork of Terraform, hosted by the Linux Foundation
Ansible     | automation of remote systems, which "controls their desired state", with playbooks in YAML
Bicep       | a declarative language for Azure, converted by its CLI to an ARM template
Pulumi, CDK | the same idea in a general programming language

---

## Dated facts about Terraform

- **10 August 2023**: HashiCorp moved its future releases from the Mozilla Public License 2.0 to the Business Source License 1.1.

- **20 September 2023**: the Linux Foundation announced OpenTofu, "an open and community-driven response".

- **27 February 2025**: IBM completed its acquisition of HashiCorp.

- **A tool is a dependency**, with a licence, an owner and a roadmap that can change.
  The code of this course is the idea, the files of a tool are one way to write it.

---

## In this lab

Step        | What it shows
------------|--------------------------------------------------------------------------
Setup       | cosign and Trivy, verified
Imperative  | a script, run twice: an error, a duplicated line, and a success status
Idempotent  | the same script made safe to repeat, and what it still cannot do
Declarative | a file of resources and a small Python tool: plan, apply, state
Drift       | a change by hand, found by the plan, and a resource removed from the code
Tools       | the same file in Terraform and Ansible
Scan        | `trivy config` on a Terraform file, before anything exists

> The environment is a folder of files: no account, no cloud, nothing to pay.
> The real tools come in the next courses.
