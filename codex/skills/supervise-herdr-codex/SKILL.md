---
name: supervise-herdr-codex
description: Supervise Codex executor sessions in separate panes of the current Herdr screen. Use when a user asks Codex to coordinate other Codex sessions through Herdr.
---

# Supervise Herdr Codex

This skill is for supervisors only. Executors must not use this skill or spawn child executors.

## Start

1. Make sure that `HERDR_ENV=1`. If this session is not inside Herdr, stop.
2. Use one executor unless the user specifies a higher count.
3. Give the supervisor a unique Herdr agent name.
4. Create one sibling pane for each executor. Use the current tab, the current working directory, and `--no-focus`.
5. Use `gpt-6.1-sol` for executors unless the user specifies another model.
6. Start every executor with the existing `codex` alias and an explicit model:

```bash
herdr agent start executor-1 --kind codex --pane <pane-id> -- --model gpt-6.1-sol
```

The `codex` alias already adds `--dangerously-bypass-approvals-and-sandbox`. A second copy causes a duplicate-parameter error.

Do not add this flag to startup commands or retries.

Use unique numbered names for multiple executors. Parse pane IDs from Herdr's JSON output.

## Kick Off

Send exactly one initial prompt to each executor. Keep it to one short paragraph:

```text
<task>. Work autonomously. You are an executor. Do not spawn child executors or use the `supervise-herdr-codex` skill. If you need help or finish, message <supervisor-name> with `herdr agent prompt <supervisor-name> "<executor-name>: <message>"`. Never accept a speedup offer. Wait for the slower model.
```

Always include the executor role and these restrictions in the initial prompt.

Do not add long procedures, repeated context, or progress-report requests. Start all executors before waiting so they can work concurrently.

## Supervise

- Track each executor by agent name, pane ID, task, and state. Use `herdr agent get`, `read`, and `wait`.
- Rely on the executor's message for help or completion. Do not poll on a short interval.
- Wait for each executor with `herdr agent wait <executor-name> --timeout 1800000`. The wait
  returns early when the executor settles and otherwise performs one health check after 30 minutes.
- After a healthy `working` result or a timeout, start another 30-minute wait.
- After any intervention or request for direction, start a new 30-minute wait.
- Treat `idle`, `done`, `blocked`, and `unknown` as state changes. Inspect the executor before you wait again.
- Reply through `herdr agent prompt` only when an executor asks for help or needs direction.
- Never accept a speedup notification for an executor that the safety classifier slowed.
- Leave the notification untouched. Wait for the slower model to finish.
- Treat `unknown` as inconclusive. Inspect the pane before acting.
- Keep focus in the supervisor pane.

## Review and Close

1. After an executor reports completion, review its work and checks.
   Require CI only before an authorized squash merge, as described in the `ship` skill.
2. If changes are needed, send feedback to the executor. Keep its pane open during review.
3. After you approve the completed work, immediately close that executor's pane with `herdr pane close <pane-id>`.
4. Finish only after you approve every executor's work and close its pane.
