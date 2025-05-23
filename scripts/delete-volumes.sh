#!/usr/bin/env bash

cluster_name=$0
region=$1

if [[ "x${cluster_name}" != "x" && "x${region}" != "x" ]]; then
  aws ec2 describe-volumes \
      --region ${region} \
      --filters Name=tag:KubernetesCluster,Values=${cluster_name} \
      --query "Volumes[*].{ID:VolumeId}" \
      --output text | tr "\t" "\n" | xargs -I{} \
      sh -c 'aws ec2 delete-volume --volume-id {} --region ${region}; echo "Volume {} deleted"'
else
  echo "No CLUSTER_NAME and/or REGION provided to delete Volumes"
fi