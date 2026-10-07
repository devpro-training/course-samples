<!-- include: ../../shared/setup.md -->

## On a workstation

The .NET SDK is installed system-wide with the installer of the system, which needs administrator rights.

System         | Command
---------------|--------------------------------------------------------------------------
Windows        | `winget install Microsoft.DotNet.SDK.10`
macOS          | The installer package of the download page
Debian         | `sudo apt-get install -y dotnet-sdk-10.0`, once the Microsoft package feed is added
Other Linux    | The package manager of the distribution, or the script used below

[learn.microsoft.com/dotnet/core/install](https://learn.microsoft.com/dotnet/core/install/) is the reference for every system.

The lab has no administrator rights, so the SDK is installed in the home directory.

<!-- include: ../../shared/setup-dotnet.md -->
