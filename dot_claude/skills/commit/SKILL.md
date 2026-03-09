---
name: commit
description: Creates logical, well-structured git commits following conventional commits. Use this skill whenever the user wants to commit changes, stage files, write commit messages, or organize work into logical commits — even if they just say "commit this", "make a commit", or "let's commit".
disable-model-invocation: true
---

# Conventional Commits format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`, `style`, `perf`, `ci`, `build`

Examples:
- `feat: send an email to the customer when a product is shipped`
- `feat(api)!: send an email to the customer when a product is shipped`
- `docs: correct spelling of CHANGELOG`
- `fix: double submit issue on foobar feature`
- `chore: tweak testcase name`

# Steps

## 1. Review current changes

```bash
git branch --show-current
git status
git diff
git diff --cached
```

## 1.5. Safety check: Verify not on main branch

After reviewing the current branch, check if you're on a protected branch (main or master):

- If the current branch is `main` or `master`, **STOP immediately** and warn the user:
  ```
  ⚠️ WARNING: You are currently on the '${BRANCH_NAME}' branch.

  It's recommended to create feature branches for new work rather than
  committing directly to main/master.

  Would you like to:
  1. Create a new branch and switch to it
  2. Continue anyway (not recommended)
  3. Cancel this operation
  ```
  Wait for the user's response before proceeding.

- If on any other branch, proceed to Step 2.

## 2. Analyze changes and plan commits

Consider the following when deciding how to split changes into commits:

- Each commit must keep the codebase in a working state (don't break CI or builds)
- Make granularity easy for reviewers to follow step by step
- Respect dependency order: changes that others depend on come first
- If a single file has multiple unrelated changes, stage only the relevant portions using `git add -p`
- Each commit must be self-contained and independently revertable
- Focus commit messages on *why*, not just *what*
- If changes are based on PR review comments, include the comment link in the commit body (add after body with a blank line separator)

## 3. Present commit plan and obtain approval

Present the plan clearly, then wait for explicit approval before doing anything.

```
Commit Plan:

1. feat(auth): add user authentication feature
   - apps/api/src/features/auth/login-usecase.ts
   - apps/api/src/features/auth/route.ts

2. test(auth): add authentication test cases
   - apps/api/src/features/auth/login-usecase.spec.ts

3. docs(api): update API documentation
   - docs/api/authentication.md

4. chore(deps): add authentication libraries
   - package.json
   - pnpm-lock.yaml

Do you approve this commit plan? (y/n)
If changes are needed, please specify what adjustments are required.
```

If the user requests changes to the plan, revise and re-present for approval. Repeat until approved.

## 4. Create commits

For each commit in the approved plan:

```bash
git add [changed-files]
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<detailed explanation of what was changed and why>

<GitHub comment link if applicable>

Co-Authored-By: <reviewer-name> <email> (if significant contribution)
EOF
)"
```

## 5. Verify each signed commit

After each commit, verify it was signed correctly:

```bash
git verify-commit HEAD || exit 1
```
