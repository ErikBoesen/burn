#!/bin/bash

logfile=~/burn_$(date +%s).log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>$logfile 2>&1

echo "🔥  burn.sh 🔥"
if [[ "$1" == "--debug" ]]; then
    debug=true
    echo "⚒  (DEBUG) ⚒"
fi

host=juno
src=~/src

function backup { scp -o "StrictHostKeyChecking no" -r $@ $host:dump-$(hostname)/; }
function burm   { backup $@ && rm -rf $@; }

function task { echo "* $1..."; }
function countdown {
    clocks=(🔥 🕛 🕚 🕙 🕘 🕗 🕖 🕕 🕔 🕓 🕒 🕑 🕐)
    for i in $(seq $1 1); do
        printf "\r${clocks[$i]}  // $i..."
        sleep 1s
    done
    printf "\r"
}

countdown 5

echo "--- <root> ----"
ssh root@localhost -T <<EOF
echo "* Clearing logs..."
rm -rf /var/log/* /Library/Logs/*
EOF
if ! $debug; then
ssh root@localhost -T <<EOF
echo "* Clearing crontabs..."
rm -rf /var/at/tabs
echo "* Disabling universal SSH..."
dscl . change /Groups/com.apple.access_ssh-disabled RecordName com.apple.access_ssh-disabled com.apple.access_ssh
echo "* Removing root dotfiles..."
rm -rf /var/root/.*
EOF
fi
echo "--- </root> ---"

task "Creating dump directory on server..."
ssh -o LogLevel=QUIET $host -t "mkdir -p ~/dump-$(hostname)"

task "Backing up git projects"
cd $src
unsaved=()
for f in *; do
    # if is a file, isn't a git repository, or has unpushed changes
    if [[ -f $f ]] || ! [[ -e $f/.git ]] || [[ $(git -C $f status --porcelain) ]]; then
        unsaved+=($f)
    else git -C $f remote get-url origin >> /tmp/repos.txt; fi
done
echo "- Found ${#unsaved[@]} files in $src needing backup."
echo "- Compressing..."
tar -cf /tmp/src.tar ${unsaved[@]}
echo "- Sending to server..."
burm /tmp/repos.txt /tmp/src.tar

task "Clearing terminal sessions"
rm -f ~/Library/Saved\ Application\ State/com.apple.Terminal.savedState/*
task "Removing burn repository"
rm -rf ~/burn
if ! $debug; then
    task "Clearing prompt histories"
    rm ~/.*history
    task "Clearing SOCKS proxy"
    prox off
    task "Removing ~/.bin"
    rm -rf ~/.bin
    task "Clearing local logs"
    rm -rf ~/Library/Logs/*
fi
task "Sending log file to server"
burm $logfile
if ! $debug; then
    task "Removing SSH known_hosts"
    rm ~/.ssh/known_hosts*
fi

task "Burn complete. Killing terminals"

countdown 3

if ! $debug; then
    killall term Terminal ayy i_term iTerm2
    killall tmux screen
fi
