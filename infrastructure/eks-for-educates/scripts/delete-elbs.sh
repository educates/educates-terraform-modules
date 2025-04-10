#!/usr/bin/env bash

vpc_id=$0
region=$1

if [[ "x${vpc_id}" != "x" && "x${region}" != "x" ]]; then
   aws elb describe-load-balancers \
      --region ${region} \
      --query \"LoadBalancerDescriptions[?VPCId==\'${vpc_id}\']\|[].LoadBalancerName\" \
      --output text | tr "\t" "\n" | xargs -I{} \
      sh -c 'aws elb delete-load-balancer --load-balancer-name {} --region ${region}; echo "ELB {} deleted"'
else
  echo "No VPC and or REGION provided to delete ELBs"
fi