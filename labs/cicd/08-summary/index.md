# Summary

---

## Cheat sheet

Command                                | Does
---------------------------------------|----------------------------------------------
`bash ci/pipeline.sh`                  | Every stage: lint, test, package
`bash ci/pipeline.sh <stage>`          | One stage
`echo $?`                              | The exit code of the last command, 0 is green
`git archive <commit> \| tar -x -C <dir>` | A clean copy of one commit
`.git/hooks/post-receive` (server)     | A script run after every push
`ln -sfn <target> <link>`, `mv -T`     | A link replaced in one step
`actionlint <file>`                    | Checks a GitHub Actions workflow offline

---

## The pipeline

- **Fail fast**: the cheapest stage first, and the first failure stops the run.

- **One script**: the commands live in the repository, and the CI file only calls them.

- **Build once**: the artifact tested is the artifact deployed, named after its commit.

- **Clean machine**: every run starts from a new checkout, so nothing depends on a developer's machine.

- **Fast**: the XP guideline Martin Fowler quotes is a ten minute build, since the point is rapid feedback.

---

## The release

- A release is **immutable**, in a folder of its own, and `current` is only a link.

- A **smoke test** runs before the switch.

- A **rollback** is a deployment of the previous artifact.

- Secrets are never in the repository or in an artifact: the service injects them into the run.

---

## Good practices

- A red pipeline is fixed first: nobody has a higher priority.

- Commit to the mainline often, with small changes.

- Protect the mainline: a merge needs a green pipeline.

- Pin the versions of the tools and of the third-party actions.

- Keep the pipeline in the repository, and lint it.

---

## Next

- Playwright: the browser tests a pipeline runs after the unit tests.

- Docker: the artifact becomes an image.

- Further reading: [Continuous Integration](https://martinfowler.com/articles/continuousIntegration.html), [Continuous Delivery](https://martinfowler.com/bliki/ContinuousDelivery.html), [GitHub Actions](https://docs.github.com/en/actions), [GitLab CI/CD](https://docs.gitlab.com/ci/) and [Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/).
