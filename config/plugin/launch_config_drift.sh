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

instances="$(aws autoscaling describe-auto-scaling-instances --instance-ids "${instance_id}")"

if [ "$(echo "${instances}" | jq '.AutoScalingInstances | length')" -eq "0" ]
then
    exit $UNKNOWN
fi

instance="$(echo "${instances}" | jq '.AutoScalingInstances[0]')"
instance_launch_config="$(echo "${instance}" | jq -r .LaunchTemplate.LaunchTemplateName)"
instance_asg="$(echo "${instance}" | jq -r .AutoScalingGroupName)"

asgs="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${instance_asg})"

if [ "$(echo "${asgs}" | jq '.AutoScalingGroups | length')" -eq "0" ]
then
    exit $UNKNOWN
fi

asg_launch_config="$(echo "${asgs}" | jq -r '.AutoScalingGroups[0].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateName')"

if [ "${instance_launch_config}" = "${asg_launch_config}" ]
then
    exit $OK
else
    exit $NONOK
fi