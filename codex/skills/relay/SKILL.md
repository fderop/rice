---
name: relay
description: Work with the local Relay issue tracker API at localhost:18000. Use when the user mentions Relay, asks for ready issues, gives a short Relay issue ID, asks to claim/start/update/close an issue, or asks about project trees and issue dependencies.
---

# Relay

Use the local Relay API at `http://localhost:18000`.

## Rules

1. Resolve the actor once with `git config user.name`.
2. Send `X-Actor` on every request that supports or requires it.
3. Treat any short alphanumeric argument, such as `f47f4` or `ae98a`, as a Relay issue ID first. Fetch it before planning or working.
4. When starting work on a Relay issue, claim it immediately by setting `assignee` to the actor and `status` to `in_progress`.
5. Never close Relay issues without explicit user approval.
6. Show `_display` verbatim when the API response includes it.
7. Prefer `requests` from Python for HTTP when writing scripts or repo code. For quick interactive Relay API calls, shell HTTP commands are acceptable if no repo code is being added.

## Common Calls

Ready queue:

```bash
curl -s http://localhost:18000/issues/ready -H "X-Actor: ACTOR"
```

List open issues:

```bash
curl -s "http://localhost:18000/issues?status=open" -H "X-Actor: ACTOR"
```

Fetch an issue:

```bash
curl -s http://localhost:18000/issues/ISSUE_ID -H "X-Actor: ACTOR"
```

Claim and start:

```bash
curl -s -X PATCH http://localhost:18000/issues/ISSUE_ID \
  -H "Content-Type: application/json" \
  -H "X-Actor: ACTOR" \
  -d '{"status":"in_progress","assignee":"ACTOR"}'
```

Show a project tree:

```bash
curl -s http://localhost:18000/projects/PROJECT_ID/tree -H "X-Actor: ACTOR"
```

Close an issue only after explicit user approval:

```bash
curl -s -X POST http://localhost:18000/issues/ISSUE_ID/close \
  -H "Content-Type: application/json" \
  -H "X-Actor: ACTOR" \
  -d '{"reason":"Done."}'
```

## Output

If `_display` exists, print it directly. Otherwise summarize only the fields needed for the user's request.
