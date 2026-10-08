# .NET

Build and test a C# application with the .NET SDK, from the command line.

---

## What is .NET

- A free, open source (MIT) developer platform, by Microsoft and the .NET Foundation.

- Runs on Windows, Linux and macOS, on x64 and Arm.

- **C#** is the main language, with F# and Visual Basic also supported.

- Used for web APIs, websites, command line tools, services, desktop and mobile applications.

- Not **.NET Framework**: the older, Windows-only product, which only receives fixes.
  ".NET" is its cross-platform successor, once called ".NET Core".

---

## From source to a running program

![C# source is built into an IL assembly, which the runtime compiles to machine code](../assets/dotnet-build-dark.svg#gh-dark-mode-only)
![C# source is built into an IL assembly, which the runtime compiles to machine code](../assets/dotnet-build.svg#gh-light-mode-only)

---

## SDK or runtime

|           | SDK                                                  | Runtime                         |
|-----------|------------------------------------------------------|---------------------------------|
| Used to   | Create, build, test and publish                      | Run an application              |
| Contains  | Compiler, `dotnet` CLI, templates, **and a runtime** | The runtime and its libraries   |
| Installed on | A developer machine, a build agent                | A server, a container image     |

- The **ASP.NET Core runtime** adds the web libraries to the runtime.

- An application can also be published **self-contained**, with its own copy of the runtime.

---

## LTS or STS

Version | Type | Latest patch | Released | End of support
--------|------|--------------|----------|----------------
.NET 10 | LTS  | 10.0.12      | 2025-11-11 | 2028-11-14
.NET 9  | STS  | 9.0.20       | 2024-11-12 | 2026-11-10
.NET 8  | LTS  | 8.0.31       | 2023-11-14 | 2026-11-10

- A new major version is released every November, and the quality is the same for both types.

- **LTS**, Long Term Support, is supported for 3 years, **STS**, Standard Term Support, for 2 years.

- The lab uses the SDK [[ DOTNET_SDK_VERSION ]], the latest of .NET 10, the current LTS.

- .NET 11 is at release candidate, and ships in November 2026.

Source: the [.NET support policy](https://dotnet.microsoft.com/platform/support/policy/dotnet-core), on 2026-10-07.

---

## In this lab

Topic          | What
---------------|-------------------------------------------------------------
Console app    | `dotnet new`, the project files, `dotnet build`, `dotnet run`
NuGet          | `dotnet add package`
Unit test      | An xUnit project, `dotnet test`
Web app        | `dotnet new webapp`, Razor Pages
Web API        | `dotnet new webapi`, minimal APIs and OpenAPI
