---
name: babysit-renovate-prs
description: Helps opsmaster on-call rotation triage and prioritize Renovate/Dependabot PRs for weekly merge, and also lists release-please PRs separately. Invoked as `/babysit-renovate-prs <org>/<team>`. Fetches all open Renovate, Dependabot, and release-please PRs across repositories managed by the given GitHub Team, groups dependency PRs by merge priority, and shows release PRs in a dedicated section. Use this skill whenever the user mentions opsmaster duties, Renovate PR triage, dependency update backlog, weekly dependency maintenance, or release PR overview — even if they don't say "babysit" explicitly.
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

Use the bundled script to fetch all admin repositories for the team and collect open Renovate/Dependabot/release-please PRs in one step. The script outputs one JSON object per line (NDJSON):

```bash
bash <skill-base-dir>/scripts/fetch_prs.sh <org>/<team>
```

Each line has these fields: `repo`, `author`, `number`, `title`, `url`, `createdAt`, `labels`, `headRefName`.

Release-please PRs are identified by the `autorelease: pending` label combined with an author whose login contains `release-please`. They are separated from the dependency update triage and shown in their own section.

Also include any PR whose title contains `[security]`, regardless of author — these are already included if opened by Renovate or Dependabot, but be aware they may appear in the results from the script.

---

## Step 3: Split PRs into two tracks

Before gathering details, separate the fetched PRs into two tracks:

- **Dependency updates**: author is `renovate` or `dependabot`
- **Release PRs**: author contains `release-please`

Only dependency update PRs go through the priority classification (Steps 3–4). Release PRs are collected separately and shown in their own section at the end of the report (Step 5).

---

## Step 3: Gather details for each dependency update PR

For each dependency update PR, collect the following:

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

## Step 4: Classify dependency update PRs into priority groups

Each PR belongs to exactly one group — the highest priority that applies.

**Priority 1 — Security fix**
- Dependabot PR with a linked open security alert, OR
- Title contains `[security]`
- Show regardless of days open

**Priority 2 — Stale (14+ days)**
- `createdAt` is 14 or more days before today
- Not already in Priority 1

**Priority 3 — Ready to merge (7+ days old, CI passing)**
- All CI checks passed
- `createdAt` is 7 or more days before today
- Not already in Priority 1 or 2
- If a Claude Code / renovate-approve comment exists, note it in the output

PRs that are fewer than 7 days old and not in Priority 1 or 2 are omitted from the report entirely — they're too fresh to need a decision this week.

Within each group, sort by `createdAt` ascending (oldest first).

---

## Step 5: Dependency Dashboard health check

For each repository that had Renovate PRs in the fetched data, look up its Dependency Dashboard issue and count the backlog. Do this in parallel for all repos.

```bash
gh issue list --repo <owner>/<repo> --search "Dependency Dashboard" --json body --limit 1 \
  | jq -r '.[0].body // ""' \
  | awk '
    /^## Awaiting Schedule/{section="awaiting"; next}
    /^## Rate-Limited/{section="rate"; next}
    /^## /{section=""; next}
    (section=="awaiting" || section=="rate") && /- \[ \]/{count++}
    END{print count+0}
  '
```

Sum `Awaiting Schedule` and `Rate-Limited` checkbox items into a single "pending" count per repo. Repos with 0 pending can be omitted from the Dashboard section.

---

## Step 6: Output

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

## Priority 3: Ready to merge (N)

| Repository | PR | Created | Days open |
|---|---|---|---|
| ...

---

## Release PRs (N)

| Repository | PR | Version | Created | Days open |
|---|---|---|---|---|
| [repo-name](https://github.com/org/repo) | [PR title](PR URL) | vX.Y.Z | YYYY-MM-DD | N |

---

## Dependency Dashboard (repos with pending updates)

| Repository | Pending (Awaiting + Rate-Limited) |
|---|---|
| [repo-name](https://github.com/org/repo) | N ⚠️ |

---
Total: N dependency PRs + N release PRs across N repositories
```

The "Version" column in the Release PRs table should be extracted from the PR title (e.g., `chore(main): release 6.1.1` → `6.1.1`). If no version is discernible, leave it blank.

In the Dependency Dashboard section:
- Sort by pending count descending (most backlogged first)
- Add ⚠️ if pending count is 20 or more
- Omit repos with 0 pending items
- If all repos have 0 pending, show "None"

If a priority group has no PRs, show "None" instead of an empty table.

After writing the file, tell the user: "Copied to clipboard. Also saved to `/tmp/renovate-triage.md`."

---

## Notes

- Requires `gh` CLI to be authenticated. If not, prompt the user to run `gh auth login`.
- If CI status cannot be fetched for a PR and it is 7+ days old, treat it as unknown and still include it in Priority 3 with a note that CI status is unknown.
- If a PR qualifies for multiple groups, always place it in the highest priority group only.
- PRs fewer than 7 days old are only shown if they qualify for Priority 1 (security).
- Be mindful of API rate limits when the team manages many repositories — pace requests if needed.
