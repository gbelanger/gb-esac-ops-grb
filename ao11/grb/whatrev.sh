#!/bin/bash

# Define file paths 
revnofile="revno"
action="GetRev.awk"


# Check args
if [ $# != 1 ]
then
    echo
    echo 'Usage: whatrev yyyy-mm-ddThh:mm:ss (UTC)'
    echo
    exit 0
fi

time=$1
revnumber=`awk -f $action time=$time $revnofile`
echo "Rev" $revnumber
exit 0
