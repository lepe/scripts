#!/bin/bash
USR=root
PRE=""

if [ "$1" = "" ]; then
    echo "Usage: table_dropper.sh table_name";
    exit;
fi
echo -n "Password:"
stty -echo; read PASS; stty echo;
DB=$1
echo "\nRemoving tables from $1 ...";
#--------------------------------------
TABLES=$(mysql -u${USR} -p${PASS} ${DB} -Bse "SHOW TABLES");
SQL="SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';"
for TABLE in $TABLES; do
    SQL="${SQL};DROP TABLE \`${TABLE}\`";
done;
SQL="${SQL};SET SQL_MODE=@OLD_SQL_MODE;SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;"
mysql -u${USR} -p${PASS} ${DB} -e "$SQL";

PASS="";
echo "Done.";
