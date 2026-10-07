# The pyramid at work

Each layer exists because it catches what the one below cannot.
Three tests are run, then a bug is introduced at the level where only one layer can see it.

## Run every layer

1. Run the whole solution: `dotnet test` runs every test project, and prints one line per project.

   <!-- verify: expect="Shop.IntegrationTests.dll" -->

   ```bash exec
   cd ~/lab && \
   dotnet test
   ```

   Compare the durations: milliseconds for the unit tests, hundreds of milliseconds for the integration tests.
   The end-to-end test is a script, run on its own, since it needs a free port and a browser.

2. A project can also be run alone, which is the usual loop while coding:

   <!-- verify: expect="Shop.UnitTests.dll" -->

   ```bash exec
   cd ~/lab && \
   dotnet test Shop.UnitTests
   ```

## A bug only integration sees

1. Remove the registration of `IPromotions` from `Program.cs`, a one-line slip that no unit test of `QuoteService` can notice:

   ```bash exec
   cd ~/lab && \
   sed -i '/AddSingleton<IPromotions/d' Shop/Program.cs
   ```

   [Open Program.cs](:open:Shop/Program.cs): `QuoteService` is registered, and its dependency is not.

2. Run the tests:

   <!-- verify: expect="Unable to resolve service for type" -->

   ```bash exec
   cd ~/lab && \
   { dotnet test || true; }
   ```

   The unit tests pass: `QuoteService` is fine, and it never needed the container.
   The integration test fails, with the service that cannot be built: the **wiring** is wrong, which only a test that starts the application can see.

3. Put the line back:

   <!-- verify: expect="failed: 0, succeeded: 2" -->

   ```bash exec
   cd ~/lab && \
   sed -i 's|^builder.Services.AddSingleton<QuoteService>();|builder.Services.AddSingleton<IPromotions, FridayPromotions>();\n&|' Shop/Program.cs && \
   dotnet test Shop.IntegrationTests
   ```

## A bug only end-to-end sees

1. Misspell the route that the page calls, `/quotes` instead of `/quote`, in the JavaScript of the page:

   ```bash exec
   cd ~/lab && \
   sed -i 's|fetch("/quote?|fetch("/quotes?|' Shop/Program.cs
   ```

2. Run the unit and the integration tests, which still pass: the API is correct, and no test loads the page.

   <!-- verify: expect="failed: 0, succeeded: 6" -->

   ```bash exec
   cd ~/lab && \
   dotnet test
   ```

3. Run the end-to-end test, which loads the page in a browser:

   <!-- verify: timeout=180 expect="FAIL: the browser does not show the total" -->

   ```bash exec
   cd ~/lab && \
   { ./e2e.sh "${SHOP_PORT}" || true; }
   ```

   The page shows `...`: its request got a 404, and the total never appeared.
   Only a test that runs the page can see a bug that lives in the page.

4. Fix the route, and run it again:

   <!-- verify: timeout=180 expect="PASS: the browser shows the total" -->

   ```bash exec
   cd ~/lab && \
   sed -i 's|fetch("/quotes?|fetch("/quote?|' Shop/Program.cs && \
   ./e2e.sh "${SHOP_PORT}"
   ```

> [!NOTE]
> The three tests do not overlap: each failure above was seen by one layer, and missed by the ones below.
> It is also why the pyramid is narrow at the top: the end-to-end test took seconds to find a typo that a faster test could have found, had one existed.
> The lesson is to cover each rule at the lowest layer that can see it.
