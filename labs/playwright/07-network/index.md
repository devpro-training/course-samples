# Network

A test of the page should not depend on the API behind it being up, nor on its data.
`page.route` intercepts the requests of the page, and answers them with whatever the test needs.

1. Write two tests: the first replaces the response of `tasks.json` with an empty list, the second fetches the real one and adds a task to it.
   A route is set before `page.goto`, so the first request is already caught:

   ```bash exec
   cd ~/lab/tasks && \
   cat > tests/network.spec.ts <<'EOT'
   import { test, expect } from '@playwright/test';

   test('shows a message when there is nothing to do', async ({ page }) => {
     await page.route('**/tasks.json', (route) => route.fulfill({ json: [] }));
     await page.goto('/');
     await expect(page.getByText('Nothing to do')).toBeVisible();
     await expect(page.getByRole('listitem')).toHaveCount(0);
   });

   test('lists a task that the API does not have yet', async ({ page }) => {
     await page.route('**/tasks.json', async (route) => {
       const response = await route.fetch();
       const tasks = await response.json();
       tasks.push({ title: 'Mock the API', done: false });
       await route.fulfill({ response, json: tasks });
     });
     await page.goto('/');
     await expect(page.getByRole('listitem')).toHaveCount(3);
     await expect(page.getByText('Mock the API')).toBeVisible();
   });
   EOT
   ```

   [Open network.spec.ts](:open:tasks/tests/network.spec.ts) to read them.

2. Run every test of the project:

   <!-- verify: timeout=120 expect="6 passed" -->

   ```bash exec
   cd ~/lab/tasks && \
   npx playwright test
   ```

   > [!NOTE]
   > `route.fulfill` answers without calling the server, `route.fetch` calls it and hands the response back to be changed.
   > `page.routeFromHAR` replays a recorded archive of responses, for an API too large to write by hand.
