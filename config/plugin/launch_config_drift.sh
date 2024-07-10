#!/bin/sh

OK=0
NONOK=1
UNKNOWN=2

export $(cat /run/metadata/coreos | xargs)

instance_id="${COREOS_EC2_INSTANCE_ID}"

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