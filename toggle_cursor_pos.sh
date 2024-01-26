#!/bin/bash

# Get the current mouse position
eval $(xdotool getmouselocation --shell)

# Toggle between monitors
# if mouse is on left screen 
if [ $X -lt 1920 ]; then
# move mouse to middle of right screen
    xdotool mousemove 3840 1080
    echo 'on left screen'
# else, mouse is on right screen
else
# move mouse to middle of left screen
    xdotool mousemove 960 1080
    echo 'on right screen'
    
fi
