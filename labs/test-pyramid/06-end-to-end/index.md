# End-to-end test

An end-to-end test runs the application as it runs in production, and drives it as a user does.
Nothing is replaced: a real process, a real port, a real browser, the real clock.

It is the only layer that proves the page, its JavaScript and the API work together.
It is also the slowest, and the most fragile: a browser, a port and a start-up time can all fail without the code being wrong.

The lab image carries Google Chrome, which can load a page without a window, run its JavaScript, and print the resulting page.
That is enough for one smoke test.
A real project uses a browser automation tool, the subject of the Playwright course.

## Write the test

1. Write a script that starts the application, waits until it answers, loads the page in headless Chrome, and checks the text the page shows once its script has run:

   ```bash exec
   cd ~/lab && \
   cat > e2e.sh <<'EOT'
   #!/usr/bin/env bash
   port=$1
   cd ~/lab
   ASPNETCORE_ENVIRONMENT=Development nohup dotnet run --project Shop --no-launch-profile --urls "http://localhost:$port" > ~/shop.log 2>&1 &
   pid=$!
   trap 'kill $pid 2>/dev/null; wait $pid 2>/dev/null' EXIT
   wget -q -O /dev/null --retry-connrefused --tries=60 --waitretry=1 "http://localhost:$port/" || { echo "FAIL: the application did not start"; exit 1; }
   dom=$(google-chrome --headless=new --no-sandbox --virtual-time-budget=5000 --dump-dom "http://localhost:$port/" 2>/dev/null)
   if grep -Eq 'id="total">Total: (108|102)' <<< "$dom"; then
     echo "PASS: the browser shows the total"
   else
     echo "FAIL: the browser does not show the total"
     exit 1
   fi
   EOT
   chmod +x e2e.sh
   ```

   [Open e2e.sh](:open:e2e.sh): `--dump-dom` prints the page after its script has run, so a total in the page is only there if the page, the API and the browser worked together.
   The source of the page holds `"Total: " + quote.total`, which does not match.
   The total is 108 (a discount of 12), or 102 (18) on a Friday, since the real clock is used: the test accepts both.

   > [!NOTE]
   > `--no-sandbox` is needed because the lab container does not allow the namespaces of Chrome's own sandbox.
   > It is acceptable in a disposable container, and not on a workstation.

2. Run it:

   <!-- verify: timeout=180 expect="PASS: the browser shows the total" -->

   ```bash exec
   cd ~/lab && \
   ./e2e.sh "${SHOP_PORT}"
   ```

   The script exits with a non-zero code on a failure, which is what a CI pipeline looks at.
   It takes seconds, since the application has to be started, which is why a project has a handful of them, one per critical journey.

> [!NOTE]
> An end-to-end test runs the real clock, so it asserts what holds on every day.
> A test that passes six days a week is worse than no test.
