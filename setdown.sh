#!/bin/bash
set -x

# This script helps with cleaning up my MacBook. It automatically backs up needed
# files to my SSH server (aliased as "serv") and removes anything private before
# reimaging.

host=juno
src=~/src

# Backup files over SSH, then remove, given paths
function backup { scp -r $@ $host:dump-$(hostname)/; }
function burm   { (backup $@ && rm -rf $@) &; }

if ! [ "$TERM" = "screen" ]; then
    echo "Please run in screen or tmux."
    exit 1
fi

echo "Burn beginning in 5 seconds..."
sleep 5s

echo "--- Entering root ---"
ssh root@localhost -t <<EOF
set -x
dscl . change /Groups/com.apple.access_ssh-disabled RecordName com.apple.access_ssh-disabled com.apple.access_ssh
rm -rf /var/log/*
rm -rf /var/at/tabs
rm -rf /var/root/.*
EOF
echo "--- Leaving root ---"

rm -rf ~/setdown*
ssh $host -t "mkdir -p ~/dump-$(hostname)"
prox off
rm -rf ~/.bin

echo "Backing up git projects..."
touch ~/repos.txt
for dir in $(ls $src); do
    # if file/folder either isn't a GitHub repository or has unpushed changes
    # This way we don't waste time copying a bunch of repos which are already on GitHub
    if [ -f $src/$dir ] || ! [ -e $src/$dir/.git ] || [[ $(git -C $src/$dir status --porcelain) ]]; then
        backup $src/$dir
    else
        echo $dir >> ~/repos.txt
    fi
done
burm ~/repos.txt

rm -rf $src/{fish,net}
rm ~/.*history
rm -f ~/Library/Saved\ Application\ State/com.apple.Terminal.savedState/*
rm ~/.ssh/known_hosts*

wait

##############################################
# Assume nothing past this message will run. #
##############################################

echo "Wipedown complete. Killing terminals."

for i in 3 2 1; do
    echo "$i..."
    sleep 1s
done

killall term Terminal ayy i_term iTerm2
killall tmux screen
