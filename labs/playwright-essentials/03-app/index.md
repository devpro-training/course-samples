# The app under test

Playwright tests a web app from the outside, so any app does.
This one is a task list in three static files: a page, a script and the JSON the script loads.

## Write the app

1. Create the page, with a heading, a labelled field, a button and a list:

   ```bash exec
   mkdir -p ~/lab/tasks/app && \
   cd ~/lab/tasks/app && \
   cat > index.html <<'EOT'
   <!doctype html>
   <html lang="en">
   <head>
     <meta charset="utf-8">
     <title>Tasks</title>
   </head>
   <body>
     <h1>Tasks</h1>
     <form id="new-task">
       <label for="title">New task</label>
       <input id="title" name="title" autocomplete="off">
       <button type="submit" disabled>Add</button>
     </form>
     <p id="status">Loading</p>
     <ul id="tasks"></ul>
     <script src="app.js"></script>
   </body>
   </html>
   EOT
   ```

   [Open index.html](:open:tasks/app/index.html) to see it in the editor.
   The button is disabled until the script has loaded the list.

2. Create the tasks the app starts with:

   ```bash exec
   cd ~/lab/tasks/app && \
   cat > tasks.json <<'EOT'
   [
     { "title": "Install Playwright", "done": true },
     { "title": "Write a test", "done": false }
   ]
   EOT
   ```

3. Create the script, which loads `tasks.json`, lists the tasks, adds one and counts the ones left:

   ```bash exec
   cd ~/lab/tasks/app && \
   cat > app.js <<'EOT'
   const list = document.getElementById('tasks');
   const status = document.getElementById('status');
   let tasks = [];

   function render() {
     list.replaceChildren(...tasks.map((task) => {
       const item = document.createElement('li');
       const label = document.createElement('label');
       const box = document.createElement('input');
       box.type = 'checkbox';
       box.checked = task.done;
       box.addEventListener('change', () => { task.done = box.checked; render(); });
       label.append(box, ' ', task.title);
       item.append(label);
       return item;
     }));
     const left = tasks.filter((task) => !task.done).length;
     status.textContent = tasks.length === 0 ? 'Nothing to do' : `${left} left`;
   }

   document.getElementById('new-task').addEventListener('submit', (event) => {
     event.preventDefault();
     const input = document.getElementById('title');
     if (input.value.trim() === '') return;
     tasks.push({ title: input.value.trim(), done: false });
     input.value = '';
     render();
   });

   // The delay stands for a slow API: the list is not there when the page is loaded.
   fetch('tasks.json')
     .then((response) => response.json())
     .then((loaded) => new Promise((resolve) => setTimeout(() => resolve(loaded), 1000)))
     .then((loaded) => {
       tasks = loaded;
       document.querySelector('button').disabled = false;
       render();
     });
   EOT
   ```

   [Open app.js](:open:tasks/app/app.js) to read it.
   The one second delay is on purpose, the tests of the next steps have to cope with it.

## Serve it

1. Start a static server in the background on the lab port, then wait until it answers:

   <!-- verify: timeout=60 expect="Install Playwright" -->

   ```bash exec
   cd ~/lab/tasks
   nohup python3 -m http.server ${APP_PORT} --bind 127.0.0.1 --directory app > ~/app.log 2>&1 &
   wget -qO- --retry-connrefused --tries=30 --waitretry=1 http://127.0.0.1:${APP_PORT}/tasks.json
   ```

2. [Open the app](:navigate:app:http://localhost:4173/) in the lab browser.
   The heading, the field **New task** and the button **Add** are what the tests of the next steps look for.

3. Stop the server.
   The test runner starts its own in the next step:

   ```bash exec
   pkill -f "http.server ${APP_PORT}"
   ```
