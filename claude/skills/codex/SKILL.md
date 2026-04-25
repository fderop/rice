---
name: codex
description: Discuss the current problem with codex CLI, iterate until consensus or deadlock, report the outcome. Codex gets read-only repo access except env/secret files.
argument-hint: [optional problem framing — else infer from conversation]
allowed-tools: [Bash, Read, Grep, Glob]
---

Problem framing: $ARGUMENTS (if empty, infer from current conversation)

## Steps

1. **Frame the problem** — write a tight brief (≤200 words): the question/decision, your current take, what you've tried, the 2–3 files that matter most (absolute paths + line ranges).

2. **First turn** — allocate a unique reply file (concurrent sessions safe). Write the prompt to a *file*, then pass codex the prompt via `"$(<file)"` (or `stdin`). Do **NOT** use nested `$(cat <<EOF ... EOF)` — that pattern interpolates the prompt text into the outer command, which breaks when the prompt contains `$`, backticks, or heredoc delimiters.

   Use `--sandbox danger-full-access`. On this host (Ubuntu 24.04+, `kernel.apparmor_restrict_unprivileged_userns=1`) bwrap fails for unconfined parents — both `read-only` and `workspace-write` modes abort with `bwrap: setting up uid map: Permission denied` or `bwrap: loopback: Failed RTM_NEWADDR`, so codex can't run *any* shell tools (no `git`, no `cat`, no file reads). `danger-full-access` skips bwrap entirely. **This is not the same flag as `--dangerously-bypass-approvals-and-sandbox`** (which also skips approvals and is forbidden) — `danger-full-access` only disables the OS sandbox; we still pass `approval_policy=never` separately and rely on the ground-rules prompt to enforce read-only intent at the model layer.

   **Always redirect stdin from `/dev/null`.** `codex exec` reads stdin in addition to the positional prompt ("If stdin is piped and a prompt is also provided, stdin is appended as a `<stdin>` block" per `codex exec --help`). Claude Code's Bash tool leaves stdin as an open fd that never delivers EOF, so codex blocks forever on `read()`, prints `Reading additional input from stdin...`, and writes zero bytes. `< /dev/null` gives it immediate EOF. This is the #1 failure mode — if you forget it, codex hangs silently until timeout.

   ```bash
   REPLY=$(mktemp -t codex-reply.XXXXXXXX.md)
   PROMPT=$(mktemp -t codex-prompt.XXXXXXXX.txt)
   cat > "$PROMPT" <<'EOF'
   <brief from step 1>

   Relevant files: <paths>

   Ground rules:
   - You have read-only intent: do NOT edit, create, or delete any file. Do not run destructive shell commands. The sandbox is unconfined — read-only is enforced by you, not the OS.
   - Do NOT read .env, .env.*, anything under secrets/, *.pem, *.key, or files matching credential patterns. If you think you need one, say so — don't read it.
   - Push back if my framing is wrong. I want a real second opinion, not agreement.
   - End your reply with one of: [CONSENSUS], [DISAGREE], or [NEED_INFO].
   EOF
   codex exec --sandbox danger-full-access -c approval_policy=never \
     -o "$REPLY" \
     "$(<"$PROMPT")" < /dev/null
   ```
   
   Reuse `$REPLY` for every turn in this session. Read it after each call.

3. **Iterate** — up to ~4 turns. Each turn:
   - Read codex's last reply from `$REPLY`; decide if you agree, disagree, or need to supply info.
   - Resume: `codex exec resume --last -c sandbox_mode=danger-full-access -c approval_policy=never -o "$REPLY" "<your response>" < /dev/null`. (`codex exec resume` rejects `--sandbox`/`-a`; pass them as `-c` overrides instead. Same prompt-file trick applies for multiline responses. `< /dev/null` same rationale as first turn.)
   - Stop when: codex tags `[CONSENSUS]` and you agree, OR positions have stabilized across 2 turns (deadlock), OR ~4 turns reached.

4. **Report** to user (concise):
   - **Outcome**: consensus / deadlock / unresolved.
   - **Conclusion**: 1–3 bullets — the agreed answer, or each side's position if deadlock.
   - **Next step**: what to do (implement, investigate further, ask user to break tie).
   
   Do not auto-implement. User decides.

## Notes

- If codex asks for a file you haven't shared and the prompt forbids reading it, paste the relevant snippet into the next resume prompt rather than relaxing the rules. With `danger-full-access`, codex *can* read anything — the ground rules are the only thing stopping it.
- Never pass `--dangerously-bypass-approvals-and-sandbox` or `--full-auto`. Note: `--sandbox danger-full-access` is a *different* flag (only disables the OS sandbox, doesn't auto-approve) and is the right choice here.
- Never include `.env*`, secrets, tokens, or keys in prompts.
- If codex hangs with only `Reading additional input from stdin...` in the output, you forgot `< /dev/null` on the invocation. Kill it (`pkill -f 'codex exec'`) and retry with stdin closed. This is the #1 cause of silent hangs — the fix is not bwrap tuning or sandbox flags, it's stdin.
- If codex tool calls fail with `bwrap: setting up uid map: Permission denied` or `bwrap: loopback: Failed RTM_NEWADDR`, the host has `kernel.apparmor_restrict_unprivileged_userns=1`. Use `--sandbox danger-full-access` (this skill's default). The proper system-level fix is to install an AppArmor profile that allows `bwrap` — out of scope for this skill.
