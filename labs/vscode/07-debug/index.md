# Debug

A debugger pauses a program on a line, and shows its variables at that moment.
VS Code debugs JavaScript out of the box, and other languages through extensions.

1. Open `hello/app.js`, and click left of the line number of `console.log(message);`: a red dot marks a **breakpoint**.

2. Open the **Run and Debug** view with **☰ > View > Run**, click **Run and Debug**, and choose **Node.js**.

3. The program stops on the breakpoint, before the line runs:

   - **Variables** shows `name` and `message` for the current name.
   - The toolbar at the top continues, steps over, into or out of a line, restarts or stops.

4. Click **Continue** a few times: each stop shows the next name, and the output appears in the **Debug Console**.

5. Click **Stop** when done.

> [!TIP]
> On a desktop, `F9` toggles a breakpoint, `F5` starts or continues, `F10` steps over, and `Shift+F5` stops.
> A `.vscode/launch.json` file keeps a debug configuration, with arguments and environment variables, for the whole team.
