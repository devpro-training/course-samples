# Web API

A web API returns data, usually JSON, for other programs.
The template uses **minimal APIs**: a route and a function, in `Program.cs`.

## Create the API

1. Create it, add it to the solution, and make it use the `Greeter` project:

   <!-- verify: expect="added to the project" -->

   ```bash exec
   cd ~/lab && \
   dotnet new webapi -o Api && \
   dotnet sln add Api && \
   dotnet add Api reference Greeter
   ```

2. Replace the weather example of the template with one route that returns the greeting as JSON, and serves its OpenAPI description:

   ```bash exec
   cd ~/lab && \
   cat > Api/Program.cs <<'EOT'
   using Greeter;

   var builder = WebApplication.CreateBuilder(args);
   builder.Services.AddOpenApi();

   var app = builder.Build();
   app.MapOpenApi();

   app.MapGet("/greetings/{name}", (string name) => new { message = Greeting.For(name) });

   app.Run();
   EOT
   ```

   [Open Program.cs](:open:Api/Program.cs): `{name}` in the route is passed to the function, and the object it returns becomes JSON.
   [Open Api.csproj](:open:Api/Api.csproj): the `Sdk` is `Microsoft.NET.Sdk.Web`, and the template adds the OpenAPI package.

## Run and call it

1. Start the API in the background, and call it:

   <!-- verify: timeout=120 expect="Hello, Grace Hopper!" -->

   ```bash exec
   cd ~/lab && \
   ASPNETCORE_ENVIRONMENT=Development nohup dotnet run --project Api --no-launch-profile --urls "http://localhost:${API_PORT}" > ~/api.log 2>&1 &
   echo $! > ~/api.pid
   wget -qO- --retry-connrefused --tries=60 --waitretry=1 "http://localhost:${API_PORT}/greetings/grace%20hopper"; echo
   ```

2. Read the OpenAPI description, which tools use to generate documentation and clients:

   <!-- verify: expect="Api | v1" -->

   ```bash exec
   wget -qO- "http://localhost:${API_PORT}/openapi/v1.json" | head -n 20
   ```

3. Stop it, then build the whole solution, which now holds four projects:

   <!-- verify: expect="Build succeeded" -->

   ```bash exec
   cd ~/lab && \
   kill $(cat ~/api.pid) && \
   dotnet build
   ```

> [!TIP]
> The `Api.http` file of the template holds requests that editors with an HTTP client can send.
> A controller-based API is `dotnet new webapi --use-controllers`, and a test project can start the API in memory with `WebApplicationFactory`.
