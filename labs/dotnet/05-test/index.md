# Unit test

A unit test calls a small piece of code with known inputs, and checks the result.
It is the base of the test pyramid, the subject of the next course.

[xUnit](https://xunit.net) is the framework of the .NET documentation's unit testing tutorial, and MSTest and NUnit are the other common ones.

## A solution with two projects

1. Create a **solution**, which groups the projects so a single command builds or tests them all, and add the app to it:

   <!-- verify: expect="added to the solution" -->

   ```bash exec
   cd ~/lab && \
   dotnet new sln -n Greeter && \
   dotnet sln add Greeter
   ```

   > [!NOTE]
   > The solution file is `Greeter.slnx`, the XML format that is the default since .NET 10.
   > Earlier SDKs create `Greeter.sln`, which `--format sln` still asks for.

2. Create the test project, add it to the solution, and make it reference the app:

   <!-- verify: expect="added to the project" -->

   ```bash exec
   cd ~/lab && \
   dotnet new xunit -o Greeter.Tests && \
   rm Greeter.Tests/UnitTest1.cs && \
   dotnet sln add Greeter.Tests && \
   dotnet add Greeter.Tests reference Greeter
   ```

3. [Open Greeter.Tests.csproj](:open:Greeter.Tests/Greeter.Tests.csproj): the packages of xUnit and its test runner are there, and a `ProjectReference` to `Greeter`.

## Write and run a test

1. Write a test with two sets of inputs:

   ```bash exec
   cd ~/lab && \
   cat > Greeter.Tests/GreetingTests.cs <<'EOT'
   namespace Greeter.Tests;

   public class GreetingTests
   {
       [Theory]
       [InlineData("ada lovelace", "Hello, Ada Lovelace!")]
       [InlineData("GRACE HOPPER", "Hello, Grace Hopper!")]
       public void For_ReturnsTitleCasedGreeting(string name, string expected)
       {
           Assert.Equal(expected, Greeting.For(name));
       }
   }
   EOT
   ```

   [Open GreetingTests.cs](:open:Greeter.Tests/GreetingTests.cs): `[Fact]` marks a test without input, `[Theory]` with `[InlineData]` runs the same test for each set.

2. Run every test of the solution:

   <!-- verify: expect="failed: 0, succeeded: 2" -->

   ```bash exec
   cd ~/lab && \
   dotnet test
   ```

   In a terminal, the last lines give the **Test summary**: the total, and how many tests failed, succeeded or were skipped.
   Without a terminal, such as in a CI log, the same result is a single `Passed!` or `Failed!` line.

3. Break the expected text on purpose, and read the failure:

   <!-- verify: expect="failed: 1, succeeded: 1" -->

   ```bash exec
   cd ~/lab && \
   sed -i 's/Hello, Ada Lovelace!/Hi, Ada Lovelace!/' Greeter.Tests/GreetingTests.cs && \
   { dotnet test || true; }
   ```

   The report names the failing test, its input, the expected and the actual values.

4. Restore the text, and check that the tests pass again:

   <!-- verify: expect="failed: 0, succeeded: 2" -->

   ```bash exec
   cd ~/lab && \
   sed -i 's/Hi, Ada Lovelace!/Hello, Ada Lovelace!/' Greeter.Tests/GreetingTests.cs && \
   dotnet test
   ```

> [!TIP]
> `dotnet test --filter "FullyQualifiedName~GreetingTests"` runs a subset, and `dotnet test` exits with a non-zero code on a failure, which is what a CI pipeline looks at.
