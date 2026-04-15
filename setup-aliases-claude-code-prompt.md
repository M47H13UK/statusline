# Claude Code Multi-Account Alias Setup — Agent Prompt

Use this prompt to have a Claude Code agent set up N isolated Claude Code instances with separate authentication.

Replace `N` with the desired number of accounts (e.g. 2, 3, etc.).

---

## Prompt

```
Set up N Claude Code aliases (claude1 through claudeN) for multi-account rate limit cycling. The default `claude` command and `~/.claude/` directory must NOT be modified in any way.

For each i from 1 to N, do the following:

### Step 1: Create config directory
mkdir -p ~/.claude-$i

### Step 2: Symlink shared config
Symlink these files/dirs from ~/.claude/ into ~/.claude-$i/:
- CLAUDE.md
- settings.json
- projects
- skills
- plugins
- hooks
- agents
- commands
- teams
- statusline-command.sh

Use: ln -sf ~/.claude/<item> ~/.claude-$i/<item>

These are symlinked (not copied) so that settings changes propagate to all instances automatically.

### Step 3: Copy sessions and history (independent, not symlinked)
- cp -r ~/.claude/sessions ~/.claude-$i/sessions
- cp ~/.claude/history.jsonl ~/.claude-$i/history.jsonl

These must be copies, not symlinks, to avoid write conflicts between concurrent instances.

### Step 4: Add shell alias
Append this line to ~/.zshrc (or ~/.bashrc if zsh is not the default shell):
alias claude$i="CLAUDE_CONFIG_DIR=~/.claude-$i claude"

### After all N instances are created:
- Run: source ~/.zshrc
- Verify each alias resolves: which claude1, which claude2, etc.
- Verify symlinks are correct: ls -la ~/.claude-$i/ for each i
- Verify sessions were copied: ls ~/.claude-$i/sessions/ for each i

### Report to the user:
Tell them the next steps they must do manually:
1. Open a new terminal (or source ~/.zshrc)
2. For each alias (claude1, claude2, ...):
   - Run the alias (e.g. `claude1`)
   - Type `/login`
   - Authenticate with the desired account
3. If authenticating from a different machine:
   - The `/login` command prints an OAuth URL
   - Copy that URL and open it in a browser on the machine where the account is logged in
   - Complete the OAuth flow there

### Constraints:
- Do NOT modify ~/.claude/ in any way
- Do NOT attempt /login — it requires interactive OAuth
- Do NOT symlink sessions or history.jsonl — they must be independent copies
- On macOS, credentials are stored in the system Keychain per config dir (no .credentials.json file will appear — this is expected)
- Each instance will auto-create its own: backups/, cache/, file-history/, image-cache/, paste-cache/, plans/, session-env/, shell-snapshots/, tasks/, telemetry/
```
