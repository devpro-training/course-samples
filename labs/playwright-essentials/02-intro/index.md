# Playwright essentials

End-to-end tests that drive a real browser, the way a user does.

---

## What Playwright is

- A **testing framework** for web apps, from Microsoft, free and open source, at [playwright.dev](https://playwright.dev).

- It drives **Chromium, Firefox and WebKit** with one API, in JavaScript, TypeScript, Python, Java and .NET.

- The test runner, `@playwright/test`, brings parallel runs, retries, reports and traces.

- This lab uses **TypeScript** and Chromium.

---

## Why it matters

- An end-to-end test is the only one that proves **the whole app works**: page, scripts, API and browser.

- **Auto-waiting**: an action waits until the element is ready, so there is no `sleep`.

- **Isolation**: a new browser context for each test, so tests do not depend on each other.

- **Debugging**: a trace holds every action with a snapshot of the page.

---

## How a test drives a browser

![A test file is run by the test runner, which drives a page in a fresh browser context of Chromium, which loads the app under test, and writes a report and a trace](../assets/playwright-dark.svg#gh-dark-mode-only)
![A test file is run by the test runner, which drives a page in a fresh browser context of Chromium, which loads the app under test, and writes a report and a trace](../assets/playwright.svg#gh-light-mode-only)

---

## In this lab

Step          | What it covers
--------------|----------------------------------------------------------
The app       | A small task list, served as static files
First test    | `playwright.config.ts`, `page.goto`, `expect`
Locators      | `getByRole`, `getByLabel`, `getByText`, `fill`, `click`, `check`
Waiting       | Web-first assertions, and the one that does not wait
Network       | `page.route` to replace the API response
Page objects   | A class that holds the locators and actions of a page
Report        | The HTML report and the trace viewer

> A test belongs to the test pyramid, at the top: few of them, on the paths that matter.
