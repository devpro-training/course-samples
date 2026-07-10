# Browser Automation

This course shows scripted browser actions running in the VNC panel — driven server-side by the app's automation engine over Chrome DevTools Protocol (CDP).
No learner interaction is required to run them.

## Start the demo app

> [!NOTE]
> The lab ships a tiny static demo app under `demo-app/`.

Start it so the browser panel has something to automate:

```bash exec
cd demo-app && python3 -m http.server 8080 &
```

Check python3 process is running:

```bash exec
ps -ef | grep http.server
```

Then move on to the next step — it drives the browser for you.
