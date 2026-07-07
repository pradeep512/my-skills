#!/usr/bin/env bash
# Print when the Claude 5h/7d windows reset, from ~/.claude/rate-limit-cache.json
# (written by your statusline — see REFERENCE.md "Reset time"). macOS + Linux.
cache="$HOME/.claude/rate-limit-cache.json"
[ -f "$cache" ] || { echo "No cache yet. Set up the statusline tee (REFERENCE.md) or open a session first."; exit 1; }
now=$(date +%s)
# portable epoch->local formatter (BSD vs GNU date)
fmt() { date -r "$1" "+%a %I:%M %p" 2>/dev/null || date -d "@$1" "+%a %I:%M %p"; }
one() {
  local label="$1" pct="$2" res="$3"
  [ -z "$res" ] || [ "$res" = null ] && return
  local p="—"; [ -n "$pct" ] && [ "$pct" != null ] && p="$(printf '%.0f%%' "$pct")"
  if [ "$res" -gt "$now" ] 2>/dev/null; then
    local r=$(( res - now ))
    printf "  %-3s %s used · resets %s (in %dh %02dm)\n" "$label" "$p" "$(fmt "$res")" $((r/3600)) $(((r%3600)/60))
  else printf "  %-3s %s used · window already reset\n" "$label" "$p"; fi
}
fh_p=$(jq -r '.five_hour.used_percentage // empty' "$cache"); fh_r=$(jq -r '.five_hour.resets_at // empty' "$cache")
sd_p=$(jq -r '.seven_day.used_percentage // empty' "$cache"); sd_r=$(jq -r '.seven_day.resets_at // empty' "$cache")
echo "Claude usage limits:"
one "5h" "$fh_p" "$fh_r"
one "7d" "$sd_p" "$sd_r"
