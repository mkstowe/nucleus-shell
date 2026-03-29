#!/bin/bash

START_DIR="$HOME/Pictures/wallpapers"

get_monitors() {
    if command -v hyprctl >/dev/null 2>&1; then
        local hypr_monitors
        hypr_monitors=$(hyprctl -j monitors 2>/dev/null | jq -r '.[].name' 2>/dev/null)
        if [ -n "$hypr_monitors" ]; then
            printf '%s\n' "$hypr_monitors"
            return 0
        fi
    fi

    if command -v xrandr >/dev/null 2>&1; then
        local xrandr_monitors
        xrandr_monitors=$(xrandr --query 2>/dev/null | grep " connected" | cut -d" " -f1)
        if [ -n "$xrandr_monitors" ]; then
            printf '%s\n' "$xrandr_monitors"
            return 0
        fi
    fi

    return 1
}

MONITORS=$(get_monitors)

# Convert monitors into Zenity list arguments
LIST_ARGS=()
for m in $MONITORS; do
    LIST_ARGS+=("$m")
done

if [ ${#LIST_ARGS[@]} -eq 0 ]; then
    zenity --error \
        --title="Wallpaper Picker" \
        --text="No monitors were detected. Make sure Hyprland is running and try again." \
        2>/dev/null
    echo "null"
    exit
fi

DISPLAY=$(zenity --list \
    --title="Select Display" \
    --column="Monitor" \
    "${LIST_ARGS[@]}" \
    --height=300 \
    --width=300 2>/dev/null)

# User cancelled
[ -z "$DISPLAY" ] && echo "null" && exit

FILE=$(zenity --file-selection \
    --title="Select Wallpaper for $DISPLAY" \
    --filename="$START_DIR/" \
    --file-filter="Images/Videos | *.png *.jpg *.jpeg *.webp *.bmp *.svg *.mp4 *.mkv *.webm *.mov *.avi *.m4v" \
    2>/dev/null)

[ -z "$FILE" ] && echo "null" && exit

# Output format: monitor|wallpaper
echo "$DISPLAY|file://$FILE"
