#!/bin/bash

# Check if environment name is provided
if [ -z "$1" ]; then
  echo "Please provide the environment name (e.g., sandbox, dev)."
  exit 1
fi

environment=$1

# Construct the config file name
config_file="config_${environment}.json"

config=$(cat "$config_file")

export PREFECT_API_KEY="$(light_auth)"
export PREFECT_API_URL=$(echo $config | jq -r '.prefect_api_url // ""')
export DEFAULT_AGENT_WORK_POOL_NAME=$(echo $config | jq -r '.work_pool_name // ""')
deployment_name=$(echo $config | jq -r '.deployment_name // "pm_mlops_conn_tst"')
entrypoint=$(echo $config | jq -r '.entrypoint // "prefect_flow_file.py:prefect_new_flow_s3"')

prefect deploy $entrypoint \
    -n $deployment_name \
    -p $DEFAULT_AGENT_WORK_POOL_NAME
