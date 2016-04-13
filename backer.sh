#!/bin/bash
#############################################
#
# This code create a backup of files
# using hard links to use as less space as
# possible. It will keep one copy per day
# which can be browsed as normal files.
# Recommended: Execute this script in cron.daily
#
# Created: Dec 27,2014
# Last Modified: September 16, 2015
#
# Example structure:
# /mnt/work  <-- CURRENT: The directory that you want to backup
# /mnt/back  <-- BACKDIR: The directory where you want to store your backups
# /mnt/back/2015-09-16/  <--- Will create a daily snapshot of your files
#
#############################################
# Language Settings
export LANGUAGE=en
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Main directory (write access) <-- it can be a remote address as well
CURRENT="/mnt/work";
# Directory where to store the backup
BACKDIR="/mnt/back";
# Where to store "rsync" logs
LOG="/var/log/backer/";

# Progresive history (read-only)
HISTORY="$BACKDIR/";
# Yesterday's version (read-only)
BACKUP="$BACKDIR/";

#Main sync params:
# "Remote" means from CURRENT to BACKUP (it may be located in the same fs system, but is called "remote")
RSYNC="-Aogplrt --delete";

#Update BACKUP version with CURRENT and log changes:
DATE=`date +%Y-%m-%d`
if [[ $DEBUG == 1 ]]; then
    echo "$DATE: Starting";
fi

# Set readonly
function permits
{
    FILE_PERMS=644;
    DIR_PERMS=755;
    if [[ "$3" == "ro" ]]; then
        FILE_PERMS=444;
        DIR_PERMS=555;
    fi
    if [[ $DEBUG == 1 ]]; then
        echo "Setting permissions in $1";
    fi

    if [[ "$2" == "single" ]]; then
        if [[ -f $1 ]]; then
            chmod $FILE_PERMS $1;
        fi
        if [[ -d $1 ]]; then
            chmod $DIR_PERMS $1;
        fi
        chown ${USER}.${GROUP} $1;
    elif [[ "$2" == "recursive" ]]; then
        find "$1" -type d -exec chmod $FILE_PERMS {} \;
        find "$1" -type f -exec chmod $DIR_PERMS {} \;
        find "$1" -exec chown ${USER}.${GROUP} {} \;
    fi
}

# If directory doesn't exist, create it (make parents if needed)
function ifmkdir
{
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
        permits "$1" single
        if [[ $DEBUG == 1 ]]; then
            echo "Creating Directory: $1";
        fi
    fi
}

ifmkdir $BACKUP
ifmkdir $HISTORY
ifmkdir $LOG
HIST_TODAY="$HISTORY/$DATE";
PREVIOUS=$(ls -rc "$HISTORY/" | tail -n 1);
echo "Previous: $PREVIOUS";
if [[ "$PREVIOUS" == "" ]]; then
    echo "No previous backup found. creating first";
    echo "First copy" > $LOG/$DATE.log
    rsync $RSYNC "$CURRENT/" "$HIST_TODAY/"
    exit 2;
fi
HIST_PREVIOUS="$HISTORY/$PREVIOUS";
echo "Logging changes..."
rsync -n $RSYNC "$CURRENT/" "$HIST_TODAY/" > $LOG/$DATE.log
gzip -9 -f $LOG/$DATE.log

echo "Backing up..."
rsync $RSYNC --link-dest="$HIST_PREVIOUS/" "$CURRENT/" "$HIST_TODAY/"
exit 1
