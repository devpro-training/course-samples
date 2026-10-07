# Settings

Every setting has a default, which can be changed at two levels.

Level     | Stored in                    | Applies to
----------|------------------------------|-----------------------------------------------
User      | The user profile             | Every folder opened by this user
Workspace | `.vscode/settings.json`      | The opened folder, for everyone who clones it

A workspace value wins over a user value.
A workspace file committed with the project gives the whole team the same formatting rules.

## Change a setting

1. Click the **Command Center**, type `>workspace settings`, and select **Preferences: Open Workspace Settings**.

2. Search for `auto save`, and set **Files: Auto Save** to `afterDelay`: files are now saved a second after each change.

3. In the Explorer, open the new file `.vscode/settings.json`: the change is stored as JSON.

   ```json
   {
       "files.autoSave": "afterDelay"
   }
   ```

4. Click the **Open Settings (JSON)** icon, at the top right of the settings, to edit them as JSON directly.

> [!NOTE]
> On a desktop, user settings are in `settings.json` under `%APPDATA%\Code\User` on Windows,
> `~/Library/Application Support/Code/User` on macOS, and `~/.config/Code/User` on Linux.
> **Settings Sync** saves them, with the extensions and keyboard shortcuts, to a GitHub or Microsoft account.
