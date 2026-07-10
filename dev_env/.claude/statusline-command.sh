#!/usr/bin/env bash
# https://code.claude.com/docs/en/statusline#build-a-status-line-step-by-step
# Read JSON data that Claude Code sends to stdin
input=$(cat)

# Extract fields using jq
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
# The "// 0" provides a fallback if the field is null
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Output the status line - ${DIR##*/} extracts just the folder name
echo "[$MODEL] 📁 ${DIR##*/} | ${PCT}% context"


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
