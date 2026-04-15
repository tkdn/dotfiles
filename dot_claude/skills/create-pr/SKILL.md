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

## Step 2: Self-review with pr-review

Run the `pr-review` skill against the current branch **before** writing the PR description.

> This step catches issues early and surfaces items to include in "見てほしいところ".

Since pr-review targets an already-opened PR but we don't have one yet, review the diff directly:

```bash
git diff main...HEAD
```

Apply the pr-review perspectives (Code Quality, Harmony, Error Handling, Testing, Security, Naming) to this diff.
Write the review findings to a temporary file in the repository's `tmp/` directory (already in `.gitignore`):

```bash
mkdir -p tmp
# write findings to tmp/pr-self-review.md
```

### Present findings to the user

Write the review findings to the temporary file, then open it in VS Code:

```bash
code tmp/pr-self-review.md
```

After opening, present a concise summary in the conversation:

```
## Self-Review Results

### Critical (must fix before PR)
- ...

### Warning (should consider)
- ...

### Info (optional improvements)
- ...

Full details are open in VS Code (tmp/pr-self-review.md).
Do you want to fix any of these before creating the PR?
If yes, please make the changes and let me know when ready.
If no, I'll proceed with creating the PR.
```

**STOP HERE. Do NOT proceed to Step 3 until the user explicitly responds.**
Wait for the user's response. If they want to fix issues, stop here and let them make changes. Resume when they say they're ready.

## Step 3: Gather context

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

## Step 4: Draft the PR body

Fill in each section of the PR template based on the context gathered above.
If `.github/PULL_REQUEST_TEMPLATE.md` exists, follow its structure exactly.

For this project the template has these sections — use them if the template is present:

| Section | How to fill |
|---|---|
| レビュー期日 | Leave blank (user fills this in) |
| 関連リンク | Extract from branch name, commit messages, or leave blank |
| やりたいこと | Summarize the goal of this branch in 1–2 sentences |
| なぜなのか | Explain the motivation or problem being solved |
| やったこと | List concrete changes made (files, logic, DB, etc.) |
| やらなかったこと | Note explicitly out-of-scope items if relevant |
| 見てほしいところ | Include any Warning/Critical items from the self-review, plus genuinely uncertain areas |
| 確認方法 | Describe how to verify the changes work |

Keep each section concise. Prefer bullet points over prose where appropriate.

**Formatting rules for the PR body:**
- Do NOT use bold (`**text**`) anywhere in the PR body
- If you feel the urge to bold something, it's a sign the text is too long or the structure is wrong — simplify instead

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

**STOP HERE. Do NOT proceed to Step 5 until the user explicitly confirms they are ready.**
Wait for confirmation. Read the file again before proceeding to pick up any edits the user made:

```bash
cat tmp/pr-draft.md
```

## Step 5: Create the PR

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

Example: `[PR #797](https://github.com/classi/kuroko-api/pull/797)`

## Step 6: Done

Tell the user the PR is open and share the URL as a markdown link (see Step 5 format).
The temporary files (`tmp/pr-self-review.md`, `tmp/pr-draft.md`) can be left as-is — they will be overwritten on the next run and are covered by `.gitignore`.
