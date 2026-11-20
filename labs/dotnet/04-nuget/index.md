# NuGet package

A library is shared as a **NuGet package**, a versioned archive published on [nuget.org](https://www.nuget.org).
[Humanizer](https://www.nuget.org/packages/Humanizer.Core) turns text and numbers into human-readable ones, such as `ada lovelace` into `Ada Lovelace`.

## Add a package

1. Add it to the project, with its version:

   <!-- verify: requires=network timeout=120 expect="added to file" -->

   ```bash exec
   cd ~/lab && \
   dotnet add Greeter package Humanizer.Core --version "${HUMANIZER_VERSION}"
   ```

2. [Open Greeter.csproj](:open:Greeter/Greeter.csproj): the command added a `PackageReference`.
   The package is downloaded at the next build, by `dotnet restore`, into a cache shared by every project of the user.

   > [!NOTE]
   > Without `--version`, the latest stable version is added.
   > A package is code that runs with the rights of the application, so it comes from a publisher the team trusts.

3. List the packages of the project, and look for known vulnerabilities:

   <!-- verify: requires=network timeout=120 expect="Humanizer.Core" -->

   ```bash exec
   cd ~/lab && \
   dotnet list Greeter package && \
   dotnet list Greeter package --vulnerable
   ```

## Use it

1. Put the greeting in its own class, which uses the package, and call it from `Program.cs`:

   ```bash exec
   cd ~/lab && \
   cat > Greeter/Greeting.cs <<'EOT'
   using Humanizer;

   namespace Greeter;

   public static class Greeting
   {
       public static string For(string name) => $"Hello, {name.Titleize()}!";
   }
   EOT
   cat > Greeter/Program.cs <<'EOT'
   using Greeter;

   string[] names = ["ada lovelace", "grace hopper", "linus torvalds"];

   foreach (var name in names)
   {
       var message = Greeting.For(name);
       Console.WriteLine(message);
   }
   EOT
   ```

   [Open Greeting.cs](:open:Greeter/Greeting.cs) and [open Program.cs](:open:Greeter/Program.cs).

2. Run it:

   <!-- verify: expect="Hello, Grace Hopper!" -->

   ```bash exec
   cd ~/lab && \
   dotnet run --project Greeter
   ```
