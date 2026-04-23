---
name: new
description: Start a new investigation or feature on a fresh branch off latest main. Pulls main without switching, creates a named branch, dispatches a sonnet agent to do the work.
argument-hint: <idea>
allowed-tools: [Bash, Agent, Read, Glob, Grep]
---

Idea: $ARGUMENTS

If empty, ask user for the idea and stop.

## Steps

1. **Preflight** (parallel Bash):
   - `git rev-parse --show-toplevel` — abort if not a repo.
   - `git status --porcelain=v1 -b` — abort if dirty; ask user to stash/commit.
   - Detect default branch: `git symbolic-ref refs/remotes/origin/HEAD --short` → strip `origin/`. Fall back to `main`.

2. **Update default branch without switching**:
   - If on default: `git pull --ff-only`.
   - Else: `git fetch origin <default>:<default>`. On non-ff failure, `git fetch origin <default>` and branch off `origin/<default>` in step 4; warn user local default diverged.

3. **Branch name**: kebab-case, ≤50 chars, type-prefixed:
   - "investigate|why|debug|look into" → `investigate/...`
   - "add|build|implement|create" → `feat/...`
   - "fix|bug" → `fix/...`
   - "refactor|clean up|simplify" → `refactor/...`
   - else → `wip/...`

   Check collisions with `git rev-parse --verify` and `git ls-remote --exit-code --heads origin`; append `-2`, `-3`, etc.

4. **Create branch**: `git checkout -b <name> <default>` (or `origin/<default>` per step 2 fallback).

5. **Dispatch sonnet agent** (foreground, per global CLAUDE.md):
   - Investigation (why/how/safe-to-change) → `Explore` or `general-purpose`; output = written analysis with file paths + line numbers, no code changes.
   - Feature/fix → `general-purpose`; plan + implement, scoped.
   
   Brief the agent cold: restate idea verbatim, one-line repo summary, expected output form, branch name.

6. **Report**: 2–4 sentence summary of agent's output + any decision needed from user. Do not push, commit to main, or open PRs.
