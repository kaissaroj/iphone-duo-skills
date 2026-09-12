#!/usr/bin/env bash
# Claude Code PostToolUse hook: after any Edit/Write to a .swift file, run the
# iPhone Duo scanner on that file and surface findings to the agent.
#
# Install (project): add to .claude/settings.json
# {
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Edit|Write|MultiEdit",
#       "hooks": [{ "type": "command", "command": "bash .claude/skills/iphone-duo-audit/../../hooks/duo-check-on-edit.sh" }]
#     }]
#   }
# }
# or, if you installed via `npx skills add`, point the command at wherever this
# file lives (e.g. "bash hooks/duo-check-on-edit.sh" from the repo root).
set -u
input=$(cat)
file=$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))' 2>/dev/null)
case "$file" in
  *.swift) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0
here="$(cd "$(dirname "$0")" && pwd)"
scanner=""
for c in "$here/../skills/iphone-duo-audit/scripts/duo_audit.sh" \
         ".claude/skills/iphone-duo-audit/scripts/duo_audit.sh" \
         "$HOME/.claude/skills/iphone-duo-audit/scripts/duo_audit.sh"; do
  [ -f "$c" ] && { scanner="$c"; break; }
done
[ -n "$scanner" ] || exit 0
tmp=$(mktemp -d); cp "$file" "$tmp/"; out=$(bash "$scanner" "$tmp" 2>/dev/null | grep -E '^\[' | sed "s|$(basename "$file")|$file|"); rm -rf "$tmp"
if [ -n "$out" ]; then
  printf 'iPhone Duo scan of %s found candidate issues (see iphone-duo-audit/references/checklist.md):\n%s\n' "$file" "$out"
fi
exit 0
