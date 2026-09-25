#!/usr/bin/env bash
# https://code.claude.com/docs/en/statusline#build-a-status-line-step-by-step
# Read JSON data that Claude Code sends to stdin
input=$(cat)

# Extract fields using jq
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
# The "// 0" provides a fallback if the field is null
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Day/week spend across ALL sessions (ccusage), refreshed in the background
# so the statusline itself never blocks on it.
# Installed by: `npm i -g ccusage`
# See: https://github.com/ccusage/ccusage
COST_CACHE="/tmp/.claude-statusline-cost-cache"
COST_LOCK="/tmp/.claude-statusline-cost.lock"
COST_TTL=60
COST_THRESHOLD_DAILY=100
COST_THRESHOLD_WEEKLY=500
CONTEXT_THRESHOLD=30

# ANSI escape sequences (literal ESC byte, no further interpretation needed)
COLOR_RED=$'\033[31m'
COLOR_ORANGE=$'\033[38;5;208m'
COLOR_RESET=$'\033[0m'

# Orange at 75-100% of threshold, red beyond it, empty otherwise.
threshold_color() {
  local value="$1" threshold="$2" pct
  pct=$(awk -v v="$value" -v t="$threshold" 'BEGIN { printf "%.4f", (t > 0) ? (v / t * 100) : 0 }')
  if awk -v p="$pct" 'BEGIN { exit !(p > 100) }'; then
    printf '%s' "$COLOR_RED"
  elif awk -v p="$pct" 'BEGIN { exit !(p >= 75) }'; then
    printf '%s' "$COLOR_ORANGE"
  fi
}

refresh_cost_cache() {
  local day_cost week_cost
  day_cost=$(ccusage daily --json --last 1 2>/dev/null | jq -r '.totals.totalCost // 0')
  week_cost=$(ccusage weekly --json --last 1 2>/dev/null | jq -r '.totals.totalCost // 0')
  printf '%s %s\n' "$day_cost" "$week_cost" > "${COST_CACHE}.tmp" && mv "${COST_CACHE}.tmp" "$COST_CACHE"
}

cache_age=$COST_TTL
if [ -f "$COST_CACHE" ]; then
  cache_mtime=$(stat -f %m "$COST_CACHE" 2>/dev/null || stat -c %Y "$COST_CACHE" 2>/dev/null || echo 0)
  cache_age=$(( $(date +%s) - cache_mtime ))
fi

if [ "$cache_age" -ge "$COST_TTL" ] && mkdir "$COST_LOCK" 2>/dev/null; then
  ( refresh_cost_cache; rmdir "$COST_LOCK" ) >/dev/null 2>&1 &
  disown 2>/dev/null
fi

if [ -f "$COST_CACHE" ]; then
  read -r DAY_COST WEEK_COST < "$COST_CACHE"
else
  DAY_COST="…"
  WEEK_COST="…"
fi
[ "$DAY_COST" != "…" ] && DAY_COST=$(printf '%.2f' "$DAY_COST")
[ "$WEEK_COST" != "…" ] && WEEK_COST=$(printf '%.2f' "$WEEK_COST")

# Colours a "LABEL: $cost" pair orange at 75-100% of threshold, red beyond it.
colorize_cost() {
  local cost="$1" threshold="$2" label="$3"
  if [ "$cost" = "…" ]; then
    printf '%s: $%s' "$label" "$cost"
    return
  fi
  local color
  color=$(threshold_color "$cost" "$threshold")
  if [ -n "$color" ]; then
    printf '%s%s: $%s%s' "$color" "$label" "$cost" "$COLOR_RESET"
  else
    printf '%s: $%s' "$label" "$cost"
  fi
}

DAY_PART=$(colorize_cost "$DAY_COST" "$COST_THRESHOLD_DAILY" "D")
WEEK_PART=$(colorize_cost "$WEEK_COST" "$COST_THRESHOLD_WEEKLY" "W")

CONTEXT_COLOR=$(threshold_color "$PCT" "$CONTEXT_THRESHOLD")
if [ -n "$CONTEXT_COLOR" ]; then
  CONTEXT_PART="${CONTEXT_COLOR}${PCT}% context${COLOR_RESET}"
else
  CONTEXT_PART="${PCT}% context"
fi

# Output the status line - ${DIR##*/} extracts just the folder name
echo "[$MODEL] 📁 ${DIR##*/} | ${CONTEXT_PART} | ${DAY_PART}, ${WEEK_PART}"


# # Claude Code status line — PS1-style display + model + context progress bar
# input=$(cat)

# # PS1-style: user@host dir
# cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
# dir=$(basename "$cwd")
# ps1_part="$(whoami)@$(hostname -s) $dir"

# # Model display name
# model=$(echo "$input" | jq -r '.model.display_name // ""')

# # Context progress bar
# used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
# if [ -n "$used" ]; then
#   used_int=$(printf "%.0f" "$used")
#   filled=$(( used_int / 5 ))
#   empty=$(( 20 - filled ))
#   bar=""
#   for i in $(seq 1 $filled); do bar="${bar}#"; done
#   for i in $(seq 1 $empty); do bar="${bar}-"; done
#   ctx_part="[${bar}] ${used_int}%"
# else
#   ctx_part=""
# fi

# # Combine: PS1 | Model | Context
# if [ -n "$model" ] && [ -n "$ctx_part" ]; then
#   printf "%s | %s | %s" "$ps1_part" "$model" "$ctx_part"
# elif [ -n "$model" ]; then
#   printf "%s | %s" "$ps1_part" "$model"
# else
#   printf "%s" "$ps1_part"
# fi
