# Summary

---

## Cheat sheet

Command or API                              | Does
--------------------------------------------|------------------------------------------------
`npm init playwright@latest`                | Create a project, its config and an example test
`npx playwright install --only-shell chromium` | Download the headless Chromium
`npx playwright test`                       | Run the tests, all of them or a file or `-g` name
`await page.goto('/')`                      | Open a page of the `baseURL`
`page.getByRole`, `getByLabel`, `getByText` | Find an element as a user describes it
`fill`, `click`, `check`                    | Act, after waiting for the element to be ready
`await expect(locator).toBeVisible()`       | Assert, and retry until it holds
`page.route(url, handler)`                  | Answer a request of the page in the test
`npx playwright show-report`                | Open the HTML report, with the traces

---

## Good practices

- Test what a user sees and does, not the markup, so prefer a role, a label or a text to a CSS selector.

- Give the locator to `expect`, never a value read before: `await expect(locator).toHaveCount(2)`.

- No `sleep`, no `waitForTimeout`: assertions and actions already wait.

- A page object for a page that several tests use, with the locators and actions in it and the assertions in the tests.

- Mock what the app does not own, and keep a few tests on the real thing.

- Few end-to-end tests, on the paths that matter, and the rest lower in the test pyramid.

- Record a trace on the first retry in CI, and keep the report as an artifact of the pipeline.

---

## Further

- **UI Mode**, `npx playwright test --ui`, runs and replays tests in a window, and **codegen**, `npx playwright codegen`, writes a test from clicks, both on a machine with a screen.

- **Projects** in the config run the same tests on Chromium, Firefox and WebKit.

- The **VS Code extension** runs and debugs a test from the editor.

---

## Next

- Docker: the same app and the same tests in containers.

- The [Playwright documentation](https://playwright.dev/docs/intro), and its [best practices](https://playwright.dev/docs/best-practices).
