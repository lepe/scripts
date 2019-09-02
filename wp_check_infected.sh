#!/bin/bash
#
# Script to check for website malware
# https://security.stackexchange.com/questions/177116/
# Since. 2018-01-09
#
if [[ $1 == "--help" ]]; then
    echo "Usage: $0 [DIRECTORY]"
    echo "If DIRECTORY is not specified, will scan from current dir."
    echo
    echo "Note: This code won't alter any file in any way"
    echo
    echo "'DANGER' means that there is a high probability your site is infected."
    echo "'WARNING' means could be a false-positive as file names are common."
    echo
    echo "To be sure, check those files with a text editor (be sure to check files with wordwrap on)"
    echo " --- Do not use your browser if they are php files --- "
    echo "If you confirm your website is infected, restore from a clean backup in a container."
    echo "It will return (exit) 0 if nothing found, 1 if warnings found and 2 if danger was found"
    exit
fi
if [[ -d $1 ]]; then
    directory=$1
fi
declare -a red=("*.suspected" "favicon_*.ico" "p.txt" "evas.php" "vlomaw.zip" "tondjr.zip" "lerbim.php" "sotpie" "wtuds" "inl.php" "zrxd" "polwxpyh.php" "article.php" "admit.php" "ini_ui-elements.php" "sql.php" "pdo.inc.php")
declare -a yellow=("ui-elements.php" "uploader.php" "wp-update.php" "db_connector.php" "admin-menu.php" "wp-theme.php" "wp-category.php" "wp-search.php")

ret_code=0 # 0: clean, 1: warn, 2: danger

echo "Searching for strange files..."
for i in "${red[@]}"
do
    test=$(find "$directory" -name "$i")
    if [[ $test != "" ]]; then
        for f in $test; do
            echo "[ DANGER ] $f"
        done
        ret_code=2
    fi
done

echo "Searching for obfuscated includes..."
test=$(find "$directory" -name "*.php" -exec egrep -l "@include.*\\\x[0-9]" {} \;)
if [[ $test != "" ]]; then
    echo "[ DANGER ] $test"
    ret_code=2
fi

echo "Searching for obfuscated code..."
for f in $(find "$directory" -name "*.php" -exec grep -l "GLOBALS" {} \;); do
    test=$(egrep -l "(\\\x[0-9]+){5}" "$f")
    if [[ $test != "" ]]; then
        echo "[ DANGER ] $test"
        ret_code=2
    fi
done

echo "Searching for encoded code..."
for f in $(find "$directory" -name "*.php"); do
    test=$(cat $f | tr -d '\r' | tr -d '\n' | grep -v "\-----BEGIN" | egrep "[a-zA-Z0-9\/+]{1000}")
    if [[ $test != "" ]]; then
        echo "[ DANGER ] $f"
        ret_code=2
    fi
done

# Be sure there are no php in /upload/
echo "Searching for PHP files inside upload directory..."
for d in $(find "$directory" -type d -name "upload*"); do
    test=$(find "$d" -name "*.php")
    if [[ $test != "" ]]; then
        echo "[ DANGER ] $test"
        ret_code=2
    fi
done

echo "Searching for inline zip files ..."
test=$(find "$directory" -name "*.php" -exec egrep -l "gzinflate\(base64_decode" {} \;)
if [[ $test != "" ]]; then
    echo "[ DANGER ] $test"
    ret_code=2
fi

echo "Searching for Injected code ..."
test=$(find "$directory" -name "*.php" -exec egrep -l "user_agent_to_filter|#TurtleScanner#|liveupdates.host|\"file test okay\"" {} \;)
if [[ $test != "" ]]; then
    echo "[ DANGER ] $test"
    ret_code=2
fi

echo "Searching for possibly malicious files..."
for i in "${yellow[@]}"
do
    test=$(find "$directory" -name "$i")
    if [[ $test != "" ]]; then
        echo "[ WARNING ] $test"
        if [[ $ret_code == 0 ]]; then
            ret_code=1
        fi
    fi
done

exit $ret_code
