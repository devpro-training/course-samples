# Waiting

The app loads its tasks one second after the page, as an API would.
A test must not read the page before, and must not sleep for a fixed time either.

## An assertion that does not wait

1. Write a test that counts the tasks as soon as the page is loaded, and compares the number with a plain `expect`:

   ```bash exec
   cd ~/lab/tasks && \
   cat > tests/waiting.spec.ts <<'EOT'
   import { test, expect } from '@playwright/test';

   test('counts the tasks', async ({ page }) => {
     await page.goto('/');
     expect(await page.getByRole('listitem').count()).toBe(2);
   });
   EOT
   ```

2. Run it, and read the failure:

   <!-- verify: timeout=120 expect="Received: 0" -->

   ```bash exec
   cd ~/lab/tasks && \
   { npx playwright test waiting || true; }
   ```

   `count()` answers at once, with the 0 tasks of a list that is not loaded yet, and `toBe` compares that number once.
   Here it fails every time, with a one second delay.
Against a real app it passes or fails with the speed of the machine, which is a flaky test.

## An assertion that waits

1. Give the locator to `expect` instead, and let it compare:

   ```bash exec
   cd ~/lab/tasks && \
   cat > tests/waiting.spec.ts <<'EOT'
   import { test, expect } from '@playwright/test';

   test('counts the tasks', async ({ page }) => {
     await page.goto('/');
     await expect(page.getByRole('listitem')).toHaveCount(2);
   });
   EOT
   ```

2. Run it again:

   <!-- verify: timeout=120 expect="1 passed" -->

   ```bash exec
   cd ~/lab/tasks && \
   npx playwright test waiting
   ```

   A **web-first assertion**, such as `toHaveCount`, `toBeVisible` or `toHaveText`, checks again until it holds or its timeout runs out, 5 seconds by default.
   The test is the same, without a `sleep`, and as fast as the page.

## Actions wait too

The **Add** button is disabled for the first second, and `click()` never mentions it.
Before an action, Playwright waits until the element is visible, stable, enabled and not covered, and fails with a timeout if it never is.
The `adds a task` test of the previous step relied on it, and the report of the last step shows the wait.
