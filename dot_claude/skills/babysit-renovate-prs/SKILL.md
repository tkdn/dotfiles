---
name: babysit-renovate-prs
description: Helps opsmaster on-call rotation triage and prioritize Renovate/Dependabot PRs for weekly merge. Invoked as `/babysit-renovate-prs <org>/<team>`. Fetches all open Renovate and Dependabot PRs across repositories managed by the given GitHub Team, then groups them by merge priority. Use this skill whenever the user mentions opsmaster duties, Renovate PR triage, dependency update backlog, or weekly dependency maintenance — even if they don't say "babysit" explicitly.
---

# babysit-renovate-prs

List this week's Renovate/Dependabot PRs ranked by merge priority, for the opsmaster on-call rotation.

## Invocation

```
/babysit-renovate-prs <org>/<team>
```

Example: `/babysit-renovate-prs my-org/my-team`

If no argument is given, print an error and stop — do not guess defaults.

---

## Step 1 & 2: Fetch repositories and collect open PRs

Use the bundled script to fetch all admin repositories for the team and collect open Renovate/Dependabot PRs in one step. The script outputs one JSON object per line (NDJSON):

```bash
bash <skill-base-dir>/scripts/fetch_prs.sh <org>/<team>
```

Each line has these fields: `repo`, `author`, `number`, `title`, `url`, `createdAt`, `labels`, `headRefName`.

Also include any PR whose title contains `[security]`, regardless of author — these are already included if opened by Renovate or Dependabot, but be aware they may appear in the results from the script.

---

## Step 3: Gather details for each PR

For each PR, collect the following:

### Vulnerability check

A PR is considered a security fix if:
- It was opened by `app/dependabot` AND has a linked Dependabot security alert, OR
- Its title contains `[security]`

To check for linked alerts (Dependabot PRs):
```bash
gh api "/repos/<owner>/<repo>/dependabot/alerts" \
  --jq '[.[] | select(.state == "open")]'
```

Cross-reference the alert's affected package with the PR's branch name or title to confirm the link.

### CI status

```bash
gh pr checks <number> --repo <repo>
```

A PR is "CI passing" if all checks have passed (no failures or pending).

### Claude Code Renovate comment check

If CI is passing, also check PR comments for any approval or notes from Claude Code or renovate-approve bots — these give extra confidence the PR is safe to merge:

```bash
gh api "/repos/<owner>/<repo>/issues/<number>/comments" \
  --jq '.[] | select(.user.login | test("claude|renovate-approve"; "i")) | {user: .user.login, body: .body}'
```

---

## Step 4: Classify into priority groups

Each PR belongs to exactly one group — the highest priority that applies.

**Priority 1 — Security fix**
- Dependabot PR with a linked open security alert, OR
- Title contains `[security]`

**Priority 2 — Stale (14+ days)**
- `createdAt` is 14 or more days before today
- Not already in Priority 1

**Priority 3 — CI passing**
- All CI checks passed
- Not already in Priority 1 or 2
- If a Claude Code / renovate-approve comment exists, note it in the output

**Priority 4 — Low risk**
- Updates to `devDependencies`, test tooling, type definitions (`@types/*`), linters, etc.
- Inferred from PR title, labels, or branch name
- Not already in a higher priority group

Within each group, sort by `createdAt` ascending (oldest first).

---

## Step 5: Output

Write the report to a temp file and copy it to the clipboard:

```bash
<generate the markdown report, then run>
tee /tmp/renovate-triage.md | pbcopy
```

The Markdown table report format:

```markdown
# Renovate/Dependabot PR Triage — <org>/<team>
> As of: YYYY-MM-DD

## Priority 1: Security fixes (N)

| Repository | PR | Created | Days open |
|---|---|---|---|
| [repo-name](https://github.com/org/repo) | [PR title](PR URL) | YYYY-MM-DD | N |

## Priority 2: Stale (14+ days) (N)

| Repository | PR | Created | Days open |
|---|---|---|---|
| ...

## Priority 3: CI passing (N)

| Repository | PR | Created | Days open |
|---|---|---|---|
| ...

## Priority 4: Low risk (N)

| Repository | PR | Created | Days open |
|---|---|---|---|
| ...

---
Total: N PRs across N repositories
```

If a group has no PRs, show "None" instead of an empty table.

After writing the file, tell the user: "Copied to clipboard. Also saved to `/tmp/renovate-triage.md`."

---

## Notes

- Requires `gh` CLI to be authenticated. If not, prompt the user to run `gh auth login`.
- If CI status cannot be fetched for a PR, treat it as unknown and place it in Priority 4.
- If a PR qualifies for multiple groups, always place it in the highest priority group only.
- Be mindful of API rate limits when the team manages many repositories — pace requests if needed.
