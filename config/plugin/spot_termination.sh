#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

# Get instance ID from Kubernetes node providerID
if [ -z "${NODE_NAME}" ]; then
    exit $UNKNOWN
fi

provider_id="$(curl -s -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  "https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1/nodes/${NODE_NAME}" \
  2>/dev/null | jq -r '.spec.providerID')"

if [ -z "${provider_id}" ]; then
    exit $UNKNOWN
fi

# Extract instance ID from providerID (format: aws:///region/instance-id)
instance_id="$(echo "${provider_id}" | awk -F'/' '{print $NF}')"

if [ -z "${instance_id}" ]; then
    exit $UNKNOWN
fi

# Check for spot instance interruption via EC2 API
interruption_time=$(aws ec2 describe-instances --instance-ids "${instance_id}" \
  --query 'Reservations[0].Instances[0].DisruptionTime' \
  --output text 2>/dev/null)

if [ "${interruption_time}" = "None" ] || [ -z "${interruption_time}" ]; then
    exit $OK
else
    exit $NONOK
fi
