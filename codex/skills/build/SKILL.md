---
name: build
description: "Run an end-to-end development workflow from a user idea: create a fresh branch, implement or investigate the task, review the resulting diff for correctness, fix clear issues, and ship a ready-for-review PR when appropriate. Use when the user asks to build a feature end to end, do the whole task, start from an idea and ship it, or invokes build-style workflow language."
---

# Build

Drive the task from idea to PR without stopping between phases unless a real decision blocks progress.

## Workflow

1. Start with the `new` workflow.
   - Create a fresh branch from the latest default branch.
   - If the request is investigative, produce findings and stop. Do not force code changes or PR creation for an investigation unless the user asks.
   - If the request is a feature, fix, or refactor, implement it in the current session.
2. Clarify only if blocked by meaningful ambiguity.
   - If one reasonable interpretation is consistent with the repo and request, choose it.
   - If two choices would lead to materially different product or API behavior, ask.
3. Review the diff before shipping.
   - Inspect `git diff <default>...HEAD`.
   - Look for correctness bugs, missing edge cases, broken contracts, stale generated files, and missing verification.
   - Fix clear bugs directly.
   - Surface judgment calls to the user instead of silently expanding scope.
4. Run relevant checks.
   - Use repo instructions and configured tooling.
   - Do not add tests by default unless local instructions or an actual surfaced bug justify them.
5. Use the `ship` workflow to push and open or update a ready-for-review PR.

## Reporting

Report:

- PR URL
- What changed, with concrete files or components
- Checks run
- Anything the user should manually verify

Do not merge. Do not close Relay issues without explicit approval.
