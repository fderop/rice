---
name: metasupervise
description: Execute an agreed plan of small PRs through Herdr, with an hourly watchdog and up to two independent executors. Review and squash merge each PR, then review the complete module and test its live flows. Use after planning, when the user requests this supervised implementation and merge workflow.
---

# Metasupervise

Use this skill as the metasupervisor after the plan is complete. The plan defines small issues or PRs and their dependencies.
In this skill, "supervisor" means metasupervisor.
If no plan exists, request the plan before starting executors.

An invocation to execute this workflow authorizes PR publication and squash merges for the agreed plan, subject to explicit user restrictions.
Creating, editing, or discussing this skill does not authorize execution. Do not request merge approval again for each planned PR.
Deployment requires authorization for the target environment under repository rules. Reuse authorization already given in the session.

Read [herdr](../herdr/SKILL.md), [supervisor-executor](../supervisor-executor/SKILL.md), and [ship](../ship/SKILL.md).
Use their session and shipping procedures, with this skill's executor limit, isolated checkouts, watchdog, and pane lifecycle.
Applicable repository instructions control checks, hooks, Relay, and deployment, including overrides of older skill instructions.
For this workflow, close each executor pane after its PR merges.

## Start

1. Require `HERDR_ENV=1` before controlling Herdr.
2. Read the plan and applicable repository instructions. Preserve the plan's scope and acceptance criteria.
3. Check Relay for overlapping work and resolve ownership before edits, as required by repository instructions.
4. Create a local progress record for dependencies, acceptance criteria, owned areas, PR links, branches, checkouts, agents, panes, and states.
5. Give the supervisor a unique Herdr agent name.
6. Assess whether two planned PRs can reach the target branch independently. Record the decision before starting executors.
7. Start one separate Codex watchdog session, using the procedure below. Keep it active through the final integrated review.
8. Start one executor, or two for independent work. Use a fresh session and pane for each planned PR.

Keep the progress record outside Git unless the plan specifies a repository artifact.
Include blockers, pending decisions, held executors, review tasks, checked SHAs, and links to check results. Update it at meaningful state changes.

## Choose Parallel Work

Run at most two executor sessions at once, including executors on hold or awaiting review.
The watchdog is a separate role. One executor gives three Codex sessions. Two executors give four.

Use two executors only when each PR can merge without the other PR's unmerged code or unresolved design decisions.
Check shared files, interfaces, schema changes, and deployment resources before assigning work.
Different filenames alone do not establish independence. Keep coupled work sequential, or merge its prerequisite first.

Give each executor a separate worktree or checkout and branch from the latest target branch.
Use the current Herdr tab with `--no-focus`, but set each executor pane's working directory to its assigned checkout.
Keep supervisor checks in a separate checkout. Never switch branches or reset files underneath another session.
Serialize operations that use a shared database, port, or deployment environment.

The supervisor reviews and merges one PR at a time. An independent executor can continue during that review.
After each merge, reassess the remaining PR's dependencies and shared contracts against the latest target branch.
Do not create stacked PRs. If the work becomes coupled, hold one executor and resolve the dependency before resuming it.

## Watch the Supervisor

Create the watchdog as a sibling Herdr pane with `--no-focus` and a unique agent name.
Start it through the existing `codex` alias, with `gpt-6.1-sol` unless the user specifies another model.
Give it the supervisor's agent name, pane ID, and progress-record path.
Use a short initial prompt:

```text
Act only as the hourly watchdog in the "Watch the Supervisor" section of <absolute metasupervise SKILL.md path>. Watch supervisor <name>, pane <pane-id>, using progress record <path>. Read that section and the Herdr instructions. Start the hourly watch now. Do not execute the plan or create other agents.
```

The watchdog follows these rules:

1. Wait one hour between inspections in one long-lived process, with saved observations outside Git.
   Keep the wait interruptible by user input or shutdown. Do not use repeated model turns for the timer.
2. Inspect the supervisor with `herdr agent get <supervisor-name>` and `herdr agent read <supervisor-name> --source recent-unwrapped --lines 120`.
   Read the progress record for the current task and blockers.
3. If a provider timeout or transient session failure stopped unfinished work, send `herdr agent prompt <supervisor-name> "Continue."`.
4. If permission or another developer's conflicting work blocks progress, send this direction:
   `herdr agent prompt <supervisor-name> "Keep the blocked item pending. Continue another authorized part of the agreed plan that does not depend on it."`
5. If the supervisor is working or waiting for an active job or executor, leave it alone.
   Treat `unknown`, quiet output, and elapsed time as inconclusive. Inspect the actual failure before sending a prompt.
6. Respect an explicit user pause or stop. Never approve a permission prompt, dismiss a denial, or take over conflicting work.
   If a permission UI prevents message delivery, record that blocker without interacting with its approval controls.
   Do not restart completed or canceled work.
7. Record each inspection and intervention. Send at most one intervention per hourly inspection, then resume the wait.

The watchdog only inspects and prompts the supervisor. It does not edit code, direct executors, merge PRs, deploy, or spawn agents.
The supervisor retains all task decisions. If no independent authorized work remains, keep the blocker pending and report it to the user.

## Execute One PR

1. Fetch the latest target branch. Start a fresh branch from that target for this issue in the assigned checkout.
2. Claim the matching Relay issue under the resolved actor, as required by repository instructions.
3. Create a sibling Herdr pane in the current tab and assigned checkout with `--no-focus`.
4. Start the executor through the existing `codex` alias, with `gpt-6.1-sol` unless the user specifies another model.
5. Send one short initial prompt with the issue, relevant plan context, acceptance criteria, and supervisor contact command.

Use this prompt structure:

```text
Build a ready-for-review PR for <issue> from <plan reference>. Acceptance criteria: <criteria>. Use checkout <path> and branch <branch>. Own <area>. Coordinate changes to shared interfaces through <supervisor-name>. Build the smallest working MVP that fits the current app. Check the main user flow with live testing where available. Prioritize architecture, integration, and observed defects. Add edge-case handling only for an observed failure or explicit requirement. Preserve security and data boundaries. Any permitted new tests must check observable results through public interfaces. Obey any rule against adding tests. Commit and open the PR, but do not merge. Do not spawn agents. If told to hold, save your state and wait for explicit resume. Contact <supervisor-name> only when done, blocked, or acknowledging a hold: herdr agent prompt <supervisor-name> "<executor-name>: <PR link and checks, blocker, or hold acknowledgement>". Send no interim progress messages.
```

Use normal hooks and relevant local checks. Select full CI only when repository instructions or the affected scope require it.
Do not broaden the issue with speculative safeguards, abstraction, or unrelated cleanup.

## Wait and Respond

Use the event-driven wait procedure in supervisor-executor. Wait in a process, not through repeated model turns or short polling loops.
For two executors, wait on both concurrently within that process. Resume when either executor needs attention.
Exclude held executors from active waits until explicit resume.
Send no routine status requests to the executor. Resume for completion, a help request, an actionable failure, or user input.

When the executor needs help, inspect the issue and any existing PR. Give a concrete decision or correction within the plan.
If required user input or access is missing, record and report the blocker. Leave the affected PR unmerged.
Continue independent authorized work from the plan within the two-executor limit.
After giving direction, resume the wait. A help request does not imply that the PR is ready to merge.

## Control the Review Queue

Keep one ordered queue of help requests, corrections, reviews, and merges in the progress record.
Prioritize actionable blockers and corrections over new assignments. Process one review or merge decision at a time.

If concurrent messages or pending reviews become difficult to track, tell one or both executors to hold:

```text
Hold at the next safe stopping point. Save your work and current check results. Acknowledge once, then wait for explicit resume. Do not start another task or send progress messages.
```

Let active commands finish safely. Record the held state and the next action for each executor.
Stop assigning work until the queue is manageable. Then send an explicit resume with the next task or correction.
A held executor still occupies its slot. The watchdog must not treat an intentional hold as a failure.

## Review and Merge

The supervisor owns review and merge decisions.

1. Read the PR diff, acceptance criteria, check evidence, and review comments.
2. Review architecture, simplicity, and integration with the current app. Focus on misplaced responsibilities, duplicated paths, and broken contracts.
3. Check the main user flow and observable results. Fix missing requirements and failures found through routine use.
4. Reply to reviewer questions on the PR. Obey repository rules for comment prefixes.
5. If changes are needed, send specific corrections to the same executor. Keep its pane open and repeat review after completion.
6. After approval, complete the repository's required checks for squash merge on a clean, committed PR head. Record the checked SHA and results.
7. For Glass Bio, use the current repository's scope-based local checks and evidence-reuse rules. Keep normal hooks enabled.
8. Require selected checks and required GitHub gates to pass. Record missing, skipped, pending, failed, and canceled results accurately.
   Never request, dispatch, or rerun remote CI, tests, or audits. Deployment follows its separate authorization rules.
9. Check that the PR still targets the agreed branch and its head matches the reviewed SHA immediately before merging.
   Stop on an unexpected head change. After expected corrections, review the changes and run the affected checks.
   Reuse valid check evidence under repository rules, with the actual checked SHA and reuse reason.
10. Merge with `gh pr merge <pr> --squash --match-head-commit <reviewed-sha>`. Check that the merge completed.
11. Record the merge SHA and PR link. Close the resolved Relay issue under repository rules.
    Close the executor pane with `herdr pane close <pane-id>`.
12. Assign the next unblocked issue to a fresh executor within the two-executor limit.

Do not bypass failed checks or close a pane while its executor still needs to correct the PR.
If a merge fails, resolve the actual failure before advancing dependent work. Independent work can continue.

## Review the Complete Module

After all planned PRs merge, review the complete module as it exists on the latest target branch.
Use a clean checkout and record its SHA. Read the resulting code, its callers, and the surrounding app.
Review the total result against the original plan, beyond the individual PR diffs and check receipts.

- Assess how the module fits the app's architecture, including responsibilities, dependencies, state ownership, and shared interfaces.
- Check that the combined implementation forms one simple user flow without duplicate mechanisms or unnecessary layers.
- Exercise representative real inputs through the app's public interfaces. Inspect actual outputs, saved results, and visible failures.
- Run as much live testing as the available environment and authorization allow. Inspect the rendered UI for UI work.
- For Marble, do all available headless checks and state exactly which installed-app flows still need live testing.
- Preserve required security and data boundaries. Spend review effort on the main workflow and defects observed during routine testing.

If hosted behavior needs the combined changes, assess an AWS redeployment as part of this final review.
Use existing deployment authorization for the target environment and the repository's deployment procedure.
If authorization is missing, prepare the exact SHA, environment, and deployment action before requesting it.
Continue independent local checks while permission or conflicting deployment work remains pending.
After an authorized deployment, exercise the live user flow and record the deployed SHA, environment, results, and concrete limitations.

If the review finds a concrete defect within the plan, create a focused correction issue through the repository's tracker.
Record it in the progress record.
Use a new executor pane and the same PR, review, and squash-merge cycle. Then repeat the affected feature checks.
Reassess the final module after corrections. If live testing requires the corrected code, redeploy within the existing authorization and repeat it.
Do not expand the feature beyond the agreed plan. Report out-of-scope findings separately.
Avoid speculative edge-case hardening, broad refactors, and new abstractions without a demonstrated need.

Do not declare completion from merged PRs alone. Approve the complete module only after the integrated review and available live checks.
If a required check remains blocked, report the unfinished acceptance item and its blocker. Do not label it complete.
At completion, stop the watchdog's wait process and close all executor and watchdog panes created for this workflow.
On an explicit user stop, shut down the watchdog. On an explicit pause, suspend its interventions until the user resumes.

Report the architecture and user-flow result, PR links, live checks, and remaining limitations concisely.
Keep merge status, reviewed and checked SHAs, local CI results, and deployment evidence separate from the change summary.
