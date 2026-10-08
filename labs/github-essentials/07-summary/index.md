# Summary

---

## Cheat sheet

Need                    | Command or place
------------------------|------------------------------------------------------
Read a repository       | `git clone https://github.com/<owner>/<repo>.git`
The same, in a page     | `https://github.com/<owner>/<repo>`
Read it as JSON         | `wget -O - https://api.github.com/repos/<owner>/<repo>`
Rate limit              | 60 requests per hour and per IP address, `/rate_limit`
A pull request          | `git fetch origin pull/<n>/head:<branch>`
A tag's commit          | `git ls-remote --tags <url> <tag>`
A workflow              | `.github/workflows/<name>.yml`, runs in the **Actions** tab

---

## Good practices

- Small pull requests, each with one purpose and a description that says why.

- Pin an action to a full commit SHA, and a tool to a version.

- A token has the least permissions and the shortest life, and is never in a repository.

- A `README.md` that says what the project is, how to run it and how to contribute.

---

## Not covered

- **Writing**: an account, a token or SSH key, forks, and opening a pull request.

- **Protecting**: branch protection and required reviews, `CODEOWNERS`.

- **Securing**: Dependabot, secret scanning and code scanning.

- **The GitHub CLI** (`gh`) and GitHub Codespaces.

---

## Next

- CI/CD: build, test and deliver every change with a pipeline.

- The [GitHub documentation](https://docs.github.com) and [GitHub Skills](https://skills.github.com), free hands-on courses.
