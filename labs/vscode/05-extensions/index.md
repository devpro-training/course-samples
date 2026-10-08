# Extensions

An extension adds a language, a linter, a debugger, a theme or a whole tool to VS Code.

Marketplace                                               | Used by
----------------------------------------------------------|---------------------------------------------
[Visual Studio Marketplace](https://marketplace.visualstudio.com/vscode) | VS Code, as distributed by Microsoft
[Open VSX](https://open-vsx.org)                          | code-server, VSCodium and other builds of Code - OSS

Microsoft's terms reserve its marketplace to its own products, so a few extensions are only found there.

## From the user interface

1. Open the **Extensions** view with **☰ > View > Extensions**.

2. Search for `GitLens`, the Git extension made by GitKraken, and look at its page: publisher, installs, version and description.

## From the command line

The same extension can be installed from a terminal, which is how a setup script or a container image prepares an editor.

1. In the [terminal](:panel:terminal), install GitLens by its identifier, `<publisher>.<name>`:

   <!-- verify: requires=network timeout=180 expect="was successfully installed" -->

   ```bash exec
   code-server --install-extension eamodio.gitlens
   ```

   > [!NOTE]
   > On a desktop, the command is `code --install-extension eamodio.gitlens`.

2. List the installed extensions:

   <!-- verify: expect="eamodio.gitlens" -->

   ```bash exec
   code-server --list-extensions
   ```

3. Back in [VS Code](:panel:vnc), run **Developer: Reload Window** from the Command Palette, so the running window loads the new extension.

> [!TIP]
> A `.vscode/extensions.json` file in a project lists the extensions it recommends, and VS Code offers to install them when the folder is opened.
