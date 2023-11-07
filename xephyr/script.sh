#!/bin/bash

# Launch Xephyr to create a nested X11 display
Xephyr :1 -ac -screen 1280x720 &
sleep 1

# Set the DISPLAY variable to the nested X11 display
export DISPLAY=:1

# Launch the web browser and position it on the left side of the screen
firefox --new-window --width 640 --height 720 --geometry 0x0 &
sleep 1

# Launch Cheese to display your image in the lower right-hand corner
cheese --geometry 640x360+640+360 &
sleep 1

# Launch a terminal emulator and position it over the image
xterm -geometry 640x360+640+0 &

# Wait for the user to close the windows
read -p "Press Enter to exit..."

# Clean up and terminate the Xephyr display
killall Xephyr