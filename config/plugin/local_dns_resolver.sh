#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

if [ -z "${NODE_NAME}" ]; then
    exit $UNKNOWN
fi

# Get the node-local-dns pod IP running on this node directly,
# bypassing 169.254.20.10 which requires Cilium's eBPF path
local_dns_resolver_ip="$(curl -s \
    -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    "https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1/namespaces/kube-system/pods?labelSelector=k8s-app%3Dnode-local-dns&fieldSelector=spec.nodeName%3D${NODE_NAME}" \
    2>/dev/null | jq -r '.items[0].status.podIP')"

if [ -z "${local_dns_resolver_ip}" ] || [ "${local_dns_resolver_ip}" = "null" ]; then
    exit $UNKNOWN
fi

dig_cmd_out="$(dig -t TXT @"${local_dns_resolver_ip}" +tries=1 +retry=0 +time=33 +noqr +noall +comments kubernetes.default.svc. 2>&1)"
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

  10)
    echo "Dig internal error, response status: ${dig_cmd_response_status}"
    exit "${NONOK}"
    ;;

  *)
    echo "Unexpected return code of dig: ${dig_cmd_return_code}"
    exit "${UNKNOWN}"
    ;;
esac
