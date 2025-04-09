#!/usr/bin/env bash

network=$1

# gcloud compute network-endpoint-groups delete my-neg

if [[ "x${network}" != "x" ]]; then
   echo "[$network]"
   gcloud compute network-endpoint-groups list \
      --filter "network:(${network})" --uri | xargs -I{} \
      sh -c 'gcloud compute network-endpoint-groups delete {} --quiet'
else
  echo "No REGION provided to delete NEGs"
fi