# Tour

## A small project

1. In the [terminal](:panel:terminal), create a Node.js script in a Git repository:

   <!-- verify: expect="1 file changed" -->

   ```bash exec
   mkdir -p ~/lab/hello && \
   cd ~/lab/hello && \
   printf '%s\n' \
     'const names = ["Ada", "Grace", "Linus"];' \
     '' \
     'for (const name of names) {' \
     '  const message = `Hello, ${name}!`;' \
     '  console.log(message);' \
     '}' > app.js && \
   git init -q && \
   git add app.js && \
   git commit -m "Add greeting app"
   ```

2. Run it:

   <!-- verify: expect="Hello, Grace!" -->

   ```bash exec
   node ~/lab/hello/app.js
   ```

## The window

Go back to [VS Code](:panel:vnc).

1. **Restricted Mode** is shown in the Status Bar: VS Code does not run tasks, debuggers or extensions from a folder it does not trust yet.
   This folder only holds code written in this lab, so click **Restricted Mode**, click **Trust**, then close the Workspace Trust window with its **✕**.

2. The **Chat** on the right is the AI assistant, which needs an account, and closes with its **✕**.

3. In the **Explorer**, opened with **☰ > View > Explorer**, expand `hello` and click `app.js` to open it in the editor.

4. Click the **Command Center**, the search box at the top, and type `app`: this is **Quick Open**, the fastest way to open a file.

5. Type `>` in the same box: this is the **Command Palette**, where every command of VS Code can be found by name.
   Type `theme`, select **Preferences: Color Theme**, and pick a theme with the arrow keys.

6. Open the integrated terminal with the menu **☰ > Terminal > New Terminal**, and run the script there:

   ```bash
   node hello/app.js
   ```

> [!TIP]
> `F1` opens the Command Palette, `Ctrl+P` Quick Open, and `` Ctrl+` `` the terminal.
> In a browser, some shortcuts belong to the browser itself, which is why this lab uses the menus and the Command Center.
