# Integration test

An integration test starts several components together, real ones, and checks that they work as a whole.
For a web API, that means the routes, the parameter binding, the dependency injection and the JSON, which no unit test of `QuoteService` touches.

`WebApplicationFactory` starts the application **in memory**, with a test server: no port, no network, and a client that calls it like a browser would.

## Create the test project

1. Create the project, add it to the solution, and make it reference the application:

   <!-- verify: expect="added to the project" -->

   ```bash exec
   cd ~/lab && \
   dotnet new xunit -o Shop.IntegrationTests && \
   rm Shop.IntegrationTests/UnitTest1.cs && \
   dotnet sln add Shop.IntegrationTests && \
   dotnet add Shop.IntegrationTests reference Shop
   ```

2. Add the package that provides `WebApplicationFactory`, and switch the project to the web SDK, as the documentation asks:

   <!-- verify: requires=network timeout=120 expect="added to file" -->

   ```bash exec
   cd ~/lab && \
   sed -i 's|Sdk="Microsoft.NET.Sdk"|Sdk="Microsoft.NET.Sdk.Web"|' Shop.IntegrationTests/Shop.IntegrationTests.csproj && \
   dotnet add Shop.IntegrationTests package Microsoft.AspNetCore.Mvc.Testing --version "${MVC_TESTING_VERSION}"
   ```

   [Open Shop.IntegrationTests.csproj](:open:Shop.IntegrationTests/Shop.IntegrationTests.csproj): the `Sdk` and the package.
   The package copies the dependencies of the application next to the tests, and sets the content root to the application's folder.

3. The top-level statements of `Program.cs` generate an internal `Program` class, which the factory needs to see.
   Make it public, with a partial declaration, as the documentation does:

   ```bash exec
   cd ~/lab && \
   echo 'public partial class Program;' >> Shop/Program.cs
   ```

## Write and run the tests

1. Write two tests.
   The first replaces the real promotions with a fake, for this test only, and checks a whole HTTP exchange.
   The second checks a request with no `subtotal`:

   ```bash exec
   cd ~/lab && \
   cat > Shop.IntegrationTests/QuoteApiTests.cs <<'EOT'
   using System.Net;
   using System.Net.Http.Json;
   using Microsoft.AspNetCore.Mvc.Testing;
   using Microsoft.AspNetCore.TestHost;
   using Microsoft.Extensions.DependencyInjection;

   namespace Shop.IntegrationTests;

   public class QuoteApiTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
   {
       private class NoSale : IPromotions
       {
           public bool IsSale() => false;
       }

       [Fact]
       public async Task GetQuote_ReturnsTheQuoteAsJson()
       {
           var client = factory
               .WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
                   services.AddSingleton<IPromotions, NoSale>()))
               .CreateClient();

           var quote = await client.GetFromJsonAsync<Quote>("/quote?subtotal=120");

           Assert.Equal(new Quote(120m, 12m, 108m), quote);
       }

       [Fact]
       public async Task GetQuote_WithoutSubtotal_IsABadRequest()
       {
           var response = await factory.CreateClient().GetAsync("/quote");

           Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
       }
   }
   EOT
   ```

   [Open QuoteApiTests.cs](:open:Shop.IntegrationTests/QuoteApiTests.cs): `ConfigureTestServices` runs after the registrations of `Program.cs`, so the fake wins.
   Everything else is real: the routing, the binding of `subtotal`, `QuoteService`, the JSON.

2. Run them, and compare the duration with the unit tests:

   <!-- verify: expect="Shop.IntegrationTests.dll" -->

   ```bash exec
   cd ~/lab && \
   dotnet test Shop.IntegrationTests
   ```

   Starting the application, even in memory, costs hundreds of milliseconds, against a few for the unit tests.
   It is why there are fewer of them.

> [!NOTE]
> The `NoSale` fake is still needed: the real `FridayPromotions` would make the first test fail on Fridays.
> An integration test replaces what it cannot control, the clock, and keeps the rest.
> In a real application, the same technique replaces what is outside the team's control, such as a payment provider or an e-mail service.
