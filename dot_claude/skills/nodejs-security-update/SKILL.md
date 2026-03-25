---
name: nodejs-security-update
description: |
  Skill for applying Node.js security patch releases across multiple repositories by detecting all version
  specifications and creating PRs. Use this skill whenever the user mentions Node.js security updates,
  vulnerability patches, or pastes a nodejs.org security release URL. Invoke as:
  `/nodejs-security-update <security-release-url>`
---

# Node.js Security Update Skill

Detect all Node.js version specifications across repositories, identify which ones need updating based on
a security release, confirm the target repos with the user via a checklist, then apply updates and open PRs.

## Invocation

```
/nodejs-security-update https://nodejs.org/en/blog/vulnerability/...
```

If the URL is omitted, ask the user for it before proceeding.

---

## Step 1: Determine the working directory

Check the current PWD:

- **Multiple repos side-by-side** (no `.git` directly in PWD) → use PWD as the scan root
- **Single repo** (`.git` exists in PWD) → inform the user: "It looks like you're inside a single repository. I recommend running this from the parent directory that contains all your repos. Should I proceed with just this one repo?"

---

## Step 2: Fetch fixed versions from the security release

Use the `WebFetch` tool on the provided URL and extract the patched version for each major line (v20, v22, v24, etc.).

Example output:
```
v20 → 20.20.2
v22 → 22.22.2
v24 → 24.14.1
```

Only patch/minor updates within the same major are applied — never bump the major version.

---

## Step 3: Scan repositories

Run the bundled scan script:

```bash
node ~/.claude/skills/nodejs-security-update/scripts/scan.mjs <working-directory>
```

The script detects and returns JSON covering:
- `.node-version` / `.nvmrc` files
- `engines.node` in `package.json` (root + one level of subdirectories)
- Direct `node-version:` values in `.github/**/*.yml` (skips `node-version-file:` references — those inherit from the files above)

---

## Step 4: Present a checklist to the user

Format the scan results and present them grouped by major version. Only include entries where
the current version is older than the patched version for that major line.

Example presentation:

```
Here are the Node.js version specs that need updating. Please confirm which repos to include:

[v22 → 22.22.2]
- [ ] my-frontend    engines.node: 22.22.0  (package.json)
- [ ] my-api         engines.node: 22.22.1  (package.json)

[v24 → 24.14.1]
- [ ] my-schema      engines.node: 24.14.0  (package.json)
- [ ] my-backend     engines.node: 24.14.0  (package.json + gas/package.json)

[Range specifiers — skipping by default]
- [ ] my-test-suite  engines.node: 24.x
- [ ] my-worker      engines.node: 20.x
```

**Rules:**
- Pre-check all fixed-version entries (no wildcards/ranges) by default
- Leave range specifiers (`22.x`, `>=20`, `^22.14.0`, etc.) unchecked with a note that they're skipped
- If a repo has both `.node-version` and `engines.node`, list both files
- `node-version-file:` references in GitHub Actions follow the files above automatically — no separate entry needed
- Omit repos already at or above the patched version

Wait for the user to confirm before proceeding.

---

## Step 5: Update each repo and open a PR

Process selected repos **one at a time** (not in parallel — git operations need sequential execution).

### 5-1. Prepare branch

```bash
git fetch --prune
git switch main      # adjust if the default branch differs
git pull
git checkout -b nodejs-security-update
```

If `nodejs-security-update` already exists, ask the user whether to delete it or use a different name.

### 5-2. Apply file updates

| Detection type | What to update |
|---------------|----------------|
| `.node-version` / `.nvmrc` | Replace file content with the new version string |
| `engines.node` (fixed version) | Update the field value in `package.json` |
| Direct `node-version:` in GitHub Actions | Update the relevant line |

Bundle all changed files for a repo into a single commit. Do not update range specifiers.

### 5-3. Commit

```bash
git add <changed files>
git commit -m "chore: update Node.js to security patch version X.Y.Z

<Month> <Year> security release
<URL>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

### 5-4. Push and open PR

```bash
git push -u origin nodejs-security-update
gh pr create \
  --title "chore: update Node.js to security patch version X.Y.Z" \
  --body "..."
```

Check whether the repo has a `PULL_REQUEST_TEMPLATE` and match its structure if present.
Otherwise use this template:

```markdown
## Summary

Apply Node.js security patch release.

## Why

- <Month> <Year> security release
- <URL>

## Changes

- Updated `engines.node` in `<file>` from `<old>` to `<new>`

## Verification

- CI passes

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## Step 6: Report results

After all repos are done, list the PR URLs:

```
Done. PRs created:

- https://github.com/org/repo-a/pull/123
- https://github.com/org/repo-b/pull/456
```

---

## Error handling

- **Branch already exists** → ask user to delete or rename before continuing
- **PR already exists** → report the existing PR URL and skip that repo
- **Default branch is not `main`** → run `git remote show origin` to detect it before switching
