#!/bin/bash
#############################################
#
# This code create a backup of files
# and keep a history of modifications
# which can be browsable
#
# Created: Dec 27,2014
# Last Modified: May 28th, 2016
#
#############################################

echo "Start:" >> /tmp/time
date >> /tmp/time

export LANGUAGE=ja
export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8

BACKDIR="/backup/daily";
# If History directory exists, overwrite it
OVERWRITE=0
LOG="/var/log/backer";
# Main directory (to backup)
CURRENT="/var/www/ONLINE";
MAX_DAYS_KEEP=15

#NOTE: BACKUP and HISTORY must be in the same file system where this script reside
# Progresive history (read-only)
HISTORY="$BACKDIR";
# Yesterday's version (read-only)
BACKUP="$BACKDIR";

#Main sync params:
# "Remote" means from CURRENT to BACKUP (it may be located in the same fs system, but is called "remote")
RSYNC="-Aogplrt --delete --exclude-from=/etc/backer.exclude"

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
        mkdir -p "$1/"
        permits "$1/" single
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
rsync -n $RSYNC "$CURRENT/" "$HIST_PREVIOUS/" &> $LOG/$DATE.log
gzip -9 -f $LOG/$DATE.log
#echo "Unlocking:" (no need. taken care by samba)
#chattr -R -i "$HIST_PREVIOUS/"
echo "Linking..."
rsync $RSYNC --link-dest="$HIST_PREVIOUS/" "$CURRENT/" "$HIST_TODAY/"
#echo "Locking:"
#chattr -R +i "$HIST_PREVIOUS/"
#chattr -R +i "$CURRENT/"
echo "Stop:" >> /tmp/time
date >> /tmp/time
#Proceed to remove very old directories
OLDER_DATE=`date +%Y%m%d -d "$MAX_DAYS_KEEP days ago"`;
find $HISTORY -maxdepth 1 -type d | while read dir_to_test; do
    x=$(basename "$dir_to_test")
    if [[ $OLDER_DATE > ${x:0:4}${x:5:2}${x:8:2} ]]; then
        rm -rvf "$dir_to_test"
        rm -f $LOG/$x.log.gz
        # Temporally, run dry
        echo "$dir_to_test" > /root/deleted.log
    fi
done
#Protect against modifications by www-data
#chown -R root $HIST_TODAY/
exit 1
