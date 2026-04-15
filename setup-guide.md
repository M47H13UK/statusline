# Claude Code Status Line Setup

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed
- `jq` installed (`brew install jq` on mac, `sudo apt install jq` on linux)

## Setup

### 1. Copy the script

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

### 2. Configure Claude Code

Open Claude Code and paste this prompt:

```
Configure my status line to use the script at ~/.claude/statusline-command.sh. Add this to my ~/.claude/settings.json:

{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

Or manually add the `statusLine` block above to your `~/.claude/settings.json`.

### 3. Restart Claude Code

Restart Claude Code to see the status line.

## What it shows

**Line 1:** Model name | context usage bar + % + token count | rate limits (5h/7d with reset timers) | session cost

**Line 2:** lines added/removed | cumulative input/output tokens | version | working directory + git branch

Rate limits are cached to `/tmp/.claude-rate-limits-cache.json` so they persist between refreshes even when the input doesn't include them.
