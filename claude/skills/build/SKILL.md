---
name: build
description: End-to-end pipeline — branch off main, implement the idea, codex-review the diff, fix what's safe, and ship a PR. Pauses only when a real decision needs the user.
argument-hint: <idea>
allowed-tools: [Bash, Agent, Read, Edit, Write, Grep, Glob, Skill]
---

Idea: $ARGUMENTS

If empty, ask user for the idea and stop.

This skill is a one-shot pipeline. Stay in the driver's seat across steps — don't ask the user "ready to continue?" between phases. Only stop for actual ambiguity that affects the code (unclear scope, choice between meaningfully different approaches, missing info you can't infer). Recoverable noise (lint nits, obvious bugfixes flagged by codex) gets fixed silently.

## Steps

1. **Branch + scope** — invoke `Skill(new, <idea>)`. That skill creates the branch and dispatches a sonnet agent. When it returns, you have either:
   - A completed implementation (feat/fix/refactor path) → go to step 3.
   - A written investigation (investigate path) → the user asked for analysis, not code. Report `new`'s output and stop. Don't force /codex or /ship on an investigation branch.

2. **Clarify only if blocking** — if the agent dispatched by `/new` reports back with a genuine ambiguity (e.g. "two valid schemas, which?"), surface it to the user with `AskUserQuestion` and resume after they answer. Don't manufacture questions to feel safe — if you can make the reasonable call, make it.

3. **Codex review** — invoke `Skill(codex, review the diff on this branch vs <default-branch>. Focus on correctness, missed edge cases, and anything that would block a PR. Skip style nits already covered by formatters.)`. The codex skill handles the framing details; you just trigger it and read the result.

4. **Triage codex output**:
   - **Safe fixes** (clear bug, missing null check, off-by-one, dead branch, obviously-wrong type): fix them directly with Edit. Run formatters/tests if the repo has them. Commit tersely.
   - **Judgment calls** (architectural disagreement, scope expansion, "consider doing X instead"): surface the most important 1–2 with `AskUserQuestion`. Ignore the rest — codex is a second opinion, not a checklist.
   - **Consensus or no issues**: continue.

5. **Ship** — invoke `Skill(ship)`. That handles local CI, push, and PR creation. Don't merge.

6. **Final report** — three sections, terse:
   - **PR**: URL from `/ship`.
   - **What changed**: 1–3 bullets, the actual code-level changes (not "added feature X" — name files/functions touched).
   - **What you should test**: concrete steps the user can run. Golden path + the 1–2 edge cases most likely to break. If you couldn't test something yourself (UI, external service, manual flow), say so explicitly.

## Notes

- Per global CLAUDE.md: don't push to main, don't close Relay issues, stay on the feature branch after merge.
- If any step fails hard (e.g. `/new` aborts on dirty tree, `/ship` fails CI), stop and report. Don't paper over failures to keep the pipeline running.
- If the user invoked `/build` from a non-repo or a dirty tree, `/new` will catch it — don't pre-validate.
