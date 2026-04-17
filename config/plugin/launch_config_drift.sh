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

instance_launch_template=$(curl --max-time 3 --silent --fail \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/tags/instance/aws:ec2launchtemplate:id")

instance_asg=$(curl --max-time 3 --silent --fail \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/tags/instance/aws:autoscaling:groupName")

if [ -z "${instance_asg}" ] || [ -z "${instance_launch_template}" ]; then
    exit $UNKNOWN
fi

# Get ASG's current launch template (still requires AWS API)
asgs="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "${instance_asg}" 2>/dev/null)"

if [ -z "${asgs}" ] || ! echo "${asgs}" | jq empty 2>/dev/null; then
    exit $UNKNOWN
fi

if [ "$(echo "${asgs}" | jq '.AutoScalingGroups | length')" -eq "0" ]; then
    exit $UNKNOWN
fi

asg_launch_template="$(echo "${asgs}" | jq -r '.AutoScalingGroups[0].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateId')"

if [ "${instance_launch_template}" = "${asg_launch_template}" ]; then
    exit $OK
else
    exit $NONOK
fi
