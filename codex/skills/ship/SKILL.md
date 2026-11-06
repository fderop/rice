---
name: ship
description: Ship the current git branch by checking local status, running configured formatting and lint checks, committing intentional local changes when appropriate, pushing the branch, and opening or updating a ready-for-review GitHub pull request. Use when the user says ship, open a PR, create a PR, publish this branch, or push this work for review.
---

# Ship

Ship the current branch as a ready-for-review PR. Never create a draft PR unless the user explicitly asks for a draft.

## Preflight

1. Check the current branch and abort on `main` or `master`.
2. Check `git status --porcelain`.
   - If unrelated or unclear changes are present, ask the user whether to include them.
   - If changes are clearly part of the current task, include them.
3. Determine the default branch from GitHub when possible, falling back to `main`.
4. Check whether a PR already exists for the branch.

## Local Checks

Run only checks that are configured in the repo.

- JavaScript/TypeScript formatting: if `package.json` or config shows Prettier, run `npx prettier --check .`.
- Python lint/format: if `pyproject.toml`, `ruff.toml`, or `.ruff.toml` configures Ruff, run `ruff check .` and `ruff format --check .`.
- Repo-specific checks requested by local instructions should be run when they are relevant to the files changed.

If formatting fails and the fix is mechanical, run the formatter, review the diff, and include that change. If lint or tests fail in a way that is not clearly mechanical, stop and report the failure.

## Commit And Push

1. Review `git diff` and `git status`.
2. Commit the intended changes with a terse, descriptive message if there are uncommitted changes.
3. Push with `git push -u origin HEAD`.

## Pull Request

Create or update the PR using GitHub tooling available in the environment.

- New PR: create it ready for review. Do not pass `--draft`.
- Existing PR: update the title/body if the local diff changed the scope materially.
- Title: imperative, at most 70 characters.
- Body:

```markdown
## Summary
- <1-3 bullets>

## Notes
<Only include if user steering, tradeoffs, or unusual decisions matter for review.>

## Test plan
- [ ] <command or manual check>
```

### Images

When the branch contains useful figures or screenshots, embed them in the PR body after the
relevant text. Push the image files before you update the PR body. Use an absolute GitHub `blob`
URL with `?raw=1` so GitHub displays each image:

```markdown
![Descriptive image text](https://github.com/<owner>/<repo>/blob/<branch>/<path/to/image.png>?raw=1)
```

Use descriptive alternative text. Do not use a local file path or a relative path in the PR body.

Do not merge the PR unless the user explicitly approves. Do not close Relay issues unless the user explicitly approves.

## Local CI Before Squash Merge

Run full CI locally only after the user explicitly requests a squash merge, before merging that PR.
Do not run full CI for commits, pushes, PR creation, PR updates, or readiness reports.
Keep normal local hooks and relevant checks enabled during development and shipping.
Never manually dispatch or rerun GitHub CI. Run agent-requested CI locally only.
Leave existing automatic GitHub workflows and schedules enabled. Authorized pushes and PR updates can trigger those existing workflows.
Never restore deleted remote CI commands from another worktree.
A squash merge request authorizes local CI only. Do not disable or change GitHub workflows or schedules without an explicit request.

For `glass-bio/glass_bio` and its worktrees, use this merge procedure:

1. Use a clean, committed checkout of the current PR head. Record its SHA.
2. Run all checks from `.github/workflows/ci.yml` locally, including referenced actions, with the required dependencies and services.
3. Wait for long jobs in one process. Record each command and its result for the checked SHA.
4. Require every expected check to pass. Missing, skipped, pending, or failed checks do not pass. If local CI cannot complete, report the blocker and leave the PR unmerged.
5. Immediately before merging, confirm that the PR head still matches the checked SHA. If the head changed, run local CI for the new head.
6. Merge with `gh pr merge --squash --match-head-commit <checked-sha>`.

Include the local CI result and checked SHA in the merge completion response.
No remote CI run link is required. Passing local CI does not grant permission to merge.

## Reporting

Return the PR URL, branch name, checks run, and any checks that could not be run.
