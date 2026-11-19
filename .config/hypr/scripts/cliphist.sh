#!/usr/bin/env bash
# Clipboard history selector using cliphist and fuzzel

# Query cliphist and present with fuzzel
selected=$(cliphist list | fuzzel -d --prompt="Clipboard ❯ " --width=60 --lines=15)

# If an item was chosen, decode and load back into clipboard
if [ -n "$selected" ]; then
    echo "$selected" | cliphist decode | wl-copy
    # Send a quick paste notification or simulate paste if desired
    notify-send -t 1200 -a "Clipboard" "Copied to clipboard" "$(echo "$selected" | cut -d' ' -f2- | head -c 40)..."
fi
