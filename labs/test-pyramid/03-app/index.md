# The application

A **quote API**: given a subtotal, it returns the discount and the total.
A subtotal of 100 or more gets 10 % off, and on a sale day, which is every Friday, 5 % more.

The code is small on purpose, so the tests are the subject.
One thing makes it hard to test: the sale depends on **today's date**.
It hides behind an interface, `IPromotions`, so a test can replace it.

## Create it

1. Create a solution and a web project, add the project to the solution:

   <!-- verify: expect="added to the solution" -->

   ```bash exec
   mkdir -p ~/lab && cd ~/lab && \
   dotnet new sln -n Shop && \
   dotnet new web -o Shop && \
   dotnet sln add Shop
   ```

2. Write the quote logic:

   ```bash exec
   cd ~/lab && \
   cat > Shop/Quote.cs <<'EOT'
   namespace Shop;

   public record Quote(decimal Subtotal, decimal Discount, decimal Total);

   public interface IPromotions
   {
       bool IsSale();
   }

   public class FridayPromotions : IPromotions
   {
       public bool IsSale() => DateTime.UtcNow.DayOfWeek == DayOfWeek.Friday;
   }

   public class QuoteService(IPromotions promotions)
   {
       public Quote For(decimal subtotal)
       {
           var rate = subtotal >= 100m ? 0.10m : 0m;
           if (promotions.IsSale())
           {
               rate += 0.05m;
           }

           var discount = Math.Round(subtotal * rate, 2);
           return new Quote(subtotal, discount, subtotal - discount);
       }
   }
   EOT
   ```

   [Open Quote.cs](:open:Shop/Quote.cs): `QuoteService` receives an `IPromotions` in its constructor, and never reads the clock itself.
   `FridayPromotions` is the only class that does.

3. Expose it as a route, and as a small page that shows a quote:

   ```bash exec
   cd ~/lab && \
   cat > Shop/Program.cs <<'EOT'
   using Shop;

   var builder = WebApplication.CreateBuilder(args);
   builder.Services.AddSingleton<IPromotions, FridayPromotions>();
   builder.Services.AddSingleton<QuoteService>();

   var app = builder.Build();

   app.MapGet("/quote", (decimal subtotal, QuoteService quotes) => quotes.For(subtotal));

   app.MapGet("/", () => Results.Content("""
       <!DOCTYPE html>
       <title>Shop</title>
       <h1>Quote</h1>
       <p id="total">...</p>
       <script>
         fetch("/quote?subtotal=120")
           .then(response => response.json())
           .then(quote => document.getElementById("total").textContent = "Total: " + quote.total);
       </script>
       """, "text/html"));

   app.Run();
   EOT
   ```

   [Open Program.cs](:open:Shop/Program.cs): the services are registered, then the route `/quote` and the page `/` are mapped.
   The page asks the API for the quote of 120, and writes the total in the page.

## Run it

1. Start it in the background, and call the API.
   120 is above 100, so the discount is 12, or 18 on a Friday:

   <!-- verify: timeout=180 expect="discount" -->

   ```bash exec
   cd ~/lab && \
   ASPNETCORE_ENVIRONMENT=Development nohup dotnet run --project Shop --no-launch-profile --urls "http://localhost:${SHOP_PORT}" > ~/shop.log 2>&1 &
   wget -qO- --retry-connrefused --tries=60 --waitretry=1 "http://localhost:${SHOP_PORT}/quote?subtotal=120"; echo
   ```

2. Stop it, which also frees the port for the end-to-end test:

   ```bash exec
   pkill -f "dotnet run --project Shop"
   ```

> [!NOTE]
> A manual call proves it works once, today.
> The tests of the next steps prove it on every change, and on every day of the week.
