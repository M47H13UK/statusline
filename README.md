# Claude Code status line and multi-account aliases

Two tools for [Claude Code](https://claude.ai/claude-code):

1. **Status line.** Info bar (model, context bar, rate limits, cost, tokens, git branch)
2. **Multi-account aliases.** `claude1`, `claude2`, … isolated instances to cycle between Max subscriptions and distribute rate limits

---

## Status line

![Status line example](status_line_example_image.png)

**Line 1:** model · context bar + % + tokens · 5h/7d rate limits with reset timers · session cost
**Line 2:** lines +/- · cumulative input/output tokens · version · cwd + git branch

Rate limits are cached to `/tmp/.claude-rate-limits-cache.json` so they persist across refreshes.

### Install

See [setup-guide.md](setup-guide.md) for manual steps, or paste [setup-prompt.md](setup-prompt.md) into Claude Code to install automatically.

Requires `jq` (`brew install jq` / `sudo apt install jq`).

---

## Multi-account aliases

Run isolated Claude Code instances, each with its own auth, sharing settings/skills/plugins via symlinks. The default `claude` command stays untouched.

![claude1 alias](claude1_alias.png)
![claude2 alias](claude2_alias.png)

```bash
claude                                    # default account
claude1 --dangerously-skip-permissions    # account A
claude2 --dangerously-skip-permissions    # account B
```

### Install

Full walkthrough: [setup-aliases-claude-code-guide.md](setup-aliases-claude-code-guide.md).
Agent prompt (automated): [setup-aliases-claude-code-prompt.md](setup-aliases-claude-code-prompt.md).
