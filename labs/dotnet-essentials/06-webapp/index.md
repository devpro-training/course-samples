# Web app

The same SDK creates every kind of .NET application, with a template per kind.

Template        | Short name  | For
----------------|-------------|--------------------------------------------
Console App     | `console`   | A command line tool, as in this lab
Razor Pages     | `webapp`    | A website with server-rendered pages
MVC             | `mvc`       | A website with controllers and views
Blazor Web App  | `blazor`    | A website with C# components instead of JavaScript
Web API         | `webapi`    | An HTTP API returning JSON
gRPC Service    | `grpc`      | A service for gRPC
Class Library   | `classlib`  | Code shared by other projects
MCP Server App  | `mcpserver` | A server for AI tools

`dotnet new list` shows them all, and each one builds, runs and tests with the same commands.

## Create the site

1. Create a Razor Pages site, add it to the solution, and make it use the `Greeter` project:

   <!-- verify: expect="added to the project" -->

   ```bash exec
   cd ~/lab && \
   dotnet new webapp -o Web && \
   dotnet sln add Web && \
   dotnet add Web reference Greeter
   ```

2. Replace the home page with one that shows the greeting of the `Greeting` class:

   ```bash exec
   cd ~/lab && \
   cat > Web/Pages/Index.cshtml <<'EOT'
   @page
   @using Greeter
   @{
       ViewData["Title"] = "Home page";
   }

   <h1>@Greeting.For("ada lovelace")</h1>
   <p>Served by ASP.NET Core Razor Pages.</p>
   EOT
   ```

   [Open Index.cshtml](:open:Web/Pages/Index.cshtml): HTML, with C# after an `@`.
   [Open Program.cs](:open:Web/Program.cs) of the site: `AddRazorPages` and `MapRazorPages` are all it takes to serve the pages.

## Run it

1. Start the site in the background, on the port of the lab, and wait until it answers:

   <!-- verify: timeout=120 expect="Hello, Ada Lovelace!" -->

   ```bash exec
   cd ~/lab && \
   ASPNETCORE_ENVIRONMENT=Development nohup dotnet run --project Web --no-launch-profile --urls "http://localhost:${WEB_PORT}" > ~/web.log 2>&1 &
   echo $! > ~/web.pid
   wget -qO- --retry-connrefused --tries=60 --waitretry=1 "http://localhost:${WEB_PORT}/" | grep "<h1"
   ```

   > [!NOTE]
   > `--urls` sets the address, and `--no-launch-profile` ignores `Properties/launchSettings.json`, which holds the ports of a developer machine and opens a browser.
   > `ASPNETCORE_ENVIRONMENT` is `Production` unless it is set, and `Development` adds the details useful while building.

2. [Open the site](:navigate:webapp:http://localhost:5080/) in the lab browser.

3. Stop it:

   ```bash exec
   kill $(cat ~/web.pid)
   ```
