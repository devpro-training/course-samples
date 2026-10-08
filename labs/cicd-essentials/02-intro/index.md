# CI/CD essentials

Every change built, tested and ready to ship, without a human in the loop.

---

## What CI/CD is

- **Continuous integration**: each member of a team merges their changes into the shared mainline at least daily, and each merge is verified by an automated build, tests included.

- **Continuous delivery**: the software is built so that it can be released to production at any time.

- **Continuous deployment**: every change that goes through the pipeline is put into production automatically.

- Definitions of [Martin Fowler](https://martinfowler.com/articles/continuousIntegration.html), who also wrote [the second and the third](https://martinfowler.com/bliki/ContinuousDelivery.html).

---

## Why it matters

- **Feedback in minutes**: a broken change is found while its author still remembers it.

- **One way to build**: the same script runs on every push, on every machine.

- **Small releases**: a deployment is a routine, so it is cheap to do and to undo.

- **Foundation** for the registry, the scanner and the cluster that follow in this series.

---

## From a push to a release

![A push starts a pipeline of lint, test and package, which produces an artifact built once and then deployed, with a way back to the author and to the previous artifact](../assets/pipeline-dark.svg#gh-dark-mode-only)
![A push starts a pipeline of lint, test and package, which produces an artifact built once and then deployed, with a way back to the author and to the previous artifact](../assets/pipeline.svg#gh-light-mode-only)

---

## Not a product

- A pipeline is a **script** that a service runs when something happens to the repository.

- GitHub Actions, GitLab CI, Azure Pipelines, Jenkins or a Git hook all do the same job, with their own syntax.

- This lab builds the script and the server itself, then shows the same pipeline in a service's file.

---

## In this lab

Step                | What it shows
--------------------|-------------------------------------------------------
Project             | a small Python app and its unit tests
Pipeline            | lint, test and package in one script, exit codes
Server              | a Git server that runs the pipeline on every push, red and green
Delivery            | one artifact deployed as a release, smoke tested, rolled back
As code             | the same pipeline as a GitHub Actions workflow, checked offline

> No account and no network service: the Git server and the pipeline run in the lab.
