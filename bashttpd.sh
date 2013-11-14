#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

echo "Starting up bashttpd..." >&2

source "$SCRIPTPATH/bashttpd.conf"

WEBSITES=`ls -1b $CONFIG_PATH`

for WEBSITE in $WEBSITES ; do
    if test -f "$CONFIG_PATH/$WEBSITE" ; then
		echo -n "Loading $WEBSITE..." >&2
		
		$SCRIPTPATH/worker.sh $WEBSITE "$SCRIPTPATH/bashttpd.conf"
		
		echo " done!" >&2
    fi
done