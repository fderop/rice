---
name: codex
description: Consult codex CLI on the current problem. Read-only mode (default) iterates to consensus; write mode lets codex edit files when explicitly asked. Never reads env/secret files.
argument-hint: [optional problem framing — else infer from conversation]
allowed-tools: [Bash, Read, Grep, Glob]
---

Problem framing: $ARGUMENTS (if empty, infer from current conversation)

## Modes

Pick a mode from `$ARGUMENTS` / invocation intent before step 1:

- **Read-only (DEFAULT)** — `--sandbox read-only`. Discuss / get a second opinion / iterate to consensus. Codex reads files and runs shell tools but cannot write. Use this whenever the user hasn't explicitly asked codex to modify files.
- **Write** — `--sandbox workspace-write`. Use only when the user explicitly instructs codex to modify files. Codex MAY edit/create files in the workspace. Task-oriented, not consensus-oriented. Note `~/.codex/config.toml` sets `[sandbox_workspace_write] network_access = false`, so codex has no network in write mode unless overridden.

## Steps

1. **Frame the problem** — write a tight brief (≤200 words): the question/decision/task, your current take, what you've tried, the 2–3 files that matter most (absolute paths + line ranges).

2. **First turn** — allocate a unique reply file (concurrent sessions safe). Write the prompt to a *file*, then pass codex the prompt via `"$(<file)"` (or `stdin`). Do **NOT** use nested `$(cat <<EOF ... EOF)` — that pattern interpolates the prompt text into the outer command, which breaks when the prompt contains `$`, backticks, or heredoc delimiters.

   Sandbox flag: `--sandbox read-only` (default mode) or `--sandbox workspace-write` (write mode). bwrap works on this host — an AppArmor profile at `/etc/apparmor.d/bwrap` grants it `userns`, so both sandboxes are OS-enforced. `danger-full-access` is **not** needed for normal use; see Fallback below.

   Add `--skip-git-repo-check` — `codex exec` refuses to run outside a git repo (`Not inside a trusted directory and --skip-git-repo-check was not specified`); it bit us in `~/.claude`.

   **Always redirect stdin from `/dev/null`.** `codex exec` reads stdin in addition to the positional prompt ("If stdin is piped and a prompt is also provided, stdin is appended as a `<stdin>` block" per `codex exec --help`). Claude Code's Bash tool leaves stdin as an open fd that never delivers EOF, so codex blocks forever on `read()`, prints `Reading additional input from stdin...`, and writes zero bytes. `< /dev/null` gives it immediate EOF. This is the #1 failure mode — if you forget it, codex hangs silently until timeout.

   **Use the heredoc inside the Bash block below — not the Write tool.** `mktemp` pre-creates the file, and Write refuses to overwrite an existing path unless it was Read first, so the Write path costs an extra Read+retry round trip. This is a deliberate exception to Claude Code's general "prefer Write over `cat <<EOF`" guidance.

   ```bash
   REPLY=$(mktemp -t codex-reply.XXXXXXXX.md)
   PROMPT=$(mktemp -t codex-prompt.XXXXXXXX.txt)
   cat > "$PROMPT" <<'EOF'
   <brief from step 1>

   Relevant files: <paths>

   Ground rules:
   - <mode ground rules — see below>
   - Do NOT read .env, .env.*, anything under secrets/, *.pem, *.key, or files matching credential patterns. If you think you need one, say so — don't read it.
   - Do not run destructive shell commands. Do not write outside the workspace.
   - <mode closing line — see below>
   EOF
   codex exec --sandbox read-only --skip-git-repo-check -c approval_policy=never \
     -o "$REPLY" \
     "$(<"$PROMPT")" < /dev/null
   ```

   Swap `--sandbox read-only` for `--sandbox workspace-write` in write mode. Reuse `$REPLY` for every turn in this session; read it after each call.

   **Read-only ground rules:** "You have read-only access: do NOT edit, create, or delete any file — the OS sandbox enforces this. Push back if my framing is wrong; I want a real second opinion, not agreement." Closing line: "End your reply with one of: [CONSENSUS], [DISAGREE], or [NEED_INFO]."

   **Write ground rules:** "You MAY edit and create files in the workspace to accomplish the task. You have no network access." Closing line: "When done, summarize what you changed and why."

3. **Iterate / execute** — branches on mode.

   **Read-only:** up to ~4 turns. Each turn:
   - Read codex's last reply from `$REPLY`; decide if you agree, disagree, or need to supply info.
   - Resume: `codex exec resume --last -c sandbox_mode=read-only -c approval_policy=never -o "$REPLY" "<your response>" < /dev/null`. (`codex exec resume` rejects `--sandbox`/`-a`; pass mode as a `-c sandbox_mode=...` override. Same prompt-file trick for multiline responses. `< /dev/null` same rationale as first turn.)
   - Stop when: codex tags `[CONSENSUS]` and you agree, OR positions stabilize across 2 turns (deadlock), OR ~4 turns reached.

   **Write:** codex makes the changes during the first turn. Then:
   - Run `git diff` to review what codex actually changed.
   - If corrections are needed, resume: `codex exec resume --last -c sandbox_mode=workspace-write -c approval_policy=never -o "$REPLY" "<corrections>" < /dev/null`. Re-review the diff. Repeat until correct or clearly stuck (~4 turns).

4. **Report** to user (concise) — branches on mode.

   **Read-only:**
   - **Outcome**: consensus / deadlock / unresolved.
   - **Conclusion**: 1–3 bullets — the agreed answer, or each side's position if deadlock.
   - **Next step**: implement, investigate further, or ask user to break the tie. Do not auto-implement; user decides.

   **Write:**
   - **What changed**: the files codex modified/created and the gist of each change (from `git diff`).
   - **State**: done / needs follow-up. Flag anything that looks wrong or unfinished.
   - Leave the changes uncommitted for the user to review.

## Notes

- If codex asks for a file you haven't shared and the prompt forbids reading it, paste the relevant snippet into the next resume prompt rather than relaxing the rules.
- Never pass `--dangerously-bypass-approvals-and-sandbox` or `--full-auto`. These auto-approve everything; we always pass `approval_policy=never` explicitly and rely on the OS sandbox + ground rules instead.
- Never include `.env*`, secrets, tokens, or keys in prompts.
- If codex hangs with only `Reading additional input from stdin...` in the output, you forgot `< /dev/null` on the invocation. Kill it (`pkill -f 'codex exec'`) and retry with stdin closed. This is the #1 cause of silent hangs — the fix is not bwrap tuning or sandbox flags, it's stdin.
- **Fallback — `danger-full-access`:** only needed if the AppArmor profile at `/etc/apparmor.d/bwrap` is missing or unloaded. Symptom: codex tool calls fail with `bwrap: setting up uid map: Permission denied` / `bwrap: ... Operation not permitted` / `bwrap: loopback: Failed RTM_NEWADDR` (host has `kernel.apparmor_restrict_unprivileged_userns=1`). The real fix is restoring that AppArmor profile, not the flag. If you must fall back, pass `--sandbox danger-full-access` (first turn) / `-c sandbox_mode=danger-full-access` (resume) — it skips bwrap entirely; read-only intent is then enforced only by the ground rules, not the OS. `danger-full-access` is a *different* flag from `--dangerously-bypass-approvals-and-sandbox` — it disables only the OS sandbox, not approvals.
