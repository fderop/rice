---
name: new
description: Start a new investigation or feature on a fresh branch off latest main. Pulls main without switching, creates a named branch, dispatches a sonnet agent to do the work.
argument-hint: <idea>
allowed-tools: [Bash, Agent, Read, Glob, Grep]
---

Idea: $ARGUMENTS

If empty, ask user for the idea and stop.

## Steps

1. **Derive branch name**: kebab-case, ≤50 chars, type-prefixed:
   - "investigate|why|debug|look into" → `investigate/...`
   - "add|build|implement|create" → `feat/...`
   - "fix|bug" → `fix/...`
   - "refactor|clean up|simplify" → `refactor/...`
   - else → `wip/...`

2. **Create the branch**: run `git new-branch <name>` (one Bash call). The helper
   verifies the repo, aborts on a dirty tree, fetches the default branch,
   auto-suffixes the name on collision (`-2`, `-3`, ...), and checks out the new
   branch off `origin/<default>`. Read its one-line stdout (`OK created '<final>'
   from origin/<default> at <sha>`) for the actual branch name used.

   If it exits non-zero: relay the stderr message to the user and stop. A dirty
   working tree is an abort — do not work around it; tell the user to stash/commit.

3. **Dispatch sonnet agent** (foreground, per global CLAUDE.md):
   - Investigation (why/how/safe-to-change) → `Explore` or `general-purpose`; output = written analysis with file paths + line numbers, no code changes.
   - Feature/fix → `general-purpose`; plan + implement, scoped.

   Brief the agent cold: restate idea verbatim, one-line repo summary, expected output form, branch name.

4. **Report**: 2–4 sentence summary of agent's output + any decision needed from user. Do not push, commit to main, or open PRs.
