<!-- include: ../../shared/setup.md -->

## On a workstation

Playwright needs Node.js, current 22, 24 or 26, on Windows, macOS or Linux.

System         | Command
---------------|-----------------------------------------------
Windows        | `winget install OpenJS.NodeJS.LTS`
macOS          | `brew install node`
Debian, Ubuntu | the package of [nodejs.org](https://nodejs.org/en/download)

npm comes with Node.js, and `npm init playwright@latest` asks a few questions and creates the project of the next steps.
The lab does the same in visible steps, with a pinned version, so the output matches.

<!-- include: ../../shared/setup-npm.md -->

## Playwright

1. Create the project folder and the `package.json` that records its dependencies:

   <!-- verify: expect="Wrote to" -->

   ```bash exec
   mkdir -p ~/lab/tasks && \
   cd ~/lab/tasks && \
   npm init -y
   ```

2. Add the test runner, `@playwright/test`, as a development dependency:

   <!-- verify: requires=network timeout=180 expect="added 3 packages" -->

   ```bash exec
   cd ~/lab/tasks && \
   npm install --save-dev @playwright/test@${PLAYWRIGHT_VERSION}
   ```

3. Download the browser.
   Playwright drives its own build of Chromium, and `--only-shell` keeps only the headless one, which is all the tests need:

   <!-- verify: requires=network timeout=300 expect="Chrome Headless Shell" -->

   ```bash exec
   cd ~/lab/tasks && \
   npx playwright install --only-shell chromium
   ```

   > [!NOTE]
   > Browsers are stored once per user, in `~/.cache/ms-playwright`, and shared by every project.
   > Without `--only-shell`, `npx playwright install` also downloads Firefox, WebKit and the full Chromium.
   > A workstation also needs the system libraries of the browsers, which `--with-deps` installs with administrator rights.
   > The lab image already carries them.

4. Check the version:

   <!-- verify: expect="Version 1." -->

   ```bash exec
   cd ~/lab/tasks && \
   npx playwright --version
   ```
