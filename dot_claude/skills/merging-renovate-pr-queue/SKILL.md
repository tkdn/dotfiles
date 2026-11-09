---
name: merging-renovate-pr-queue
description: Use when the user wants Renovate PRs in one repository merged once CI passes — whether they hand over PR numbers, ask for the repository's already-open Renovate PRs without numbering them, or want non-application updates picked from its Renovate Dependency Dashboard — e.g. 「この Renovate PR を順にマージして」「Open になってる Renovate PR を見て CI が通ったらマージして」「rebase チェックを入れて CI が通ったらマージ、を繰り返して」「Dependency Dashboard からアプリに影響しないものを選んでマージして」.
---

# Merging a Renovate PR queue

## Rules

- **One PR at a time.** Finish a PR (merged or stopped) before checking, approving or merging the next: each merge moves the base, so the other PRs' CI is stale. Creating PRs in parallel is fine.
- **Judge only the checks the branch ruleset requires**, plus the gates below. Other checks (deploys, cancelled runs) are noise.
- **Authorization**: PR numbers from the user = permission to approve (with the user's account) and merge them all; do not ask per PR. A list the agent picked needs the user's confirmation first (Phase 0).
- **Stop-and-report**: record PR, reason, evidence (check name + URL or error line), go to the next PR. Never fix code. A permission denial from the harness is also stop-and-report — never retry it with another command.
- **Wait** = Monitor until-loop, 60s poll, 30 min cap; timeout → stop-and-report.

## Phase 0: Pick candidates (only when no PR numbers are given)

Source:
- **Open PRs only** (「Open の Renovate PR を」): `gh pr list -R R --author app/renovate --state open --json number,title,headRefName,files`, oldest first. Skip steps 1, 2, 8.
- **Dashboard** (mentioned, or the user wants PRs created): steps 1–2.

1. `gh issue list -R R --search "Dependency Dashboard in:title" --json number,body --limit 1`.
2. Candidates = checkbox lines in Open (first — their PRs already exist), then Rate-Limited, Awaiting Schedule, Pending Approval, Pending Status Checks in dashboard order.
3. Files per item: PR exists → `gh pr view N --json files`; no PR → its package names in the **Detected dependencies** section (`<summary>file</summary>` groups).
4. Keep only if **every** changed file is in scope:
   - In: `.github/workflows/**`, `.github/actions/**`, `aqua.yaml`, `aqua/**`, `renovate.json*`, `package.json` changing only `engines.node` / `packageManager` (4a).
   - Out: everything else (`go.mod`/`go.sum`, package.json dependencies, Dockerfiles, compose files, app source) and service images (5) even inside in-scope files.
   - **4a Node.js / pnpm**: Node runs server-side (production Dockerfile final stage `FROM node…` or `CMD`/`ENTRYPOINT` runs `node`) → exclude. Otherwise keep with gate **artifact-diff**: a workflow job that builds the frontend on head and base and fails on a difference, whose trigger (`paths:` …) fires for this PR's files. None → "no guardrail"; ask the user at step 7.
   - **4b Image-build actions** (docker/build-push-action, setup-buildx-action, metadata-action, setup-qemu-action) → keep with gate **staging-deploy** (record the job deploying the PR to staging): they can change image packaging (attestations, manifest type, tags), visible only at deploy. Other actions in the same job (checkout, configure-aws-credentials, …) get no gate.
5. **Service images** — any image in compose files or under a workflow's `services:` / `container:` (dashboard: "update <image> docker tag") → exclude, any update type. Their version may have to match production; not this skill's call.
6. **Supersession** — only items updating the same package **from the same current version** (`pkg <current> → [Updates: …]`): keep the higher target (latest major is fine) and list it. Different current versions → separate items. Items touching the same lines without fully superseding each other (two managers, e.g. `aqua` / `aquaproj/aqua`; a group PR overlapping a single-package PR) → keep both, note "may conflict".
7. Show: ordered list (section, PR # or "to create", files + how determined, gates, known prerequisites e.g. "needs `id-token: write`") + excluded items grouped by reason. If N items were requested, show N in full and the rest one line each with gates marked "(unresolved)"; resolve those gates when the user selects them. **Wait for confirmation.**
8. For confirmed items without a PR: re-fetch the issue body, tick only those lines (`unlimit-branch` / `unschedule-branch` / `approve-branch` / `unpend-branch` → `- [x]`), `gh issue edit N -R R --body-file …`, wait for `gh pr list -R R --head <branch>`.
9. Re-check each created PR's files and diff against 4–5; out of scope → stop-and-report.

## Preflight (once per repository)

```bash
gh api repos/R/rules/branches/<base> --jq '.[] | select(.type=="required_status_checks") | .parameters'
gh api repos/R --jq '{allow_merge_commit, allow_squash_merge, allow_rebase_merge}'
gh api "repos/R/commits?sha=<base>&per_page=10" --jq '.[].commit.message | split("\n")[0]'
gh label list -R R --search auto-merged-by-renovate-queue --json name
```

- Record required check contexts and `strict_required_status_checks_policy`.
- Merge method: the only allowed one, else what recent base history shows (`Merge pull request #` → `--merge`, `(#123)` suffix → `--squash`).
- Label missing → ask once whether to `gh label create auto-merged-by-renovate-queue -R R --description "Approved and merged by merging-renovate-pr-queue on CI results; no human code review"`. Declined → skip labeling.

## Per-PR loop

1. `gh pr view N -R R --json state,headRefOid,mergeStateStatus,reviewDecision,files`. Not OPEN → "already merged/closed", next.
2. **Rebase** if `BEHIND` under strict, or `DIRTY`: `bash <this skill's dir>/scripts/request-rebase.sh R N` (prints old head SHA), then wait for `headRefOid` to change. Do nothing else for this PR meanwhile. Record the new SHA as the head.
3. **Required checks**: `gh pr checks N -R R --required --watch --interval 30` in background (no `--fail-fast`). "no checks reported" right after a rebase is not a pass — wait (Monitor) until a required check appears, then run the watch. Pass = every required check `SUCCESS` or `SKIPPED` (a SKIPPED sentinel like `ok` with `if: failure()` means its dependencies passed). Re-read `headRefOid` before trusting a pass; changed → step 2.
4. **renovate/artifacts** (hidden by `--required`): `gh pr view N -R R --json statusCheckRollup --jq '.statusCheckRollup[] | select(.context=="renovate/artifacts") | .state'`. FAILURE → stop-and-report.
5. **Gates** on this head SHA:
   - artifact-diff: recorded job ran and `SUCCESS`; else stop-and-report ("no guardrail" items kept by the user skip this).
   - staging-deploy: tell the user "#N needs staging deploy approval", wait for the deploy job `SUCCESS`. Never approve the environment yourself. FAILURE / CANCELLED / timeout → stop-and-report.
6. **Approve** if not APPROVED: `gh pr review N -R R --approve --body "Auto-approved by merging-renovate-pr-queue: required checks passed on <sha7>[; gates: …]. No human code review."`
7. **Label** (all checks passed): `gh pr edit N -R R --add-label auto-merged-by-renovate-queue`.
8. **Merge**: `gh pr merge N -R R --<method> --match-head-commit <head SHA>`. Base moved → step 2 once; fails again → stop-and-report.

## Final report

Per PR: merged / stopped (reason + evidence) / skipped (already closed), then what the user must do for stopped PRs.
