#!/bin/bash
# This backup all databases and copy it to other computer
# By Alberto Lepe (www.alepe.com, www.support.ne.jp)
# Created: 17III2009
# Modified: 08X2014 (Up to N modifications)
#           21II2015 (skip "mysql")

# --------------------- CONFIG --------------

STOREIN="/backup/sql/"
#PREMOTE="remote_user@remote_host:${STOREIN}"
PREMOTE=""
RSYNCPR="--stats -irpt"
CHARSET="UTF8"
PASSWRD="************"
MYSQLPW=" -uroot -p${PASSWRD} "
MYSQLPM=" --hex-blob --comments=false --default-character-set=${CHARSET} "

LASTLOG=7

#Choose one option to select which DB(s) to backup (default=ALL):
#DBLIST=""
#DBFILE="${CONFIGS}sqldatabases"

#will generate separated files for each db. Can not be used with ALLDATA
SEPARATEDBAKUPS="yes"

###########################################################################
sqlBackup()
{
    TMPFILE="${STOREIN}$1.tmp"
    NEWFILE="${STOREIN}$1.sql"

    if [ -f ${TMPFILE} ]; then # if file exists... 
        if [ -s ${TMPFILE} ]; then # and is not empty
            TMPCKSM=$(cksum ${TMPFILE} | cut -d " " -f 1,2);
            if [ -f "${NEWFILE}.gz" ]; then # check if the gziped file exists
                NEWCKSM=$(zcat "${NEWFILE}.gz" | head -n1 | sed 's/[\/\*]//g');
                if [ "$NEWCKSM" = "$TMPCKSM" ]; then # Are the same
                    #echo "No changes found. removing ${TMPFILE}"
                    rm ${TMPFILE}
                else # There was an update
                    X=$(( LASTLOG - 1 ));
                    for (( b=X; b>=0; b-- )); do
                        t=$((b + 1));
                        BAKFROM="${STOREIN}$1.sql.${b}.gz";
                        BAKTO="${STOREIN}$1.sql.${t}.gz";
                        if [ -f "${BAKFROM}" ]; then
                            #echo "Moving ${BAKFROM} to ${BAKTO} [${b},${t}]";
                            mv ${BAKFROM} ${BAKTO}
                        #else
                        #   echo "${BAKFROM} not found.";
                        fi
                    done
                    #echo "Moving ${NEWFILE}.gz to ${STOREIN}$1.sql.0.gz"
                    mv "${NEWFILE}.gz" "${STOREIN}$1.sql.0.gz"
                    #echo "Moving ${TMPFILE} to ${NEWFILE}"
                    mv ${TMPFILE} ${NEWFILE}
                    sed -i "1i/*${TMPCKSM}*/" ${NEWFILE}
                    gzip ${NEWFILE}
                    chmod 600 "${NEWFILE}.gz"
                    echo -ne " (Updated) "
                fi
            else #... if not, is the first time
                echo "Creating ${NEWFILE}";
                mv ${TMPFILE} ${NEWFILE}
                sed -i "1i/*${TMPCKSM}*/" ${NEWFILE}
                gzip ${NEWFILE}
                chmod 600 "${NEWFILE}.gz"
                echo -ne " (New) "
            fi
        fi
    fi

    echo "Done."
}
#Perform the DUMP
if [ $SEPARATEDBAKUPS = "yes" -a "$1" != "all" ]; then
    if [ "$1" != "" ]; then
        DATABASES=$1
    elif [ ${DBLIST} ]; then
        DATABASES=$(echo ${DBLIST} | tr ' ' '\n')
    elif [ ${DBFILE} ]; then
        if [ -s ${DBFILE} ]; then
            DATABASES=$(cat ${DBFILE})
        else
            echo "Can not open file: ${DBFILE}. Please absolute or relative path of an existing file."
            exit 1
        fi
    else
        DATABASES=$(mysql ${MYSQLPW} -Bse 'show databases')
    fi
    for DB in $DATABASES
    do
        if [[ "$DB" != "mysql" ]]; then
            echo -ne "Processing [$DB] ... "
            mysqldump ${MYSQLPW} ${MYSQLPM} ${DB} -r ${STOREIN}$DB.tmp
            sqlBackup $DB
        fi
    done
else
    if [ "${DBLIST}" != "" -a "$1" != "all" ]; then
        OPTIONS="--databases ${DBLIST}"
    elif [ "${DBFILE}" != "" -a "$1" != "all" ]; then
        if [ -s ${DBFILE} ]; then
            OPTIONS="--databases $(tr '\n' ' ' < ${DBFILE})"
        else
            echo "Can not open file: ${DBFILE}. Please absolute or relative path of an existing file."
            exit 1
        fi
    else
        OPTIONS="--all-databases"
    fi
    echo -ne "Processing [$1] ... "
    mysqldump ${MYSQLPW} ${MYSQLPM} ${OPTIONS} -r ${STOREIN}$1.tmp
    sqlBackup "all"
fi
if [ "$PREMOTE" != "" ]; then
    echo "Synchronizing... "
    CMD="rsync ${RSYNCPR} ${STOREIN} ${PREMOTE} > sqlbackup.log"
    eval $CMD
fi
