---
model: claude-haiku-4-5-20251001
effort: low
---

# Relay Issue Tracker

Local issue tracker API at `http://localhost:18000`.

## Agent Rules

0. **No thinking.** This is a simple API wrapper—execute immediately, no internal reasoning. Speed > intelligence.
1. **Always show `_display` verbatim.** Every response includes a `_display` field with pre-formatted text. Output it directly to the user — never reformat, summarize, or extract fields from the JSON.
2. **Always send `X-Actor` header on every request.** Resolve the username once per session by running `git config user.name`, then use the literal string value in all subsequent curl commands. Do NOT use `ACTOR` inline — shell expressions trigger permission prompts.
3. **Never truncate output.** Show the full `_display` content.
4. **CRITICAL — Issue ID resolution:** When ANY command or workflow receives a short alphanumeric argument (e.g., `f47f4`, `ae98a`), treat it as a **Relay issue ID first**. Fetch the issue with `curl http://localhost:18000/issues/{id}` to get the full title and description before doing anything else. This applies to ALL workflow skills (`/workflows:plan`, `/workflows:work`, etc.) — the argument is an issue ID, not a literal feature description.
5. **CRITICAL — Claim issues immediately:** When starting work on a Relay issue, you MUST assign it to the user and mark it as `in_progress` before doing any research or planning:
```bash
curl -X PATCH http://localhost:18000/issues/{id} -H "Content-Type: application/json" -d '{"assignee": "ACTOR", "status": "in_progress"}'
```

## Quick Reference

```bash
# Ready queue (unblocked open issues + project progress)
# X-Actor REQUIRED here — without it, "Yours" and "Team" sections are empty
curl -s http://localhost:18000/issues/ready -H "X-Actor: ACTOR"

# List open issues (includes in_progress)
curl -s "http://localhost:18000/issues?status=open"

# List issues in a project
curl -s "http://localhost:18000/issues?project_id=PROJECT_ID"

# Show project tree
curl -s http://localhost:18000/projects/PROJECT_ID/tree

# Create issue
curl -s -X POST http://localhost:18000/issues \
  -H "Content-Type: application/json" \
  -H "X-Actor: ACTOR" \
  -d '{"title":"...","priority":2,"type":"task","project_id":"PROJECT_ID"}'

# Create project
curl -s -X POST http://localhost:18000/projects \
  -H "Content-Type: application/json" \
  -H "X-Actor: ACTOR" \
  -d '{"title":"...","priority":2}'

# Claim and start
curl -s -X PATCH http://localhost:18000/issues/ISSUE_ID \
  -H "Content-Type: application/json" \
  -d '{"status":"in_progress","assignee":"ACTOR"}'

# Close issue
curl -s -X POST http://localhost:18000/issues/ISSUE_ID/close \
  -H "Content-Type: application/json" \
  -d '{"reason":"Done."}'

# Close project
curl -s -X POST http://localhost:18000/projects/PROJECT_ID/close \
  -H "Content-Type: application/json" \
  -d '{"reason":"Done."}'
```

## Endpoints

### Issues

| Action | Method | Endpoint |
|--------|--------|----------|
| List | GET | `/issues?status=&type=&priority=&assignee=&label=&parent_id=&project_id=&limit=&offset=` |
| Ready | GET | `/issues/ready?limit=&assignee=&priority=&label=` |
| Get | GET | `/issues/{id}` |
| Create | POST | `/issues` |
| Update | PATCH | `/issues/{id}` |
| Close | POST | `/issues/{id}/close` |
| Reopen | POST | `/issues/{id}/reopen` |
| Delete | DELETE | `/issues/{id}` |
| Add dep | POST | `/issues/{id}/deps` |
| List deps | GET | `/issues/{id}/deps` |
| Dep tree | GET | `/issues/{id}/deps/tree` |
| Remove dep | DELETE | `/issues/{id}/deps/{dep_id}` |
| Audit | GET | `/issues/{id}/audit` |

### Projects

| Action | Method | Endpoint |
|--------|--------|----------|
| List | GET | `/projects?status=` |
| Get | GET | `/projects/{id}` |
| Create | POST | `/projects` |
| Update | PATCH | `/projects/{id}` |
| Close | POST | `/projects/{id}/close` |
| Tree | GET | `/projects/{id}/tree` |
| Stats | GET | `/projects/{id}/stats` |

## Headers

- `X-Actor` — who's making the change
- `Content-Type: application/json`

## Fields

- **priority:** 0 (critical) – 4 (backlog), default 2
- **type:** task, bug, feature, chore
- **status:** open, in_progress (use /close to close)
- **dep types:** blocks, related, discovered-from, parent-child
- **project_id:** optional FK to a project (set on issue create/update)

## Notes

- `status=open` returns both open and in_progress issues.
- Projects are containers for issues. Use `project_id` on issues to assign them to a project.
- `GET /projects/{id}/tree` shows the full dependency flow of issues in a project.
- **Display strategy:** `/issues/ready` shows simplified project summaries (name, progress) without dependency trees. When a user asks about a specific project, always show the full tree (e.g., `/projects/{id}` or `/projects/{id}/tree`).
- `created_by` is shown on all display output, defaults to `?` when empty.
- `X-Actor` header is **required** on all endpoints — returns 400 if missing.

## Install / Update

```bash
mkdir -p ~/.claude/skills/relay
curl -s http://localhost:18000/skill > ~/.claude/skills/relay/SKILL.md
```
