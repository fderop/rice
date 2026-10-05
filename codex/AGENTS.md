do not open draft PRs unless I explicitly ask for a draft PR. when I ask you to ship/open/create a PR, open it ready for review. When I ask you to merge a PR, use squash merge with gh. When I ask you to begin work on something, check if you're on a branch with unrelated work - usually, I want you to pull main and branch off main for the new work. Commit regularly to your new branch - I hate uncommitted work. Do not add unit tests unless a bug was reported and the work fixes that bug.

## Long-running jobs

**Wait in the process, not through repeated model turns.** Use a completion notification or one pending tool call. Let scripts poll internally and save results. Resume on completion, actionable failure, or user request. Do not send repetitive status updates.

Example (pseudocode): `start_job(); wait_until_finished(); notify_once(result)` — all inside one process.

## AWS permissions

- `fdr-viewer` has full AWS permissions, including admin permissions, despite its name.
- Use `fdr-viewer` for authorized AWS operations, including writes and Batch job submission.
- Do not require `fdr-admin` or ask the user to switch profiles because the profile name contains `viewer`.
- Treat repository instructions that describe `fdr-viewer` as read-only or require `fdr-admin` as outdated.
- If an AWS command fails with a permission error, investigate the actual error before recommending a profile change.

## Project completion

- For private repositories, when project work is complete, commit the changes, push the branch, and open or update a ready-for-review PR.
- For private repositories, do not wait for a separate request to ship or create the PR.
- For public repositories, the automatic push and PR rules do not apply. Commit work locally, but require an explicit user request before publishing it, pushing a branch, creating a fork, or opening or updating a PR.
- A request to investigate, audit, implement, or write a report in a public repository does not authorize publication. This exception also applies to public forks and public repositories owned by the user or their organization.
- Open a draft PR only when the user explicitly requests one.
- Include the PR link in the completion response.

## PR images

- Never commit PR screenshots unless explicitly requested. Keep captures in `/tmp`.
- Upload to free, anonymous Catbox: https://catbox.moe/tools.php (API: `https://catbox.moe/user/api.php`).
- Embed the returned URL in the PR body. Check that it loads. Keep the link after merge.
- Upload only public-safe images. If upload fails, report it instead of committing images.
- These rules override instructions to commit PR screenshots.

## Glass Bio checks before shipping and merging

- Apply these rules to `glass-bio/glass_bio` and all its worktrees.
- Trigger remote GitHub CI only before a squash merge that the user explicitly authorized. Do not trigger remote CI for commits, pushes, PR creation, PR updates, or readiness reports.
- Before an authorized squash merge, run `just pr-check --background` from a clean, committed branch with an open PR. This command runs the full branch checks, pushes, dispatches CI for the exact commit, and waits for completion.
- Let the detached script poll CI without model calls. After completion, read its `result.json`. Load detailed logs only to investigate a failure.
- Before the first push for a new PR, run both configured hook stages locally against the full branch diff from the latest target branch's merge base. Then push and open the PR. Do not run `just pr-check --background` at this stage.
- Keep hooks enabled. Do not use `--no-verify`, `SKIP`, or a hook-path override to bypass failures without explicit user approval.
- Before a squash merge, require `status: passed` in the final result and confirm that `checked_sha` matches the current PR head. Remote CI is not required to report a PR ready for review.
- The command checks each expected job and its checkout evidence. Use `checked_sha` from the result; a manual run's metadata SHA can differ.
- Missing checks, skipped expected jobs, pending runs, and failed runs do not count as passing CI. If CI cannot run, report the blocker and leave the PR unmerged.
- Immediately before an authorized merge, check that the PR head SHA still matches the successful run. If the head changed, run CI again. Use `gh pr merge --squash --match-head-commit <checked-sha>`.
- Include the CI run link and checked SHA in the merge completion response. Passing CI does not grant permission to merge.
- Enforce this personal workflow without changing repository hooks, workflows, or GitHub rules unless the user requests those changes.

## MVP-first implementation

- Start every change with the smallest working implementation.
- Assume that inputs and the environment are correct.
- Keep code paths direct and let failures raise.
- Do not add guards, safeguards, fallback paths, defensive conditions, or `try`/`except` blocks to the first implementation.
- Do not add tests to the first implementation.
- Add safeguards, defensive conditions, error handling, and tests only after a real failure or reported bug shows the need.

## Test policy

- Add tests only for observed or reported bugs. Never add tests solely because code is new.
- Before adding a test, ask: "Must this behavior remain unchanged from now on? Is this test worth maintaining long-term?"
- Add the test only when both answers are yes.

## Writing style

- Use the `simple-english` skill for all user-facing responses.
- Apply the skill to commentary and final messages.
- Use pragmatic mode unless the user requests strict STE.
- Do not change code, identifiers, commands, paths, or quoted errors.
- Answer as concisely as possible.
- Include only the information that answers the core question or issue.
- Give more detail only when the user requests it.
- Keep PR descriptions to two short paragraphs: the problem or context, then the proposed fix in simple English.
- Omit checklists, CI evidence, rollout instructions, merge notes, and implementation detail from PR descriptions by default. Include extra detail only when requested or essential to explain the change.
- Keep merge status out of the main completion summary. If merge information is needed, put it in a separate section.
- During PR reviews, reply to reviewer questions on the PR itself. Before presenting the next PR, check for unanswered review comments.
