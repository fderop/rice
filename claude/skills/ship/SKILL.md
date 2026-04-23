---
name: ship
description: Ship the current branch as a PR. Runs local CI (prettier + ruff), pushes, opens or updates the PR with a concise body including where human steering was needed.
allowed-tools: [Bash, Read, Grep, Glob]
---

## Steps

1. **Preflight** (parallel): current branch (abort if main/master), `git status --porcelain` (if dirty, ask commit/abort), check for upstream.

2. **Local CI** (parallel, only if configured):
   - Prettier: `npx prettier --check .` where `package.json` has prettier or a prettier config exists.
   - Ruff: `ruff check . && ruff format --check .` where `pyproject.toml`/`ruff.toml`/`.ruff.toml` exists.
   
   On failure: autofix (`prettier --write`, `ruff format`, `ruff check --fix`), commit fixes tersely, continue. If not autofixable, stop and show user.

3. **Push**: `git push -u origin HEAD`.

4. **Detect PR**: `gh pr view --json number,title,body,url 2>/dev/null`.

5. **Draft body** from `git log <base>..HEAD` + `git diff <base>...HEAD` (base via `gh repo view --json defaultBranchRef`, fallback `main`):

   ```
   ## Summary
   <1–3 terse bullets>
   
   ## Notes
   <where user corrected/redirected/made judgment calls not obvious from diff — from THIS conversation. Omit section if work was smooth.>
   
   ## Test plan
   - [ ] <checklist>
   ```
   
   Title ≤70 chars, imperative.

6. **Create/update**:
   - New: `gh pr create --title ... --body "$(cat <<'EOF' ... EOF)"`.
   - Existing: `gh pr edit <number> --title ... --body ...`.

7. **Report** URL + one line. Don't merge. Don't close Relay issues (global CLAUDE.md).
