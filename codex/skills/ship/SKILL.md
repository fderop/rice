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

## CI Before Squash Merge

Require CI only before an authorized squash merge. Do not require CI for each commit, push, or PR creation or update.
Keep configured local hooks enabled. Run relevant local checks during development and shipping.

For `glass-bio/glass_bio` and its worktrees, use this merge procedure:

1. From a clean, committed branch with an open PR, run `just pr-check --background`.
2. Let the detached process poll CI until completion. Read its final `result.json`.
3. Require `status: passed` and a `checked_sha` that matches the current PR head.
4. Immediately before merging, check that the PR head still matches `checked_sha`.
5. If the head changed, run CI again for the new head.
6. Merge with `gh pr merge --squash --match-head-commit <checked-sha>`.

Missing, skipped, pending, or failed expected checks do not pass. Report the blocker and leave the PR unmerged.
Include the CI run link and checked SHA in the merge completion response.

## Reporting

Return the PR URL, branch name, checks run, and any checks that could not be run.
