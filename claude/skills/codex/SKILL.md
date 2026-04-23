---
name: codex
description: Discuss the current problem with codex CLI, iterate until consensus or deadlock, report the outcome. Codex gets read-only repo access except env/secret files.
argument-hint: [optional problem framing — else infer from conversation]
allowed-tools: [Bash, Read, Grep, Glob]
---

Problem framing: $ARGUMENTS (if empty, infer from current conversation)

## Steps

1. **Frame the problem** — write a tight brief (≤200 words): the question/decision, your current take, what you've tried, the 2–3 files that matter most (absolute paths + line ranges).

2. **First turn** — allocate a unique reply file (concurrent sessions safe), invoke codex non-interactively, read-only:

   ```bash
   REPLY=$(mktemp -t codex-reply.XXXXXXXX.md)
   codex exec --sandbox read-only -c approval_policy=never \
     -o "$REPLY" \
     "$(cat <<'EOF'
   <brief from step 1>
   
   Relevant files: <paths>
   
   Ground rules:
   - You have read-only access to the repo. Read any file you need EXCEPT .env, .env.*, anything under secrets/, *.pem, *.key, or files matching credential patterns. If you think you need one, say so — don't read it.
   - Push back if my framing is wrong. I want a real second opinion, not agreement.
   - End your reply with one of: [CONSENSUS], [DISAGREE], or [NEED_INFO].
   EOF
   )"
   ```
   
   Reuse `$REPLY` for every turn in this session. Read it after each call.

3. **Iterate** — up to ~4 turns. Each turn:
   - Read codex's last reply from `$REPLY`; decide if you agree, disagree, or need to supply info.
   - Resume: `codex exec resume --last -c sandbox_mode=read-only -c approval_policy=never -o "$REPLY" "<your response>"`. (`codex exec resume` rejects `--sandbox`/`-a`; pass them as `-c` overrides instead.)
   - Stop when: codex tags `[CONSENSUS]` and you agree, OR positions have stabilized across 2 turns (deadlock), OR ~4 turns reached.

4. **Report** to user (concise):
   - **Outcome**: consensus / deadlock / unresolved.
   - **Conclusion**: 1–3 bullets — the agreed answer, or each side's position if deadlock.
   - **Next step**: what to do (implement, investigate further, ask user to break tie).
   
   Do not auto-implement. User decides.

## Notes

- If codex asks for a file you haven't shared, read it yourself and paste the relevant snippet into the next resume prompt rather than widening its sandbox.
- Never pass `--dangerously-bypass-approvals-and-sandbox` or `--full-auto`.
- Never include `.env*`, secrets, tokens, or keys in prompts.
