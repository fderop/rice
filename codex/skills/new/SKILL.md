---
name: new
description: Start a new investigation, bug fix, refactor, or feature on a fresh git branch from the latest default branch. Use when the user asks to start new work, begin a task from an idea, create a fresh branch, or invokes new-style workflow language such as "new" followed by an idea.
---

# New

Start work from a clean branch and then continue in the current Codex session.

## Workflow

1. Read the user's idea from the request. If it is empty or materially ambiguous, ask for the missing idea and stop.
2. Derive a branch name: kebab-case, at most 50 characters after the prefix.
   - Investigation, why, debug, look into: `investigate/...`
   - Add, build, implement, create: `feat/...`
   - Fix, bug: `fix/...`
   - Refactor, clean up, simplify: `refactor/...`
   - Otherwise: `wip/...`
3. Run `git new-branch <name>` once.
   - The helper verifies the repo, aborts on dirty worktrees, fetches the default branch, suffixes collisions, and checks out a branch from `origin/<default>`.
   - Read stdout for the actual branch name: `OK created '<final>' from origin/<default> at <sha>`.
   - If it exits non-zero, relay stderr to the user and stop. Do not stash, commit, or work around a dirty tree unless the user explicitly asks.
4. Continue the task in this session.
   - Investigation requests: inspect and report concrete findings with file paths and line numbers. Do not edit files unless the user changes the request.
   - Feature, fix, and refactor requests: implement the scoped change, verify it using the repo's normal commands, and report the outcome.
5. Do not push, commit, or open a PR unless the user explicitly asks.

## Reporting

Report the final branch name, what was done, and any blocking decision needed from the user. Keep it short.
