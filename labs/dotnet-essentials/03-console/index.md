# Console app

`dotnet` is the one command for everything: create, build, run, test and package.

## Create

1. List the templates the SDK carries, and create a console app from the `console` one:

   <!-- verify: expect="was created successfully" -->

   ```bash exec
   mkdir -p ~/lab && \
   cd ~/lab && \
   dotnet new list console && \
   dotnet new console -o Greeter
   ```

2. Look at what was created:

   <!-- verify: expect="Greeter.csproj" -->

   ```bash exec
   ls ~/lab/Greeter
   ```

   File | Role
   -----|---------------------------------------------------------------
   `Greeter.csproj` | The **project**: how to build it, as MSBuild XML
   `Program.cs`     | The source: the entry point of the program
   `obj/`           | Intermediate files, such as the restored NuGet packages

3. [Open Greeter.csproj](:open:Greeter/Greeter.csproj), then [open Program.cs](:open:Greeter/Program.cs).

   Setting          | Means
   -----------------|----------------------------------------------------------
   `Sdk`            | The MSBuild SDK that brings the C# build rules
   `OutputType`     | `Exe` produces a program, a library has none
   `TargetFramework`| `net10.0`, the .NET version the app runs on
   `ImplicitUsings` | Common namespaces, such as `System`, are imported for every file
   `Nullable`       | The compiler warns about a possible `null`

   `Program.cs` is one line: a **top-level statement**, so a small program needs no class or `Main` method.

## Build and run

1. Build, which restores the packages and compiles the code:

   <!-- verify: expect="Build succeeded" -->

   ```bash exec
   cd ~/lab && \
   dotnet build Greeter
   ```

2. Look at the output folder:

   <!-- verify: expect="Greeter.dll" -->

   ```bash exec
   ls ~/lab/Greeter/bin/Debug/${DOTNET_TFM}
   ```

   `Greeter.dll` is the IL assembly of the diagram, and `Greeter` a small launcher for the system.
   `bin/` and `obj/` are generated, and are not committed.

3. Run the project, and then the assembly directly with the runtime:

   <!-- verify: expect="Hello, World!" -->

   ```bash exec
   cd ~/lab && \
   dotnet run --project Greeter && \
   dotnet Greeter/bin/Debug/${DOTNET_TFM}/Greeter.dll
   ```

   `dotnet run` builds first when needed, and `dotnet <file>.dll` is all a machine with only the runtime does.

> [!TIP]
> `dotnet new gitignore` adds a `.gitignore` made for .NET, which keeps `bin/` and `obj/` out of Git.
