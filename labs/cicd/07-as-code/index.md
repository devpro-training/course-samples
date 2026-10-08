# Pipeline as code

A CI service reads its pipeline from a file in the repository, so it is versioned, reviewed and rolled back like the code.
The file only describes **when** to run, **where**, and **which commands**: the commands are the ones of `ci/pipeline.sh` and `ci/deploy.sh`.

## A workflow

1. Write the pipeline of this lab as a GitHub Actions workflow.
   The job `ci` runs one stage per step, and uploads the artifact.
   The job `deliver` waits for it, and only runs on `main`:

   ```bash exec
   cd ~/lab/hello && \
   mkdir -p .github/workflows && \
   cat > .github/workflows/ci.yml <<EOT
   name: CI

   on:
     push:
       branches: [main]
     pull_request:

   jobs:
     ci:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@${CHECKOUT_VERSION}
         - name: Lint
           run: bash ci/pipeline.sh lint
         - name: Test
           run: bash ci/pipeline.sh test
         - name: Package
           run: bash ci/pipeline.sh package
           env:
             COMMIT: \${{ github.sha }}
         - uses: actions/upload-artifact@${UPLOAD_ARTIFACT_VERSION}
           with:
             name: hello
             path: dist/*.tar.gz

     deliver:
       needs: ci
       if: github.ref == 'refs/heads/main'
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@${CHECKOUT_VERSION}
         - uses: actions/download-artifact@${DOWNLOAD_ARTIFACT_VERSION}
           with:
             name: hello
             path: dist
         - run: bash ci/deploy.sh dist/hello-*.tar.gz
           env:
             DEPLOY_ROOT: \${{ runner.temp }}/deploy
   EOT
   ```

   [Open ci.yml](:open:hello/.github/workflows/ci.yml).

2. Check it offline, with no account and no push:

   <!-- verify: expect="actionlint exit code: 0" -->

   ```bash exec
   cd ~/lab/hello && \
   actionlint .github/workflows/ci.yml; \
   echo "actionlint exit code: $?"
   ```

3. A typo in a job name is found before any run, which is the point of a linter:

   <!-- verify: expect="does not exist in this workflow" -->

   ```bash exec
   cd ~/lab/hello && \
   sed 's/needs: ci/needs: tset/' .github/workflows/ci.yml > ~/lab/bad.yml && \
   { actionlint ~/lab/bad.yml; echo "actionlint exit code: $?"; }
   ```

4. Commit the scripts and the workflow, and push them to the lab server, which runs the pipeline as before:

   <!-- verify: expect="PASSED" -->

   ```bash exec
   cd ~/lab/hello && \
   git add . && \
   git commit -m "Add the deploy script and the workflow" && \
   git push
   ```

> [!NOTE]
> The lab server ignores `.github/`: it runs `post-receive`.
> On GitHub, the same push starts the workflow, with `ubuntu-latest` as the machine.
> A runner is thrown away after the job, so the `deliver` job here only proves that the artifact deploys: a real one copies it to a server.
> Third-party actions are pinned to a full commit SHA in a real repository, since a tag can be moved.

## The same pipeline elsewhere

Each CI service has its own keys for the same ideas.
The commands do not change, which is why they live in a script.

Idea             | GitHub Actions              | GitLab CI                          | Azure Pipelines
-----------------|-----------------------------|------------------------------------|----------------------------
File             | `.github/workflows/*.yml`   | `.gitlab-ci.yml`                   | a YAML file of the repository
Start            | `on`                        | `rules`                            | `trigger`, `pr`
Machine          | `runs-on`                   | `image`, or the runner             | `pool`
Group of steps   | `jobs.<id>`                 | a job, with its `stage`            | `stages`, `jobs`
Command          | `run`                       | `script`                           | `script`
Order            | `needs`                     | `stages`, `needs`                  | `dependsOn`
Condition        | `if`                        | `rules`                            | `condition`
Artifact         | `upload-artifact`, `download-artifact` | `artifacts:paths`       | `publish`, `download`
Commit           | `github.sha`                | `CI_COMMIT_SHA`                    | `Build.SourceVersion`

The GitLab and Azure files are not written here: each service validates its own file, which needs an account.
