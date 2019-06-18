#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

seconds_acceptable=$1
seconds_up=$(cat /proc/uptime | cut -d' ' -f1)

if [ "$seconds_up" -lte "$seconds_acceptable" ]
then
    exit $OK
else
    exit $NONOK
fi
