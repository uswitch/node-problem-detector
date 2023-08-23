#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

readonly fqdn_a_record="$1"



# We send a single attempt only, without retries and with 1s timeout.
# We expect to receive an IPv4 address for a given A record.
dig_cmd_out="$(dig -t A @172.20.0.11 +tries=1 +retry=0 +time=1 +short "${fqdn_a_record}" 2>&1 | head -n1)"
dig_cmd_return_code="$?"
dig_cmd_out_ipv4ish="$(echo "${dig_cmd_out}" | grep -E -o "^([0-9]{1,3}[\.]){3}[0-9]{1,3}$")"

case "${dig_cmd_return_code}" in
  0)
    # Reply from the server received
    if [ -n "${dig_cmd_out_ipv4ish}" ]
    then
        echo "Acceptable A-record value received: ${dig_cmd_out}"
        exit "${OK}"
    else
        echo "Unexpected A-record value received: ${dig_cmd_out}"
        exit "${NONOK}"
    fi
    ;;

  9)
    echo "No reply received"
    exit "${NONOK}"
    ;;

  *)
    echo "Unexpected return code of dig: ${dig_cmd_return_code}"
    exit "${UNKNOWN}"
    ;;
esac
