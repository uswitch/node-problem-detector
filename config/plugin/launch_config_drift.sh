#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

# Get IMDSv2 token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
  --max-time 3 --silent --fail 2>/dev/null)

if [ -z "${TOKEN}" ]; then
    exit $UNKNOWN
fi

# Get instance ID and launch template from IMDS
instance_id=$(curl --max-time 3 --silent --fail \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/instance-id")

if [ -z "${instance_id}" ]; then
    exit $UNKNOWN
fi

INSTANCE_CACHE="/tmp/npd_asg_instance_cache"

if [ -f "$INSTANCE_CACHE" ]; then
    instances="$(cat "$INSTANCE_CACHE")"
else
    instances="$(aws autoscaling describe-auto-scaling-instances --instance-ids "${instance_id}" 2>&1)"
    if [ $? -ne 0 ]; then
        echo "describe-auto-scaling-instances: ${instances}" >&2
        exit $UNKNOWN
    fi
    echo "${instances}" > "$INSTANCE_CACHE"
fi

if [ "$(echo "${instances}" | jq '.AutoScalingInstances | length')" -eq "0" ]; then
    exit $UNKNOWN
fi

instance="$(echo "${instances}" | jq '.AutoScalingInstances[0]')"
instance_launch_template_id="$(echo "${instance}" | jq -r .LaunchTemplate.LaunchTemplateId)"
instance_launch_template_version="$(echo "${instance}" | jq -r .LaunchTemplate.Version)"
instance_asg="$(echo "${instance}" | jq -r .AutoScalingGroupName)"

# Get ASG's current launch template (still requires AWS API)
asgs="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "${instance_asg}" 2>&1)"
if [ $? -ne 0 ]; then
    echo "describe-auto-scaling-groups: ${asgs}" >&2
    exit $UNKNOWN
fi

if [ "$(echo "${asgs}" | jq '.AutoScalingGroups | length')" -eq "0" ]; then
    exit $UNKNOWN
fi

asg="$(echo "${asgs}" | jq '.AutoScalingGroups[0].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification')"
asg_launch_template_id="$(echo "${asg}" | jq -r '.LaunchTemplateId')"
asg_launch_template_version="$(echo "${asg}" | jq -r '.Version')"

if [ "${instance_launch_template_id}" = "${asg_launch_template_id}" ] && [ "${instance_launch_template_version}" = "${asg_launch_template_version}" ]; then
    exit $OK
else
    exit $NONOK
fi
