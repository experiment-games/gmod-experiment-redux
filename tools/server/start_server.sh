#!/bin/bash

# This script is used to start the server.
# Add it to your crontab to start the server on boot. We use tmux to be able to reattach to the server console.
#
#       (As the `steam` user:)
# 1.    Install tmux: `sudo apt-get install tmux`
#
# 2.    Run `crontab -e`
#
# 3.    Add `@reboot /home/steam/start_server.sh`
#
# 4.    Save and exit the editor
#
# 5.    Reboot the server: `sudo reboot`
#
# 6.    To reattach execute the ./reattach_server.sh script
#

echo "============================================" >> /home/steam/server_launcher.log
echo "Experiment Server Launch @ $(date):" >> /home/steam/server_launcher.log

cmd="/home/steam/server_1/srcds_run -console \
        -game garrysmod \
        -tickrate 100 \
        +maxplayers 64 \
        +gamemode experiment-redux \
        +map exp_c18_v1_alpha034 \
        +host_workshop_collection 3215035081 \
        +sv_setsteamaccount REPLACE_WITH_STEAM_API_KEY"

# If you want to start the server and attach immediately, run ./start_server.sh debug
if [ "$1" == "debug" ]; then
    $cmd >> /home/steam/server_launcher.log
else
    /usr/bin/tmux new-session -d -s srcds "$cmd >> /home/steam/server_launcher.log"
fi
