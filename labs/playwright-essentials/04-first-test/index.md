# First test

A test is a function that receives a `page`, a tab of a new browser, and says what is expected of it.

## Configure the runner

1. Create `playwright.config.ts`, which tells the runner where the tests are, which address the app has, and how to start it:

   ```bash exec
   cd ~/lab/tasks && \
   cat > playwright.config.ts <<EOT
   import { defineConfig } from '@playwright/test';

   export default defineConfig({
     testDir: 'tests',
     reporter: 'list',
     use: { baseURL: 'http://localhost:${APP_PORT}' },
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

   - `baseURL` lets a test write `page.goto('/')`.
   - `webServer` starts the app before the tests and stops it after them, and waits until `url` answers.
   - `reuseExistingServer` uses a server that is already running, which a developer has, instead of failing on the busy port.
   - `stderr: 'ignore'` hides the access log of the static server.

## Write the test

1. Create the test, which opens the page and checks what a user sees:

   ```bash exec
   mkdir -p ~/lab/tasks/tests && \
   cd ~/lab/tasks && \
   cat > tests/tasks.spec.ts <<'EOT'
   import { test, expect } from '@playwright/test';

   test('lists the tasks', async ({ page }) => {
     await page.goto('/');
     await expect(page).toHaveTitle('Tasks');
     await expect(page.getByRole('listitem')).toHaveCount(2);
     await expect(page.getByText('1 left')).toBeVisible();
   });
   EOT
   ```

   [Open tasks.spec.ts](:open:tasks/tests/tasks.spec.ts) to read it.
   The file name ends with `.spec.ts`, which is what the runner looks for in `testDir`.

2. Run it:

   <!-- verify: timeout=120 expect="1 passed" -->

   ```bash exec
   cd ~/lab/tasks && \
   npx playwright test
   ```

   > [!NOTE]
   > The two `npm notice run` lines before the results are not Playwright's.
   > npm 12 prints them whenever it runs a command with the terminal attached: the project and the event, here `npx`, then the command.
   > `npm run` prints the same two lines for a script of `package.json`, and a project usually keeps its test command there, as `"test": "playwright test"`, which CI then calls with `npm test`.

   > [!NOTE]
   > The browser ran headless, with no window, and exited.
   > `--headed` shows it, which needs a screen.
   > A test is also run by name with `-g "lists"`, and a file with `npx playwright test tests/tasks.spec.ts`.
