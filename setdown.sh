#!/bin/bash

host=juno
src=~/src

function backup { scp -r $@ $host:dump-$(hostname)/; }
function burm   { backup $@ && rm -rf $@; }

function countdown {
    clocks=(🔥 🕛 🕚 🕙 🕘 🕗 🕖 🕕 🕔 🕓 🕒 🕑 🕐)
    for i in $(seq $1 1); do
        echo "${clocks[$i]}  // $i..."
        sleep 1s
    done
    echo "${clocks[0]}  // GO!"
}

echo "[WARNING] Burn in 5 seconds! 🔥"
countdown 5

echo "--- Entering root ---"
ssh root@localhost -t <<EOF
dscl . change /Groups/com.apple.access_ssh-disabled RecordName com.apple.access_ssh-disabled com.apple.access_ssh
rm -rf /var/log/*
rm -rf /var/at/tabs
rm -rf /var/root/.*
EOF
echo "--- Leaving root ---"

rm -rf {/tmp,~,$src}/setdown*
ssh $host -t "mkdir -p ~/dump-$(hostname)"
prox off
rm -rf ~/.bin

echo "Backing up git projects..."
cd $src
unsaved=()
for f in *; do
    # if is a file, isn't a git repository, or has unpushed changes
    if [ -f $f ] || ! [ -e $f/.git ] || [[ $(git -C $f status --porcelain) ]]; then
        unsaved+=($f)
    else echo $f >> /tmp/repos.txt; fi
done
echo "Found ${#unsaved[@]} files needing backup. (${unsaved[@]})"
echo "Compressing..."
tar -cf /tmp/src.tar ${unsaved[@]}
echo "Sending to server..."
burm /tmp/repos.txt /tmp/src.tar


rm -rf $src/{fish,net}
rm ~/.*history
rm -f ~/Library/Saved\ Application\ State/com.apple.Terminal.savedState/*
rm ~/.ssh/known_hosts*

wait

##############################################
# Assume nothing past this message will run. #
##############################################

echo "Burn complete. Killing terminals..."

countdown 3

#killall term Terminal ayy i_term iTerm2
#killall tmux screen
