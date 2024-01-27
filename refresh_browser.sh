#!/bin/bash

# Get the title of the currently focused window
CURRENT_WINDOW_TITLE=$(xdotool getactivewindow getwindowname)

# Find THE! Chromium window by title and refresh it
CHROMIUM_WINDOW_TITLE='website - Chromium'
CHROMIUM_WINDOW_ID=$(xdotool search --onlyvisible --name "$CHROMIUM_WINDOW_TITLE")

# Check if a Chromium window with the specified title is found
if [ -n "$CHROMIUM_WINDOW_ID" ]; then
    # Switch to the Chromium window
    xdotool windowactivate --sync "$CHROMIUM_WINDOW_ID"
    
    # Send the F5 key to refresh the Chromium window
    xdotool key Ctrl+F5

    # Switch back to the original window
    xdotool windowactivate --sync "$(xdotool search --onlyvisible --name "$CURRENT_WINDOW_TITLE")"
fi