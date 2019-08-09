#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

CHECK_AGENT="$(curl -s --show-error --connect-timeout 1 http://169.254.169.254/latest/meta-data/instance-id/ 2>&1)"

case $CHECK_AGENT in
  request\ blocked*)
  # agent is intercepting requests to meta-data API
  echo "Agent is running"
  exit $OK
  ;;

  i-*)
  # request to meta-data API is not intercepted as instance ID is obtainable
  echo "Agent does not seem to be running"
  exit $NONOK
  ;;

  *)
  echo "Unexpected error: ${CHECK_AGENT}"
  exit $UNKNOWN
  ;;

esac
