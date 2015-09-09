#!/bin/bash
#############################################
#
# This code create a backup of files
# and keep a history of modifications
# which can be browsable
#
# Created: Dec 27,2014
# Last Modified: Mar 11, 2015
#
#############################################
LANGUAGE=ja
LANG=ja_JP.UTF-8
LC_CTYPE=ja_JP.UTF-8

DEBUG=1
# Link before making changes (faster): experimental 
FASTLINK=1
BACKDIR="/mnt/back";
# If History directory exists, overwrite it
OVERWRITE=0

LOG="/var/log/backer/";
# Main directory (write access)
CURRENT="/mnt/current/";

#NOTE: BACKUP and HISTORY must be in the same file system where this script reside
# Yesterday's version (read-only)
BACKUP="$BACKDIR/yesterday";
# Progresive history (read-only)
HISTORY="$BACKDIR/history";

#Main sync params:
# "Remote" means from CURRENT to BACKUP (it may be located in the same fs system, but is called "remote")
RSYNC_REMOTE="-lrt --fuzzy --delete"
# "Local" means from BACKUP to HISTORY (as they must be in the same fs system)
RSYNC_LOCAL="-lrt"

#Update BACKUP version with CURRENT and log changes:
DATE=`date +%Y-%m-%d`
if [[ $DEBUG == 1 ]]; then
    echo "$DATE: Starting";
fi

function testProblem
{
    TEST=$(ls "${HIST_TODAY}/\\\#3*")
    if [[ $TEST != "" ]]; then
        echo "Problem found............................";
        read -p "Press [Enter] key to continue";
    fi
}

# Set readonly
function permits
{
    FILE_PERMS=644;
    DIR_PERMS=755;
    USER=2502;
    GROUP=2513;
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

# Test if the directory of a new file will exist or not
# @param $1: File to be copied
function test_dir_for_file
{
    if [[ $DEBUG == 1 ]]; then
        echo "testing dir: $1..."
    fi
    if [[ "$1" == "" ]]; then
        echo "Incorrect number of parameters [$1]";
        exit_this;
    fi
    UPDIR=$(dirname "$1");
    ifmkdir $UPDIR
}

ifmkdir $BACKUP
ifmkdir $HISTORY
ifmkdir $LOG
YESTERDAY=$(ls -rc "$HISTORY/" | tail -n 1);
HIST_YESTERDAY="$HISTORY/$YESTERDAY";
HIST_TODAY="$HISTORY/$DATE";
if [[ -d "$HIST_TODAY" ]]; then
    if [[ $OVERWRITE == 1 ]]; then
        if [[ $DEBUG == 1 ]]; then
            echo "Directory existed: $HIST_TODAY, removing";
        fi
        rm -rf "$HIST_TODAY";
        YESTERDAY=$(ls -1c "$HISTORY/" | head -n 1);
        HIST_YESTERDAY="$HISTORY/$YESTERDAY";
    else
        echo "Directory exist: $HIST_TODAY";
        exit;
    fi
fi
if [[ $DEBUG == 1 ]]; then
    echo "Previous Directory: $HIST_YESTERDAY";
fi
ifmkdir "$HIST_TODAY";
if [[ "$HIST_YESTERDAY" == $HIST_TODAY ]]; then
    echo "Last Directory can not be the same as Current";
    exit_this;
fi


# Run the first time or each time the "base" history
# directory needs to be recreated
function reset
{
    if [[ $DEBUG == 1 ]]; then
        echo "Resetting base dir:";
    fi
    rsync $RSYNC_REMOTE "$CURRENT/" "$BACKUP/"
    permits "$BACKUP/" recursive ro
    rsync $RSYNC_LOCAL --link-dest="$BACKUP/" "$BACKUP/" "$HIST_TODAY/"
    echo "Done.";
    exit;
}

if [[ "$1" == "reset" ]]; then
    reset;
fi

# Ensure we are back to normal
function exit_this
{
    exit;
}

if [[ $DEBUG == 1 ]]; then
    echo "Calculating changes between $CURRENT and $BACKUP"
fi
if [[ $FASTLINK == 1 ]]; then
    ITEMIZE="-i"
else
    ITEMIZE="-ii" #display all files (even those which didn't change
fi

rsync -n $ITEMIZE $RSYNC_REMOTE "$CURRENT/" "$BACKUP/" > $LOG/$DATE.log
mapfile -t CHANGES < $LOG/$DATE.log
gzip -9 -f $LOG/$DATE.log

if [[ $FASTLINK == 1 ]]; then
    if [[ $DEBUG == 1 ]]; then
        echo "Fast Linking...."
    fi
    rsync $RSYNC_LOCAL --link-dest="$HIST_YESTERDAY/" "$HIST_YESTERDAY/" "$HIST_TODAY/"
fi
if [[ $DEBUG == 1 ]]; then
    echo "Processing changes...";
fi

for CHANGE in "${CHANGES[@]}"; do
    #testProblem
    ACTION=${CHANGE%%[[:space:]]*};
    FILE=${CHANGE#*[[:space:]]};
    #FILE=${FILE##*([[:space:]])}; #TODO: more elegant way to trim leading spaces?
    FILE=$(echo -e "${FILE}" | sed -e 's/^[[:space:]]*//');
    case "${ACTION:0:3}" in
     "cd+")
        echo "[LOG] CREATED: $ACTION $FILE"
        if [[ $FASTLINK == 0 ]]; then
            ifmkdir "$HIST_TODAY/$FILE"
        fi
        permits "$HIST_TODAY/$FILE" single ro
     ;;
     ">f+")
        test_dir_for_file "$HIST_TODAY/$FILE";
        echo "[LOG] ADDED: $ACTION $FILE"
        test_dir_for_file "$BACKUP/$FILE";
        rsync $RSYNC_REMOTE "$CURRENT/$FILE" "$BACKUP/$FILE"
        permits "$BACKUP/$FILE" single ro
        if [[ $FASTLINK == 1 ]]; then
            echo "    UNLINK: $HIST_TODAY/$FILE";
            rm -f "$HIST_TODAY/$FILE";
        fi
        echo "    LINK: $HIST_TODAY/$FILE -> $BACKUP/$FILE";
        ln "$BACKUP/$FILE" "$HIST_TODAY/$FILE"
     ;;
     ">f.")
        test_dir_for_file "$HIST_TODAY/$FILE";
        echo "[LOG] UPDATED: $ACTION $FILE"
        #unlink if possible:
        rm -f "$BACKUP/$FILE"
        rsync $RSYNC_REMOTE "$CURRENT/$FILE" "$BACKUP/$FILE"
        permits "$BACKUP/$FILE" single ro
        if [[ $FASTLINK == 1 ]]; then
            echo "    UNLINK: $HIST_TODAY/$FILE";
            rm -f "$HIST_TODAY/$FILE";
        fi
        echo "    LINK: $HIST_TODAY/$FILE -> $BACKUP/$FILE";
        ln "$BACKUP/$FILE" "$HIST_TODAY/$FILE"
     ;;
     "*de")
        echo "[LOG] DELETE: $ACTION $FILE";
        if [[ $FASTLINK == 1 ]]; then
            rm -rf "$HIST_TODAY/$FILE"
        fi
        #else: nothing to be done as it won't be linked (in case of FASTLINK == 0)
     ;;
     *)
        case "${ACTION:0:2}" in
             ".d")
                #directory not modified
                if [[ $FASTLINK == 0 ]]; then
                    if [[ ! -d "$HIST_TODAY/$FILE" ]]; then
                        ifmkdir "$HIST_TODAY/$FILE";
                        permits "$HIST_TODAY/$FILE" ro
                    fi
                fi
             ;;
             ".f")
                if [[ $FASTLINK == 0 ]]; then
                    echo "(NO CHANGE) LINK: $HIST_TODAY/$FILE -> $BACKUP/$FILE";
                    #file not modified
                    ln "$BACKUP/$FILE" "$HIST_TODAY/$FILE"
                fi
             ;;
            *)
                echo "[LOG] $ACTION $FILE";
            ;;
        esac
     ;;
    esac
    #if [[ $DEBUG == 1 ]]; then
    #    read -p "Press [Enter] key to continue"
    #fi
done
exit_this
