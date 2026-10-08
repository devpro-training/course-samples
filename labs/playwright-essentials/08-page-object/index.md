# Page objects

The three tests of `tasks.spec.ts` repeat the same locators.
When the label of a field changes, every test has to change.
A **page object** is a class that holds the locators of a page and the actions a user does on it, so a test reads as a story and a change is made once.

## Write the page object

1. Create `pages/tasks-page.ts`, with the locators in the constructor and one method per user action:

   ```bash exec
   mkdir -p ~/lab/tasks/pages && \
   cd ~/lab/tasks && \
   cat > pages/tasks-page.ts <<'EOT'
   import { type Locator, type Page } from '@playwright/test';

   export class TasksPage {
     readonly newTask: Locator;
     readonly addButton: Locator;
     readonly tasks: Locator;
     readonly status: Locator;

     constructor(readonly page: Page) {
       this.newTask = page.getByLabel('New task');
       this.addButton = page.getByRole('button', { name: 'Add' });
       this.tasks = page.getByRole('listitem');
       this.status = page.locator('#status');
     }

     async goto() {
       await this.page.goto('/');
     }

     async add(title: string) {
       await this.newTask.fill(title);
       await this.addButton.click();
     }

     async complete(title: string) {
       await this.page.getByLabel(title).check();
     }
   }
   EOT
   ```

   [Open tasks-page.ts](:open:tasks/pages/tasks-page.ts) to read it.
   The class is the only place that knows how the page is built, and it holds no assertion: the test says what is expected.

2. Rewrite the three tests of `tasks.spec.ts` with it:

   ```bash exec
   cd ~/lab/tasks && \
   cat > tests/tasks.spec.ts <<'EOT'
   import { test, expect } from '@playwright/test';
   import { TasksPage } from '../pages/tasks-page';

   test('lists the tasks', async ({ page }) => {
     const tasksPage = new TasksPage(page);
     await tasksPage.goto();
     await expect(page).toHaveTitle('Tasks');
     await expect(tasksPage.tasks).toHaveCount(2);
     await expect(tasksPage.status).toHaveText('1 left');
   });

   test('adds a task', async ({ page }) => {
     const tasksPage = new TasksPage(page);
     await tasksPage.goto();
     await tasksPage.add('Read the report');
     await expect(tasksPage.tasks).toHaveCount(3);
     await expect(tasksPage.tasks.last()).toContainText('Read the report');
     await expect(tasksPage.status).toHaveText('2 left');
   });

   test('completes a task', async ({ page }) => {
     const tasksPage = new TasksPage(page);
     await tasksPage.goto();
     await tasksPage.complete('Write a test');
     await expect(tasksPage.status).toHaveText('0 left');
   });
   EOT
   ```

   [Open tasks.spec.ts](:open:tasks/tests/tasks.spec.ts) to compare it with the previous version.

3. Run the tests:

   <!-- verify: timeout=120 expect="6 passed" -->

   ```bash exec
   cd ~/lab/tasks && \
   npx playwright test
   ```

## One change, one place

1. Rename the button of the app to **Create**, and change the page object only, then run the tests of the file:

   <!-- verify: timeout=120 expect="3 passed" -->

   ```bash exec
   cd ~/lab/tasks && \
   sed -i 's/>Add</>Create</' app/index.html && \
   sed -i "s/name: 'Add'/name: 'Create'/" pages/tasks-page.ts && \
   npx playwright test tasks.spec
   ```

   The tests pass: the label was written once, where it is used by the three of them.
   Without the class, each test that clicks the button would have been edited.

2. Put the button back:

   ```bash exec
   cd ~/lab/tasks && \
   sed -i 's/>Create</>Add</' app/index.html && \
   sed -i "s/name: 'Create'/name: 'Add'/" pages/tasks-page.ts
   ```

   > [!NOTE]
   > Playwright documents the pattern in its [page object model guide](https://playwright.dev/docs/pom).
   > A page object is worth it when several tests use the same page, and not for a single test.
   > The runner can also hand it to a test as a fixture, with `test.extend`, to skip the `new TasksPage(page)` line.
