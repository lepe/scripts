#!/bin/bash

# @since 2012-02-28
# This script will create a separate file for each database which will contains
# all the SQL to perform the convertion from the old to the new structures
if [ "$1" = "" ]; then
    echo "Use: $0 [FILENAME.sql.gz]";
    exit;
fi
echo "Splitting the file. May take some time... grab a coffee ;)"
zcat $1 | awk '/DROP TABLE /{i++}{print > "file-"i}'
for I in $(ls file-*); do
    echo "Processing [$I]...";
    TNAME=$(head -n1 $I | grep -o "\`.*\`" | sed 's/`//g');
    mv $I $TNAME.sql
    gzip $TNAME.sql
done;
echo "Done."
