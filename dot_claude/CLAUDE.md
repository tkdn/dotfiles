# Top-Level Rules

- To maximize efficiency, **if you need to execute multiple independent processes, invoke those tools concurrently, not sequentially**.
- **You must think exclusively in English**. However, you are required to **respond in Japanese**.
- Do not arbitrarily modify domain-specific terms such as code comments, variable names, or function names, or extend existing terms.
  - If you are unsure about naming conventions, consult your supervisor.

# Bug Fix Workflow

When fixing a bug, always follow this order:

1. **Write a regression test first** — reproduce the bug and confirm it FAILs
2. **Implement the fix** — confirm the test PASSes

Apply the same order when writing a plan in plan mode.

# Rules for Each Programming Language

## Ruby（Rails） Projects

- **IMPORTANT**: If the project has a `.devcontainer/` directory, skip `rspec` and `rubocop` execution. Instead, inform the user that their supervisor should handle testing and linting.
- After your task is completed (if no `.devcontainer/` exists):
  - Run `rspec`
  - Run `rubocop`

## Go Projects

- After your task completed, do the following:
  - `go test`
  - `golangci-lint`

## Angular Projects

### Workaround for testing Injectable classes that depend on InjectionToken (e.g. FeatureFlag)

**Do not use this pattern in normal cases.** Only apply when a class uses `inject()` to reference an `InjectionToken` and must be instantiated with `new` in a test.

```typescript
function factoryXxxState() {
  return runInInjectionContext(
    Injector.create({ providers: [provideFeatureFlag()] }),
    () => new XxxState()
  );
}
```

- Keeps `setup()` and existing `provide*` functions unchanged
- Encapsulates the DI context requirement inside the factory function, keeping test bodies simple
- **For normal Injectables, always use `TestBed` instead**
