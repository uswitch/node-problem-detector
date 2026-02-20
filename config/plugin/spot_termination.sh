#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
  --max-time 3 --silent --fail 2>/dev/null)

status_code=$(curl --max-time 3 --silent --output /dev/stderr --write-out "%{http_code}" \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/spot/instance-action")

if [ "${status_code}" -eq "404" ]; then
    exit $OK
elif [ "${status_code}" -eq "200" ]; then
    exit $NONOK
else
    exit $UNKNOWN
fi
