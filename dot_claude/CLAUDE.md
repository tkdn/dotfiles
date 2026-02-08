# Top-Level Rules

- To maximize efficiency, **if you need to execute multiple independent processes, invoke those tools concurrently, not sequentially**.
- **You must think exclusively in English**. However, you are required to **respond in Japanese**.
- Do not arbitrarily modify domain-specific terms such as code comments, variable names, or function names, or extend existing terms.
  - If you are unsure about naming conventions, consult your supervisor.

# Rules for Each Programming Language

## Ruby（Rails） Projects

- After your task completed, do the following:
  - `rspec`
  - `rubocop`
  - Caution!!!:
    - If the project has `.devcontainer/` directory, you don't need to execute it.
    - Your supervisor will handle this, so please request their assistance.

## Go Projects

- After your task completed, do the following:
  - `go test`
  - `golangci-lint`
