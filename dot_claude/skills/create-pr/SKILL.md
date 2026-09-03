---
name: create-pr
description: >
  Create a GitHub Pull Request (draft) based on the current working context.
  Use this skill whenever the user wants to open a PR, create a pull request, submit their work for review,
  or says "PRを作って", "Pull Requestを作成して", "PRを出して", "プルリクを作って" — even if they don't say "draft" explicitly.
  The skill performs a self-review with pr-review before creation and always opens the PR as a draft.
disable-model-invocation: true
---

# Create Pull Request

Create a GitHub Pull Request in draft mode based on the current working context.
Always open as draft — never merge-ready — so the author can signal it's ready later.

## Step 1: Verify branch

```bash
git branch --show-current
```

If on `main` or `master`, stop immediately and warn the user:

```
WARNING: You are on 'main'. Please switch to a feature branch before opening a PR.
```

Also confirm there are commits ahead of main:

```bash
git log main..HEAD --oneline
```

If there are no commits, stop and inform the user there is nothing to include in a PR.

Confirm the current branch has been pushed to origin:

```bash
git status --short --branch
```

If the output shows `## <branch>...origin/<branch>` the branch exists on origin — proceed.
If there is no tracking branch (e.g. `## <branch>` with no `...origin/...`), stop and inform the user:

```
WARNING: The current branch has not been pushed to origin yet.
Please push the branch first:

  git push -u origin <branch>

Then run this skill again.
```

## Step 2: Gather context

Collect information to fill the PR template:

```bash
# Commits on this branch
git log main..HEAD --oneline

# Changed files
git diff main...HEAD --name-only

# Branch name (often contains ticket/issue info)
git branch --show-current
```

Also check if a PR template exists:

```bash
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

## Step 3: Draft the PR body

Fill in each section of the PR template based on the context gathered above.

**If `.github/PULL_REQUEST_TEMPLATE.md` exists**, follow its structure exactly, filling
sections analogous to the ones below (レビュー期日 / 関連リンク / やりたいこと / なぜなのか /
やったこと / やらなかったこと / 見てほしいところ / 確認方法):

| Section | How to fill |
|---|---|
| レビュー期日 | Leave blank (user fills this in) |
| 関連リンク | Extract from branch name, commit messages, or leave blank |
| やりたいこと | Summarize the goal of this branch in 1–2 sentences |
| なぜなのか | Explain the motivation or problem being solved |
| やったこと | List concrete changes made (files, logic, DB, etc.). Do NOT include specific file counts (e.g. "32ファイル") — describe what changed, not how many. |
| やらなかったこと | Note explicitly out-of-scope items if relevant |
| 見てほしいところ | Areas of uncertainty or design decisions you are unsure about. Self-review runs after PR creation, so leave blank or provisional for now |
| 確認方法 | Describe how to verify the changes work |

**If `.github/PULL_REQUEST_TEMPLATE.md` does not exist**, do not invent ad-hoc section
names and do not silently reuse the Japanese table above as a default. Two fallback
heading sets are available — Japanese and English. Ask the user which one to use before
drafting:

```
No PR template found in this repository (.github/PULL_REQUEST_TEMPLATE.md).
Which heading language should the PR body use?

1. Japanese (やりたいこと / なぜなのか / やったこと / やらなかったこと / 確認方法)
2. English (What / Why / Changes / Out of Scope / How to Verify)
```

**STOP HERE. Do NOT proceed until the user picks one.**

Japanese fallback headings:

| Section | How to fill |
|---|---|
| やりたいこと | Summarize the goal of this branch in 1–2 sentences |
| なぜなのか | Explain the motivation or problem being solved |
| やったこと | List concrete changes made (files, logic, DB, etc.). Do NOT include specific file counts (e.g. "32ファイル") — describe what changed, not how many. |
| やらなかったこと | Note explicitly out-of-scope items if relevant |
| 確認方法 | Describe how to verify the changes work |

English fallback headings:

| Section | How to fill |
|---|---|
| What | Summarize the goal of this branch in 1–2 sentences |
| Why | Explain the motivation or problem being solved |
| Changes | List concrete changes made (files, logic, DB, etc.). Do NOT include specific file counts (e.g. "32 files") — describe what changed, not how many. |
| Out of Scope | Note explicitly out-of-scope items if relevant |
| How to Verify | Describe how to verify the changes work |

The fallback sets omit レビュー期日 / 関連リンク and 見てほしいところ — those are specific to
this project's own template, not general-purpose defaults.

Keep each section concise. Prefer bullet points over prose where appropriate.

**Formatting rules for the PR body:**
- Do NOT use bold (`**text**`) anywhere in the PR body
- If you feel the urge to bold something, it's a sign the text is too long or the structure is wrong — simplify instead
- Do NOT include specific file counts or numbers (e.g. "32ファイル", "15 files") — describe what changed, not how many

Write the drafted PR body to a temporary file and open it in VS Code for the user to review and edit directly:

```bash
code tmp/pr-draft.md
```

Then present a summary in the conversation:

```
## Draft PR Body

Title: <proposed title>
Base branch: main

PR body is open in VS Code (tmp/pr-draft.md).
Please review and edit as needed, then let me know when ready.
```

**STOP HERE. Do NOT proceed to Step 4 until the user explicitly confirms they are ready.**
Wait for confirmation. Read the file again before proceeding to pick up any edits the user made:

```bash
cat tmp/pr-draft.md
```

## Step 4: Create the PR

Once confirmed, create the PR as a **draft** and assign it to the current user:

```bash
gh pr create \
  --title "<title>" \
  --body "<body>" \
  --base main \
  --draft \
  --assignee @me
```

If the project uses a different default base branch, use that instead.

After creation, take the URL returned by `gh pr create` and extract the PR number from it.
Present it as a markdown link in this format:

```
[PR #<number>](https://github.com/<owner>/<repo>/pull/<number>)
```

Example: `[PR #797](https://github.com/tkdn/dotfiles/pull/1)`

## Step 5: Self-review via Agent

Once the PR is created, spawn a separate Agent to perform a self-review.
Because you hold the full conversation context, delegating to a context-free Agent produces a more objective review.

Construct the Agent prompt in this form:

```
Review the diff of PR #<number> from the following perspectives:
Code Quality, Harmony (consistency with existing code), Error Handling, Testing, Security, Naming

Fetch the diff with:
gh pr diff <number>

Report findings in this format:

## Critical (must fix before merge)
- ...

## Warning (should consider)
- ...

## Info (optional improvements)
- ...
```

Present the Agent's findings to the user as-is, then ask:

```
Here are the self-review results. Please fix anything that needs attention and let me know.
If everything looks good, we are done.
```

**STOP HERE. Do NOT proceed until the user explicitly responds.**

## Step 6: Done

Share the PR URL as a markdown link (see Step 4 format).
`tmp/pr-draft.md` can be left as-is — it will be overwritten on the next run and is covered by `.gitignore`.
