#!/bin/bash
function reset {
    INITIAL=`date +%s`;
    COUNTER=0;
}
reset;

while :
do
    #some process
    sleep 0.3 

    ((COUNTER++))
    CURRENT=`date +%s`;
    DIFF=$((CURRENT - INITIAL));
    if [[ $DIFF > 0 ]]; then
        echo -ne "${COUNTER} fps \033[0K\r"
        reset;
    fi
done
