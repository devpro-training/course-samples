# Locators and actions

A locator says which element a test means, the way a user would describe it.
It is looked up again at each use, so a page that redraws its list does not break it.

Locator                          | Finds
---------------------------------|------------------------------------------------
`page.getByRole('button', { name: 'Add' })` | An element by its ARIA role and accessible name
`page.getByLabel('New task')`    | A form control by its label
`page.getByText('1 left')`       | An element by its text
`page.getByTestId('id')`         | An element by its `data-testid` attribute

The Playwright documentation recommends them in this order, and `page.locator()` with a CSS selector last, since it breaks when the markup changes.

## Add and check a task

1. Add two tests to the file: one fills the field and clicks the button, the other checks the box of a task:

   ```bash exec
   cd ~/lab/tasks && \
   cat >> tests/tasks.spec.ts <<'EOT'

   test('adds a task', async ({ page }) => {
     await page.goto('/');
     await page.getByLabel('New task').fill('Read the report');
     await page.getByRole('button', { name: 'Add' }).click();
     await expect(page.getByRole('listitem')).toHaveCount(3);
     await expect(page.getByText('Read the report')).toBeVisible();
     await expect(page.getByText('2 left')).toBeVisible();
   });

   test('completes a task', async ({ page }) => {
     await page.goto('/');
     await page.getByLabel('Write a test').check();
     await expect(page.getByText('0 left')).toBeVisible();
   });
   EOT
   ```

   [Open tasks.spec.ts](:open:tasks/tests/tasks.spec.ts) to read the three tests.

2. Run them:

   <!-- verify: timeout=120 expect="3 passed" -->

   ```bash exec
   cd ~/lab/tasks && \
   npx playwright test
   ```

   > [!NOTE]
   > A locator must match exactly one element when it is used for an action: `page.getByRole('checkbox').check()` fails here, since two boxes match.
   > `first()`, `last()` and `nth()` skip that check, and the Playwright documentation advises against them, since the target can change silently.

## Isolation

The first test of the file ran with the list of two tasks, and so did the third, although the second one added a task.
Each test gets its own browser context, a clean profile with its own cookies and storage, so tests never depend on each other or on their order.
