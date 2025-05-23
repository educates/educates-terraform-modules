#!/usr/bin/env bash

cluster_name=$0
region=$1

REALLY_GONE=0

function get_log_group {
  aws logs describe-log-groups --log-group-name-prefix ${LOG_GROUP_NAME} --query 'length(logGroups)'
}

if [[ "x${cluster_name}" != "x" && "x${region}" != "x" ]]; then
  aws logs describe-log-groups \
      --region ${region} \
      --log-group-name-pattern=${cluster_name} \
      --query "logGroups[*].logGroupName" \
      --output text | tr "\t" "\n" | xargs -I{} \
      sh -c 'aws logs delete-log-group --log-group-name "{}" --region ${region}; echo "Log Group {} deleted"'
else
  echo "No CLUSTER_NAME and/or REGION provided to delete Log Groups"
fi

# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/920#issuecomment-645862992
# while [[ $REALLY_GONE -eq 0 ]]; do
#   while [[ $(get_log_group) -gt 0 ]]; do
#     echo "${LOG_GROUP_NAME} still exists, deleting it..."
#     aws logs delete-log-group --log-group-name ${LOG_GROUP_NAME}
#     sleep 5
#   done
#   echo "${LOG_GROUP_NAME} has been deleted. Waiting 300 seconds to validate it is not recreated..."
#   sleep 300
#   if [[ $(get_log_group) -eq 0 ]]; then
#     REALLY_GONE=1
#   fi
# done