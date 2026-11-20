# Unit test

A unit test calls one class with known inputs, and checks the result.
It is the base of the pyramid: many, fast, and a failure points to the line.

`QuoteService` needs an `IPromotions`.
The real one reads the clock, so a test that used it would pass on a Monday and fail on a Friday.
The test gives it a **fake** instead.

## Create the test project

1. Create the project, add it to the solution, and make it reference the application:

   <!-- verify: expect="added to the project" -->

   ```bash exec
   cd ~/lab && \
   dotnet new xunit -o Shop.UnitTests && \
   rm Shop.UnitTests/UnitTest1.cs && \
   dotnet sln add Shop.UnitTests && \
   dotnet add Shop.UnitTests reference Shop
   ```

## Write and run the tests

1. Write the tests, with a fake of `IPromotions` and four cases:

   ```bash exec
   cd ~/lab && \
   cat > Shop.UnitTests/QuoteServiceTests.cs <<'EOT'
   namespace Shop.UnitTests;

   public class QuoteServiceTests
   {
       private class FakePromotions(bool sale) : IPromotions
       {
           public bool IsSale() => sale;
       }

       [Theory]
       [InlineData(99.99, false, 0)]
       [InlineData(100, false, 10)]
       [InlineData(120, true, 18)]
       [InlineData(50, true, 2.5)]
       public void For_AppliesTheDiscount(decimal subtotal, bool sale, decimal discount)
       {
           var quote = new QuoteService(new FakePromotions(sale)).For(subtotal);

           Assert.Equal(discount, quote.Discount);
           Assert.Equal(subtotal - discount, quote.Total);
       }
   }
   EOT
   ```

   [Open QuoteServiceTests.cs](:open:Shop.UnitTests/QuoteServiceTests.cs): the four cases cover both sides of the 100 threshold, and the sale with and without the threshold.
   The test says `sale`, never a date: the fake decides.

2. Run them, and read the duration:

   <!-- verify: expect="Shop.UnitTests.dll" -->

   ```bash exec
   cd ~/lab && \
   dotnet test Shop.UnitTests
   ```

   The four tests take a few milliseconds, because nothing starts: no server, no network, no file.

3. Break the rule on purpose, a threshold of 101, and read the failure:

   <!-- verify: expect="failed: 1, succeeded: 3" -->

   ```bash exec
   cd ~/lab && \
   sed -i 's/subtotal >= 100m/subtotal >= 101m/' Shop/Quote.cs && \
   { dotnet test Shop.UnitTests || true; }
   ```

   The report names the failing case, `100`, with the expected and the actual discount.
   It is the whole point of a unit test: the failure is in `Quote.cs`, no search needed.

4. Restore the rule:

   <!-- verify: expect="failed: 0, succeeded: 4" -->

   ```bash exec
   cd ~/lab && \
   sed -i 's/subtotal >= 101m/subtotal >= 100m/' Shop/Quote.cs && \
   dotnet test Shop.UnitTests
   ```

> [!TIP]
> `Arrange, Act, Assert` is the usual shape of a test: set up the inputs, call the code, check the result.
> A mocking library, such as Moq or NSubstitute, generates what `FakePromotions` does by hand, and is worth adding when the fakes multiply.
