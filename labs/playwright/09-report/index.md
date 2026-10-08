# Report and trace

A failure in a pipeline has to be understood without running the test again.
The HTML report lists the tests, and a trace records every action of a test with a snapshot of the page.

1. Switch the reporter to `html`, which writes a report folder without opening it, and record a trace of every test:

   ```bash exec
   cd ~/lab/tasks && \
   cat > playwright.config.ts <<EOT
   import { defineConfig } from '@playwright/test';

   export default defineConfig({
     testDir: 'tests',
     reporter: [['list'], ['html', { open: 'never' }]],
     use: { baseURL: 'http://localhost:${APP_PORT}', trace: 'on' },
     webServer: {
       command: 'python3 -m http.server ${APP_PORT} --bind 127.0.0.1 --directory app',
       url: 'http://localhost:${APP_PORT}',
       reuseExistingServer: true,
       stderr: 'ignore',
     },
   });
   EOT
   ```

   [Open playwright.config.ts](:open:tasks/playwright.config.ts) to read it.

   > [!NOTE]
   > `trace: 'on'` records every test, which is useful to learn.
   > The project template uses `on-first-retry`, which records only the run that follows a failure, and costs nothing otherwise.

2. Run the tests, then serve the report in the background and wait until it answers:

   <!-- verify: timeout=180 expect="Playwright Test Report" -->

   ```bash exec
   cd ~/lab/tasks && \
   npx playwright test
   nohup npx playwright show-report --host 127.0.0.1 --port 9323 > ~/report.log 2>&1 &
   wget -qO- --retry-connrefused --tries=30 --waitretry=1 http://127.0.0.1:9323/ | grep -o "<title>[^<]*"
   ```

3. [Open the report](:navigate:report:http://127.0.0.1:9323/) in the lab browser.
   It lists the six tests, with a **View Trace** link on each.

4. Select **adds a task**.
   Its steps are listed with their duration: the **Click** on **Add** lasted about a second, the wait for the button to be enabled.

5. Select **View Trace**, next to the title of the test.
   The trace viewer lists the actions on the left, and the page as it was at the selected action on top, with the tabs **Before** and **After**.
   Select the **Click**, then the **Log** tab: it says that the button was not enabled, and that Playwright retried until it was.

6. Stop the report server:

   ```bash exec
   pkill -f "playwright.*show-report"
   ```

   > [!TIP]
   > A trace is a zip file, which is also opened with `npx playwright show-trace <file>` or at [trace.playwright.dev](https://trace.playwright.dev), where it is read in the browser and sent nowhere.
