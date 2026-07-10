#!/bin/sh
# See: https://code.claude.com/docs/en/hooks#notification
INPUT=$(cat)

# Extract a string value from flat JSON by key
json_str() {
    printf '%s' "$INPUT" | sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

NOTIFICATION_TYPE=$(json_str notification_type)
TITLE=$(json_str title)
MESSAGE=$(json_str message)
case "$NOTIFICATION_TYPE" in
    # 2026-05 Claude is getting needy and shouting idle notifications minutes after another prompt = false positives!
    idle_prompt)
        exit 0 ;;
esac

# Fall back to type-specific titles when none provided
if [ -z "$TITLE" ]; then
    case "$NOTIFICATION_TYPE" in
        permission_prompt)  TITLE="Claude needs permission" ;;
        idle_prompt)        TITLE="Claude is waiting" ;;
        auth_success)       TITLE="Claude authenticated" ;;
        elicitation_dialog) TITLE="Claude needs input" ;;
        *)                  TITLE="Claude Code" ;;
    esac
fi

# Escape double quotes for AppleScript
MESSAGE=$(printf '%s' "$MESSAGE" | sed 's/"/\\"/g')
TITLE=$(printf '%s' "$TITLE"   | sed 's/"/\\"/g')

osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
