---
name: commit
description: Creates logical, well-structured git commits following conventional commits
disable-model-invocation: true
---

# Step
## 1. Review current changes

```bash
git branch --show-current
git status
git diff
git diff --cached
```

## 2. Analyze changes and consider commit granularity

- Don't break CI or builds: each commit should keep the codebase in a working state
- Make granularity easy for reviewers and readers to understand step by step
- Consider dependencies: make commits in an order that respects dependencies
- If a single file has multiple changes, stage only the relevant portions
- Each commit must be self-contained and reversible
- Focus commit messages on 'why' not just 'what'

## 3. Submit commit plan to user and obtain approval
example:

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

IMPORTANT: Wait for explicit user approval before proceeding to commit creation.

### Create Commit following conventional commits

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

example:

- feat: send an email to the customer when a product is shipped
- feat!: send an email to the customer when a product is shipped
- feat(api)!: send an email to the customer when a product is shipped
- docs: correct spelling of CHANGELOG
- fix: double submit issue on foobar feature
- chore: tweak testcase name

## 4. Create commits after approval

```bash
git add [changed-files]
git commit -m "$(cat <<'EOF'
fix: double submit issue on foobar feature

- detailed description
- https://someissue.example/issues/123
EOF
)"
```

## 5. Verify signed commit in eachs

After commited do following and verify:

```bash
git verify-commit HEAD || exit 1
```
