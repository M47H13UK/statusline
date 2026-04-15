# Claude Code Multi-Account Alias Setup

A guide for setting up X number of isolated Claude Code instances, each with its own authentication, so you can cycle between multiple Max subscription accounts to distribute rate limits.

---

## How It Works

Claude Code reads its config from `~/.claude/` by default. The env var `CLAUDE_CONFIG_DIR` overrides this. By creating separate config directories (`~/.claude-1/`, `~/.claude-2/`, ..., `~/.claude-N/`) and shell aliases that set `CLAUDE_CONFIG_DIR`, each alias runs Claude Code with isolated auth while sharing settings, skills, plugins, hooks, etc. via symlinks.

The default `claude` command remains completely untouched.

---

## Setup Steps (for N accounts)

### 1. Create Config Directories

For each instance `i` from 1 to N:

```bash
mkdir -p ~/.claude-$i
```

### 2. Symlink Shared Config

These files/dirs should be **symlinked** so changes propagate across all instances:

```bash
for i in $(seq 1 N); do
  ln -sf ~/.claude/CLAUDE.md ~/.claude-$i/CLAUDE.md
  ln -sf ~/.claude/settings.json ~/.claude-$i/settings.json
  ln -sf ~/.claude/projects ~/.claude-$i/projects
  ln -sf ~/.claude/skills ~/.claude-$i/skills
  ln -sf ~/.claude/plugins ~/.claude-$i/plugins
  ln -sf ~/.claude/hooks ~/.claude-$i/hooks
  ln -sf ~/.claude/agents ~/.claude-$i/agents
  ln -sf ~/.claude/commands ~/.claude-$i/commands
  ln -sf ~/.claude/teams ~/.claude-$i/teams
  ln -sf ~/.claude/statusline-command.sh ~/.claude-$i/statusline-command.sh
done
```

**Why symlink these specifically:** settings, skills, plugins, hooks, agents, commands, and teams are config you want consistent everywhere. `projects/` holds per-project CLAUDE.md and conversation history — symlinked so all instances see the same project context. `statusline-command.sh` is the status bar script referenced by `settings.json`.

### 3. Copy (Don't Symlink) Sessions & History

Sessions and history should be **copied** (independent snapshots) to avoid write conflicts:

```bash
for i in $(seq 1 N); do
  cp -r ~/.claude/sessions ~/.claude-$i/sessions
  cp ~/.claude/history.jsonl ~/.claude-$i/history.jsonl
done
```

After this, each instance accumulates its own session history independently.

### 4. Add Shell Aliases

Append to `~/.zshrc` (or `~/.bashrc`):

```bash
for i in $(seq 1 N); do
  echo "alias claude${i}=\"CLAUDE_CONFIG_DIR=~/.claude-${i} claude\"" >> ~/.zshrc
done
```

This produces aliases like:

```bash
alias claude1="CLAUDE_CONFIG_DIR=~/.claude-1 claude"
alias claude2="CLAUDE_CONFIG_DIR=~/.claude-2 claude"
# ... etc
```

Then reload: `source ~/.zshrc`

### 5. Authenticate Each Instance

Each alias needs its own `/login`. This is the only manual step.

```bash
claude1   # launches Claude Code with ~/.claude-1 config
# then type: /login
# authenticate with Account A
```

```bash
claude2   # launches Claude Code with ~/.claude-2 config
# then type: /login
# authenticate with Account B
```

**On macOS:** credentials are stored in the system Keychain, not as files. Each config dir gets a unique Keychain entry (e.g. `Claude Code-credentials-<hash>`). No `.credentials.json` file will appear — this is normal.

**Remote auth (different machine):** if the subscription account is only logged in on another machine:
1. Run `/login` in the alias — it prints an OAuth URL
2. Copy that URL and open it in a browser on the machine where the account is logged in
3. Complete the OAuth flow there — the local instance picks up the auth

**Windows-to-Mac credential transfer:** if the other machine is Windows, install Claude Code there, `/login`, then find the credentials at `%APPDATA%\claude\.credentials.json` and copy it to `~/.claude-N/.credentials.json` on Mac. (Note: on macOS the Keychain is preferred, but file-based creds also work.)

---

## Verification

After setup, verify:

```bash
# Check aliases resolve
which claude1
which claude2

# Check symlinks are correct
ls -la ~/.claude-1/
ls -la ~/.claude-2/

# Check each has independent sessions
ls ~/.claude-1/sessions/
ls ~/.claude-2/sessions/

# Check auth (macOS)
security find-generic-password -s "Claude Code-credentials" -a "" 2>&1 | head -5
```

---

## Usage

```bash
claude                                    # default account (~/.claude/)
claude1                                   # account A (~/.claude-1/)
claude2                                   # account B (~/.claude-2/)
claude1 --dangerously-skip-permissions    # account A, skip permissions
claude2 --dangerously-skip-permissions    # account B, skip permissions
```

All flags work identically — the alias just sets `CLAUDE_CONFIG_DIR` before calling the real `claude` binary.

---

## Important Notes

- **Default `claude` is untouched.** `~/.claude/` is never modified. The original command keeps working with its own auth and history.
- **Same account on multiple aliases is fine** but pointless for rate limit cycling — they share the same rate limits. Use different accounts.
- **Symlinked `projects/` means shared conversation history.** All instances see the same past conversations per project. This is usually what you want.
- **Each instance accumulates its own:** `backups/`, `cache/`, `file-history/`, `image-cache/`, `paste-cache/`, `plans/`, `session-env/`, `shell-snapshots/`, `tasks/`, `telemetry/`. These are created automatically on first use.
- **Memory system:** if using `~/.claude/projects/<project>/memory/`, this is shared via the `projects` symlink.

---

## Directory Structure (after setup, per instance)

```
~/.claude-1/
  CLAUDE.md            -> ~/.claude/CLAUDE.md          (symlink)
  settings.json        -> ~/.claude/settings.json      (symlink)
  projects/            -> ~/.claude/projects/           (symlink)
  skills/              -> ~/.claude/skills/             (symlink)
  plugins/             -> ~/.claude/plugins/            (symlink)
  hooks/               -> ~/.claude/hooks/              (symlink)
  agents/              -> ~/.claude/agents/             (symlink)
  commands/            -> ~/.claude/commands/           (symlink)
  teams/               -> ~/.claude/teams/              (symlink)
  statusline-command.sh -> ~/.claude/statusline-command.sh (symlink)
  sessions/            (independent copy)
  history.jsonl        (independent copy)
  backups/             (auto-created on use)
  cache/               (auto-created on use)
  file-history/        (auto-created on use)
  plans/               (auto-created on use)
  session-env/         (auto-created on use)
  tasks/               (auto-created on use)
  ...
```
