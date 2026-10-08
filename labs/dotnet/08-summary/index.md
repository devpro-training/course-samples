# Summary

---

## CLI cheat sheet

Command                                | Does
---------------------------------------|----------------------------------------
`dotnet --info`                        | SDK, runtimes and operating system
`dotnet --list-sdks`, `--list-runtimes` | What is installed
`dotnet new list`                      | The templates
`dotnet new console -o <name>`         | A new console project
`dotnet new webapp`, `webapi`           | A website, a web API
`dotnet new sln`, `dotnet sln add <p>` | A solution, and a project in it
`dotnet add <p> package <id>`          | A NuGet package in a project
`dotnet add <p> reference <q>`         | A reference to another project
`dotnet restore`, `dotnet build`       | Download packages, compile
`dotnet run --project <p>`             | Build and run
`dotnet test`                          | Run the tests
`dotnet publish -c Release`            | The files to deploy

---

## Good practices

- Pin the SDK of a repository with a `global.json` (`dotnet new globaljson`), so every machine and the CI build with the same one.

- Pin package versions, and check them with `dotnet list package --outdated` and `--vulnerable`.

- Choose an LTS for an application that lives for years, and move to the next one before the end of support.

- Keep `bin/` and `obj/` out of Git with `dotnet new gitignore`.

- Run `dotnet build` and `dotnet test` in the CI exactly as on a developer machine.

- Keep the logic in classes that a test project can call, and `Program.cs` thin.

---

## Visual Studio and Rider

- **Visual Studio**, by Microsoft, on Windows: the full IDE, with designers and profilers.
  The Community edition is free for individuals, academia and open source, with limits for organizations.

- **JetBrains Rider**: a cross-platform .NET IDE, with ReSharper's analysis built in.

- Neither is needed here: the whole course ran from the command line, and a solution opens in both.

---

## Next

- Automated testing, the test pyramid: unit, integration and end-to-end tests, starting from the xUnit project of this lab.

- The [.NET documentation](https://learn.microsoft.com/dotnet/) and the [C# documentation](https://learn.microsoft.com/dotnet/csharp/).
