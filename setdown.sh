#!/bin/bash
set +x

# This script helps with cleaning up my MacBook. It automatically backs up needed
# files to my SSH server (aliased as "serv") and removes anything private before
# reimaging.

# Backup files over SSH, then remove, given paths
function burm {
    (scp -r $@ serv:dump-$(hostname)/; rm -rf $@) &
}

if [ "$TERM" = "screen" ]; then
    echo "Running as in screen or tmux. Will continue."
else
    echo "Please run in screen or tmux."
    exit 1
fi

ssh root@localhost -t <<EOF
echo "Turning off SSHD for all users..."
dscl . change /Groups/com.apple.access_ssh-disabled RecordName com.apple.access_ssh-disabled com.apple.access_ssh

echo "Clearing logs..."
rm -rf /var/log/*

echo "Removing root ssh folder..."
rm -rf /var/root/.ssh

echo "Clearing crontabs..."
rm -rf /var/at/tabs

echo "Removing all dotfiles/folders in root dir..."
rm -rf /var/root/.*
EOF

src=~/src

echo "Burn beginning in 5 seconds..."
sleep 5s

echo "Removing this script..."
rm -rf ~/setdown* &

echo "Making dump dir on server..."
ssh serv -t "mkdir -p ~/dump-$(hostname)"

echo "Disabling proxy..."
prox off

echo "Removing ~/bin..."
rm -rf ~/.bin &

echo "Backing up git projects..."
touch ~/repos.txt
for dir in $(ls $src); do
    # if file/folder either isn't a GitHub repository or has unpushed changes
    # This way we don't waste time copying a bunch of repos which are already on GitHub
    if [ -f $src/$dir ] || ! [ -e $src/$dir/.git ] || [[ $(git -C $src/$dir status --porcelain) ]]; then
        burm $src/$dir
    else
        echo $dir >> ~/repos.txt
    fi
done
burm ~/repos.txt

echo "Removing repositories..."
rm -rf $src/fish $src/net &

echo "Getting rid of prompt histories..."
rm ~/.*history

echo "Clearing terminal backups..."
rm -f ~/Library/Saved\ Application\ State/com.apple.Terminal.savedState/*

echo "Removing user's SSH known_hosts..."
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

echo "Killing terminals..."

killall term Terminal ayy i_term iTerm2

echo "Killing all multiplex sessions..."
killall tmux
killall screen
