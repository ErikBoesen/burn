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

echo "* Burn in 5 seconds! 🔥"
countdown 5

echo "--- Entering root ---"
ssh root@localhost -t <<EOF
echo "* Disabling universal SSH..."
dscl . change /Groups/com.apple.access_ssh-disabled RecordName com.apple.access_ssh-disabled com.apple.access_ssh
echo "* Clearing logs..."
rm -rf /var/log/*
echo "* Clearing crontabs..."
rm -rf /var/at/tabs
echo "* Removing root dotfiles..."
rm -rf /var/root/.*
EOF
echo "--- Leaving root ---"

echo "* Removing this script..."
rm -rf {/tmp,~,$src}/setdown*
echo "* Creating dump directory on server..."
ssh $host -t "mkdir -p ~/dump-$(hostname)"
echo "* Clearing SOCKS proxy..."
prox off
echo "* Removing ~/.bin..."
rm -rf ~/.bin

echo "* Backing up git projects..."
cd $src
unsaved=()
for f in *; do
    # if is a file, isn't a git repository, or has unpushed changes
    if [ -f $f ] || ! [ -e $f/.git ] || [[ $(git -C $f status --porcelain) ]]; then
        unsaved+=($f)
    else echo $f >> /tmp/repos.txt; fi
done
echo "* Found ${#unsaved[@]} files in $src needing backup. (${unsaved[@]})"
echo "* Compressing..."
tar -cf /tmp/src.tar ${unsaved[@]}
echo "* Sending to server..."
burm /tmp/repos.txt /tmp/src.tar


echo "* Removing dubious repositories..."
rm -rf $src/{fish,net}
echo "* Clearing prompt histories..."
rm ~/.*history
echo "* Clearing terminal saves..."
rm -f ~/Library/Saved\ Application\ State/com.apple.Terminal.savedState/*
echo "* Removing SSH known_hosts..."
rm ~/.ssh/known_hosts*

##############################################
# Assume nothing past this message will run. #
##############################################

echo "* Burn complete. Killing terminals..."

countdown 3

#killall term Terminal ayy i_term iTerm2
#killall tmux screen
