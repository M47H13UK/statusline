# Status Line Setup Prompt

Paste this prompt into Claude Code to install the status line automatically.

---

```
Do the following steps in order, no questions asked:

1. Check that `jq` is installed by running `which jq`. If missing, install it (`brew install jq` on mac, `sudo apt install jq` on linux).

2. Copy the file `statusline-command.sh` from this directory to `~/.claude/statusline-command.sh` and make it executable (`chmod +x`).

3. Configure my status line by adding this to my `~/.claude/settings.json` (merge with existing content if the file already exists — don't overwrite other settings):

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/statusline-command.sh"
     }
   }
   ```

4. Tell me to restart Claude Code to activate the status line.
```
