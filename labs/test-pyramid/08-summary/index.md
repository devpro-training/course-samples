# Summary

---

## Cheat sheet

Command                                          | Does
-------------------------------------------------|----------------------------------------------
`dotnet new xunit -o <name>`                     | A test project
`dotnet add <tests> reference <app>`             | Makes the application visible to the tests
`dotnet test`                                    | Runs every test project of the solution
`dotnet test <project>`                          | Runs one project
`dotnet test --filter "FullyQualifiedName~Quote"` | Runs the tests whose name contains `Quote`
`dotnet test --collect:"XPlat Code Coverage"`    | Also writes a coverage report, `coverage.cobertura.xml`
`google-chrome --headless=new --dump-dom <url>`  | The page, after its JavaScript has run

---

## Choosing the layer

Question                                   | Layer
-------------------------------------------|------------------
Is this rule, this calculation, right?     | Unit
Are the routes, the binding, the wiring right? | Integration
Does the user journey work in a browser?   | End-to-end

- Cover each rule at the **lowest** layer that can see it.

- Replace what is not under control in a test, the clock, a payment provider, and nothing more.

- A failing test names a cause: the lower the layer, the closer the name is to the line.

---

## Good practices

- Many unit tests, some integration tests, a handful of end-to-end tests.

- A test is independent: no order, no shared state, the same result every day.

- A flaky test, one that fails sometimes with no change, is fixed or deleted, since a team learns to ignore it.

- Run the fast layers on every save, and the whole pyramid on every push, in the CI pipeline.

- Watch for the **ice cream cone**, the pyramid turned upside down: mostly manual and end-to-end tests, few unit tests, slow feedback.

- Coverage tells which lines no test runs, not that the others are tested well.

---

## Next

- GitHub, then CI/CD: the pipeline that runs `dotnet test` on every push.

- Playwright: the browser automation behind a real end-to-end test.

- Further reading: [Testing in .NET](https://learn.microsoft.com/dotnet/core/testing/) and Martin Fowler's [Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html).
