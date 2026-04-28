---
name: fix-issue
description: >
  Fix a GitHub issue end-to-end: read the issue, explore the codebase, implement the fix with a regression test, then open a draft PR.
  Use this skill when the user says "fix issue #N", "このissueを直して", "issueを対応して", or provides a GitHub issue URL.
  Also use when the user describes a bug symptom inline (e.g. "/fix-issue ログイン後にセッションが切れる").
disable-model-invocation: true
---

# Fix GitHub Issue

Fix a GitHub issue from start to finish, following the project's Bug Fix Workflow.

## Step 1: Determine the issue source

`$ARGUMENTS` can be:
- An issue number (e.g. `123`)
- A GitHub issue URL (e.g. `https://github.com/org/repo/issues/123`)
- A natural-language bug description (e.g. `ログイン後にセッションが切れる`)
- Empty

**If it's a number or URL**, fetch the issue directly:
```bash
gh issue view $ARGUMENTS
```

**If it's a natural-language description or empty**, first search for a matching issue:
```bash
gh issue list --state open --search "$ARGUMENTS" --limit 10
```
Present the results to the user and ask which issue to fix — or confirm they want to proceed with only the inline description (no linked issue).

**STOP HERE if issue is ambiguous. Do NOT proceed until confirmed.**

After reading the issue, summarize:
- What is the reported problem?
- What is the expected behavior?
- Are there reproduction steps or error messages?

## Step 2: Explore in Plan Mode

Enter Plan Mode. Investigate the codebase to understand:
- Which files are involved?
- What is the root cause?
- Are there existing tests for this area?

Use subagents for broad investigation to avoid filling main context:
```
Use subagents to investigate how [relevant component] works and find the root cause of [problem].
```

## Step 3: Plan the fix

Still in Plan Mode, create a plan that includes:
1. The regression test to write (and why it will FAIL before the fix)
2. The fix implementation
3. Files to modify

Press `Ctrl+G` to review and edit the plan before proceeding.

## Step 4: Implement

Switch to Normal Mode.

1. **Write the regression test first** — confirm it FAILs
2. **Implement the fix** — confirm the test PASSes
3. Run the full test suite for the affected package

For Go projects:
```bash
go test -race -v ./path/to/package/...
```

## Step 5: Commit and open PR

Use the `/commit` skill to create a well-structured commit, then `/create-pr` to open a draft PR.

Reference the issue in the PR body so it auto-closes on merge:
```
Closes #<issue-number>
```
