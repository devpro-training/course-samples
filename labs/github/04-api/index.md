# The REST API

Everything the web page shows is also served as JSON by `api.github.com`.
A public resource is read without a token, with a limit of 60 requests per hour and per IP address.

## A repository

1. Get the repository, asking for the JSON media type and a version of the API, since the version of an answer is chosen by a header, and `2022-11-28` is used when there is none:

   <!-- verify: requires=network timeout=60 -->

   ```bash exec
   mkdir -p ~/lab/api && \
   cd ~/lab/api && \
   wget -q -O repo.json \
     --header="Accept: application/vnd.github+json" \
     --header="X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
     "${GITHUB_API}/repos/${COURSE_REPO}"
   ```

   > [!NOTE]
   > The API refuses a request without a `User-Agent` header.
   > `wget` sends its own, which is enough here.

2. Open the response, a long document where `html_url` is the page of the browser and `clone_url` the one of `git clone`:

   [Open repo.json](:open:api/repo.json)

3. Print the fields that matter:

   <!-- verify: expect="default_branch main" -->

   ```bash exec
   cd ~/lab/api && \
   python3 -c '
   import json
   repo = json.load(open("repo.json"))
   for key in ("full_name", "default_branch", "visibility", "clone_url"):
       print(key, repo[key])'
   ```

## The limit

1. Every response says how many requests are left.
   `/rate_limit` is the one request that does not count against the limit:

   <!-- verify: requires=network expect="X-RateLimit-Limit: 60" -->

   ```bash exec
   cd ~/lab/api && \
   wget -S -q -O /dev/null "${GITHUB_API}/rate_limit" 2>&1 | grep -i "^ *x-ratelimit-"
   ```

   > [!NOTE]
   > With a token the limit is higher, and private repositories can be read.
   > The token is passed in an `Authorization` header, and is never written in a file of a repository.

## A tag is a commit

1. The API names the commit a tag points to:

   <!-- verify: requires=network expect="11bd71901bbe5b1630ceea73d27597364c9af683" -->

   ```bash exec
   cd ~/lab/api && \
   wget -q -O - \
     --header="Accept: application/vnd.github+json" \
     "${GITHUB_API}/repos/${SAMPLE_REPO}/git/ref/tags/${SAMPLE_TAG}" | \
   python3 -c 'import json, sys; print(json.load(sys.stdin)["object"]["sha"])'
   ```

2. Git asks the same question, with no API:

   <!-- verify: requires=network expect="refs/tags/v4.2.2" -->

   ```bash exec
   git ls-remote --tags https://github.com/${SAMPLE_REPO}.git ${SAMPLE_TAG}
   ```

   Both answers are the same commit: the web page, the API and Git are three views of the same data.
