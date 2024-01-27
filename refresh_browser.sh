#!/bin/bash

# Find the Chromium window by title and refresh it
WINDOW_TITLE='website - Chromium'

# Use xdotool to find the window ID based on the title
WINDOW_ID=$(xdotool search --onlyvisible --name "$WINDOW_TITLE")

# Check if a window with the specified title is found
if [ -n "$WINDOW_ID" ]; then
    # Activate the window and send the F5 key
    xdotool windowactivate --sync "$WINDOW_ID" key Ctrl+F5
fi