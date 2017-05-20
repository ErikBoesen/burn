#!/bin/bash

# <!> WARNING!! <!>
# DO NOT RUN THIS UNLESS YOU KNOW WHAT YOU ARE DOING.
# YOU WILL LOSE FILES.

# This should be run from the /var/root directory (preferably) and must be run as an administrator.

# It's recommended that this be run in tmux so it runs in the background with no evidence.

echo "Removing this script before we start (will continue running regardless)..."
rm -rf /var/root/detonate*

echo "Turning of SSHD for all users, which is off by default and could raise some red flags if noticed..."
dscl . change /Groups/com.apple.access_ssh-disabled RecordName com.apple.access_ssh-disabled com.apple.access_ssh

echo "Giving /usr/local back to root..."
chown -R root /usr/local

echo "Making an iTunes folder..."
# To divert suspicion of having root. Obviously if they look in it they'll notice all the content is gone, but this will at least prevent them noticing something's up if for some reason they happen to ls /Applications.
mkdir /Applications/iTunes.app

echo "Removing Transmission..."
rm -rf /Users/boesene/Documents/Transmission.app

echo "Backing up fish credentials folder..."
scp -r /Users/boesene/creds serv:~/compdump/creds
echo "Removing fish credentials folder..."
rm -rf /Users/boesene/creds

echo "Removing ~/bin..." # Some scripts, like sget, might raise some eyebrows
rm -rf /Users/boesene/bin

echo "Making dump directory on server..."
# Makes a Desktop folder inside it just to save time later on
ssh serv -t "mkdir -p ~/compdump/Desktop"

echo "Removing any/all dotfiles in root directory, some of which maybe shouldn't be there... (also removing this script)"
rm -rf /var/root/.*

echo "Clearing logs..."
rm -rf /var/log/*

echo "Backing up zshrc before removal..."
scp /Users/boesene/.zshrc serv:~/compdump/.zshrc

echo "Removing .zshrcs..." # So as to not expose the 'elev' alias and give away root access means
rm /Users/*/.zshrc
echo "Getting rid of all prompt histories..."
rm /Users/*/.*history /var/root/.*history # root's should have been removed already, but just in case

echo "Removing fish if it's downloaded..." # It's usually not, but if it was that could be very bad if found.
rm -rf /Users/boesene/Desktop/fish
rm -rf /Users/boesene/fish

echo "Backing up all files on Desktop which aren't updated on GitHub. (Repositories with uncommitted changes WILL be backed up.)"
for directory in `ls /Users/boesene/Desktop`; do
    cd "/Users/boesene/Desktop/$directory"
    if [ ! -d "/Users/boesene/Desktop/$directory/.git" ] || [[ `git status --porcelain` ]]; then
        echo "- Copying $directory..."
        scp -r "/Users/boesene/Desktop/$directory" "serv:~/compdump/Desktop/$directory"
    fi
done

echo "Disabling terminal session restoration..."
# I myself already have this set to false.
defaults write com.apple.Terminal NSQuitAlwaysKeepsWindows -bool false

echo "Wipe complete. Will kill all terminal sessions in three seconds."

for i in 3 2 1; do
    echo "$i..."
    sleep 1s
done

echo "Killing terminal to clear any residual evidence..."

clear;clear;clear;clear;clear;clear

killall term
killall Terminal

#echo "Killing all tmux sessions in case this is somehow still running..."
killall tmux

clear;clear;clear;clear;clear;clear

exit
