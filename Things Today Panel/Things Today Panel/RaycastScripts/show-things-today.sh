#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Show Things Today
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎯
# @raycast.packageName Things Today Panel
# @raycast.description Show your Things Today tasks in a floating panel

# Documentation:
# @raycast.author Andrew Wilkinson
# @raycast.authorURL https://github.com/andrewwilkinson

# Launch or focus the Things Today Panel app
open -a "Things Today Panel"

# If the app is already running, this will bring it to front
# The app itself handles showing/hiding the floating panel
