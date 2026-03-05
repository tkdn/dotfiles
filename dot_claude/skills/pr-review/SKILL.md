---
name: pr-review
description: >
  Review a Pull Request on the current branch and output a structured Markdown report.
  Use this skill whenever the user asks to review a PR, check a pull request, do a code review,
  レビューして, PRを確認して, or any similar request — even if they don't say "PR review" explicitly.
  Covers security, performance, code quality, testing, and framework-specific concerns
  (Ruby on Rails, Go, Python, Java, React, Angular, Vue, Next.js, Nuxt).
  Supports monorepos with multiple tech stacks.
disable-model-invocation: true
---

# Pull Request Review

Review the PR on the current branch against main, then write a structured Markdown report.

## Step 1: Detect Tech Stack

Run the bundled detection script from the repository root:

```bash
bash "$(dirname "$0")/../.claude/skills/pr-review/scripts/detect_stack.sh"
```

> If the skill path is unknown, locate the script with:
> `find ~/.claude/skills/pr-review/scripts -name detect_stack.sh`

The script prints lines like `BACKEND:Ruby on Rails` and `FRONTEND:Angular`.
Collect all results — a monorepo may have multiple backends or frontends.
If nothing is detected, proceed with a general review.

**You decide the review scope** based on what's found — no need to ask the user.
If both backend and frontend stacks are detected, review both.

## Step 2: Load PR Description

```bash
gh pr view
```

Also get the PR number for the output filename:

```bash
PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null || date +%Y%m%d-%H%M%S)
```

## Step 3: Review the Diff

```bash
gh pr diff
```

Apply the review perspectives below based on the detected stacks.

---

## Review Perspectives

Severity levels: **Critical** (must fix), **Warning** (should fix), **Info** (consider).

### Common (All Projects)

#### Code Quality (Info/Warning)
- **Single Responsibility**: Are classes and methods focused on one thing?
- **DRY**: Is duplicate logic extracted appropriately?
- **YAGNI**: Are there unnecessary abstractions or premature optimizations?
- **Defensive Design**: Is the interface as narrow as needed? Does it prevent misuse?

#### Harmony with the Project (Warning)
- **Conventions**: Does the code follow any documented project conventions?
- **Consistency**: Does it fit the existing design patterns and style?
- **Cognitive Load**: Will teammates find this natural to read and maintain?

#### Error Handling (Warning)
- **Exception Handling**: Are there uncaught exceptions or missing error paths?
- **Validation**: Are inputs validated appropriately at boundaries?

#### Testing (Info)
- **Presence**: Are tests added for new features and bug fixes?
- **Coverage**: Are critical paths covered without over-testing trivial code?
- **Quality**: Are assertions specific and proportionate?

#### Security (Critical/Warning)
- **Secrets**: Are passwords, API keys, or tokens hardcoded?
- **Log Output**: Is sensitive data logged in production?
- **Environment Config**: Are environment-specific values hardcoded?
- **Dependencies**: Are any dependencies flagged with known security issues?

#### Naming (Info/Warning)
- **Domain Accuracy**: Do names accurately reflect the domain concepts they represent? Are any terms misleading or imprecise?
- **Consistency with Codebase**: Are names chosen from the vocabulary already used in the codebase, rather than introducing synonyms for existing concepts?
- **Clarity**: Are names self-explanatory without needing a comment to clarify their intent?

#### Other (Info/Warning)
- **Backward Compatibility**: Do any changes break existing API contracts?

---

### Backend: Ruby on Rails

#### Security (Critical)
- **SQL Injection**: Is user input passed directly into SQL queries?
- **Auth**: Are authorization checks present and correct?

#### Performance (Warning)
- **N+1 Queries**: Are associations eager-loaded where needed?
- **Queries in Loops**: Are DB calls inside iteration?
- **Indexes**: Are indexes considered for new query conditions?
- **Caching**: Is in-memory caching used for hot data?

#### API Design (Info/Warning)
- **RESTful**: Does the API follow REST conventions?
- **Naming**: Are endpoints named consistently?

---

### Backend: Go

#### Security (Critical)
- **Input Validation**: Is external input properly validated and sanitized?
- **Auth**: Are authentication and authorization enforced?

#### Performance (Warning)
- **Goroutine Leaks**: Are goroutines properly terminated?
- **Mutex Usage**: Are shared resources protected correctly?
- **Allocations**: Are there unnecessary allocations in hot paths?

#### Error Handling (Warning)
- **Ignored Errors**: Are errors checked everywhere they should be?
- **Error Wrapping**: Are errors wrapped with context using `fmt.Errorf` or `errors.As`?

---

### Backend: Python

#### Security (Critical)
- **Injection**: Is user input sanitized before use in queries or shell commands?
- **Auth**: Are auth checks present?

#### Performance (Warning)
- **ORM N+1**: Are ORM queries optimized (e.g., `select_related`, `prefetch_related`)?
- **Blocking I/O**: Is blocking I/O used in async contexts?

---

### Backend: Java

#### Security (Critical)
- **SQL Injection**: Is parameterized queries or ORM used?
- **Deserialization**: Is untrusted data deserialized?

#### Performance (Warning)
- **Connection Pooling**: Are DB connections managed correctly?
- **Memory Leaks**: Are resources closed (streams, connections)?

---

### Frontend: React

#### Security (Critical)
- **XSS**: Is `dangerouslySetInnerHTML` used with unsanitized input?

#### Performance (Warning)
- **Re-renders**: Are `useMemo`, `useCallback`, `React.memo` used appropriately?
- **Bundle Size**: Is lazy loading considered?
- **Large Lists**: Is virtualization considered for long lists?

#### Memory Management (Warning)
- **Effect Cleanup**: Do `useEffect` hooks clean up subscriptions and timers?

#### Accessibility (Info)
- **ARIA**: Are appropriate ARIA attributes set?
- **Keyboard**: Is the UI fully operable with a keyboard?

---

### Frontend: Angular

#### Security (Critical)
- **XSS**: Is `innerHTML` used without `DomSanitizer`?

#### Performance (Warning)
- **Change Detection**: Is `OnPush` strategy used where appropriate?
- **Bundle Size**: Is lazy loading of modules considered?
- **Large Lists**: Is `CdkVirtualScrollViewport` considered?

#### Memory Management (Warning)
- **Subscriptions**: Are Subscriptions unsubscribed in `ngOnDestroy`, or is `takeUntilDestroyed` / `async` pipe used?

#### Accessibility (Info)
- **ARIA**: Are appropriate ARIA attributes set?
- **Keyboard**: Is the UI fully operable with a keyboard?

---

### Frontend: Vue / Nuxt

#### Security (Critical)
- **XSS**: Is `v-html` used with unsanitized input?

#### Performance (Warning)
- **Computed Properties**: Is `computed` used for derived state instead of methods?
- **Bundle Size**: Is lazy loading of components and routes considered?
- **Large Lists**: Is virtual scrolling considered?

#### Memory Management (Warning)
- **Cleanup**: Are watchers and event listeners cleaned up in `onUnmounted`?

#### Accessibility (Info)
- **ARIA**: Are appropriate ARIA attributes set?
- **Keyboard**: Is the UI fully operable with a keyboard?

---

### Frontend: Next.js

#### Security (Critical)
- **XSS**: Is `dangerouslySetInnerHTML` used with unsanitized input?
- **Server Actions**: Is input validated in Server Actions?

#### Performance (Warning)
- **Rendering Strategy**: Is the right rendering mode chosen (SSR/SSG/ISR/CSR)?
- **Image Optimization**: Is the `next/image` component used?
- **Bundle Size**: Are dynamic imports used where appropriate?

#### Memory Management (Warning)
- **Effect Cleanup**: Do client-side `useEffect` hooks clean up properly?

---

## Step 4: Output

Write the report to the repository root:

```
pr-review-${PR_NUMBER}.md
```

### Output Rules

- **Critical**: Show all findings
- **Warning**: Show up to 10, prioritized by severity
- **Info**: Show up to 5, prioritized by severity
- Keep descriptions concise; avoid verbose phrasing
- Write code examples in the detected tech stack's language

### Output Format

```markdown
# Review Summary

- Critical: N item(s) (all displayed)
- Warning: N item(s) (up to 10 displayed)
- Info: N item(s) (up to 5 displayed)

---

# Review Items

## [Critical]: <title>

- **Location**: path/to/file.rb:12
- **Description**: <concise explanation>

```<lang>
# Affected code
...
```

```<lang>
# Suggested fix
...
```

## [Warning]: <title>

...
```
