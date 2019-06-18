#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

status_code=`curl --max-time 3 --silent --output /dev/stderr --write-out "%{http_code}" "http://169.254.169.254/latest/meta-data/spot/instance-action"`

if [ "${status_code}" -eq "404" ]
then
    exit $OK
elif [ "${status_code}" -eq "200" ]
then
    exit $NONOK
else
    exit $UNKNOWN
fi
