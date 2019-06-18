#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

readonly local_dns_resolver_ip="$1"

# CHAOS class request for a TXT record "id.server." (typically used for
# identification of DNS software). We send a single attempt only, without
# retries and with 33s timeout - CoreDNS forward plugin internally defaults to
# 30s dial time and 2s read timeout - this way we ensure to leave enough time
# for CoreDNS forward plugin to respond with _something_.
dig_cmd_out="$(dig -c CH -t TXT @"${local_dns_resolver_ip}" +tries=1 +retry=0 +time=33 +norecurse +noall +noqr +comments id.server. 2>&1)"
dig_cmd_return_code="$?"
dig_cmd_response_status="$(echo "${dig_cmd_out}" | grep HEADER | sed -e 's/^.* status: \(\w\w*\).*$/\1/')"

case "${dig_cmd_return_code}" in
  0)
    # Reply from the server received
    case "${dig_cmd_response_status}" in
        NOERROR|NXDOMAIN|SERVFAIL)
            echo "Acceptable response status value received: ${dig_cmd_response_status}"
            exit "${OK}"
            ;;
        *)
            echo "Unexpected response status value received: ${dig_cmd_response_status}"
            exit "${NONOK}"
            ;;
    esac
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
