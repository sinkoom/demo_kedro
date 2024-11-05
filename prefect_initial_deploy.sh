#!/bin/bash
# Check if environment name is provided
if [ -z "$1" ]; then
  echo "Please provide the environment name (e.g., sandbox, dev)."
  exit 1
fi

if [ -z "$2" ]; then
  echo "Please provide your github pat."
  exit 1
fi

poetry install

# Set the environment name
environment=$1
github_pat=$2

pip install git+https://github.com/EliLillyCo/LRL_light_k8s_infra_app_client_python.git

# Construct the config file name
config_file="config_${environment}.json"

# Check if the config file exists
if [ ! -f "$config_file" ]; then
  echo "Config file $config_file not found!"
  exit 1
fi

# Read the config file
config=$(cat "$config_file")

export PREFECT_API_KEY="$(light_auth)"
export PREFECT_API_URL=$(echo $config | jq -r '.prefect_api_url // ""')
export DEFAULT_AGENT_WORK_POOL_NAME=$(echo $config | jq -r '.work_pool_name // ""')

# Extract values from config file
name=$(git config --local remote.origin.url | sed -n 's#.*/\([^.]*\)\.git#\1#p' | tr '[:upper:]' '[:lower:]')
repository=`git config --get remote.origin.url`
branch=`git rev-parse --abbrev-ref HEAD`
deployment_name="${name}_${branch}"
namespace=$(echo $config | jq -r '.namespace // "bia-ds-sandbox-dev"')
prefect_version=$(echo $config | jq -r '.prefect_version // "3.0.3"')
version=$(echo $config | jq -r '.version // ""')
concurrency_limit=$(echo $config | jq -r '.concurrency_limit // ""')
description=$(echo $config | jq -r '.description // ""')
entrypoint=$(echo $config | jq -r '.entrypoint // "prefect_flow_file.py:prefect_new_flow_s3"')
parameters=$(echo $config | jq -r '.parameters // {} | tojson')
work_pool_name=$(echo $config | jq -r '.work_pool_name // "bia-ds-sandbox-worker"')
work_queue_name=$(echo $config | jq -r '.work_queue_name // ""')
job_variables=$(echo $config | jq -r '.job_variables // {} | tojson')
enforce_parameter_schema=$(echo $config | jq -r '.enforce_parameter_schema // true')
schedules=$(echo $config | jq -r '.schedules // [] | tojson')
secret_name=$(echo $deployment_name | sed 's/_/-/g')
credentials=$(echo "{{ prefect.blocks.github-credentials.$secret_name }}" | sed "s/'/''/g")
tags=$(echo '["'"$name"'", "'"$namespace"'", "'"$branch"'"]' | jq -r '.[] | "- " + .')
all_tags=$(echo '["'"$name"'", "'"$namespace"'", "'"$branch"'"]')

jq --arg project_repo "$name"  --arg project_short_name "$name" --arg repository "$repository" --arg branch "$branch" --arg deployment_name "$deployment_name" --argjson tags "$all_tags"   \
'. + {project_repo: $project_repo, project_short_name: $project_short_name, repository: $repository, branch: $branch, deployment_name: $deployment_name, tags:$tags }' $config_file > tmp.json && mv tmp.json $config_file

git add $config_file
git commit -m "updated config file for deployment"
git push --set-upstream origin $branch

# Execute the Python code to create a GitHub credentials block
python - <<END

from prefect_github import GitHubCredentials


github_credentials_block = GitHubCredentials(token="$github_pat")
github_credentials_block.save(name="$secret_name", overwrite=True)


END

echo "GitHub credentials $secret_name block has been created successfully."

# Generate the prefect.yaml file
cat <<EOL > prefect.yaml
name: $name
prefect-version: $prefect_version
build:
push:
pull:
- prefect.deployments.steps.git_clone:
    repository: $repository
    branch: $branch
    credentials: '$credentials'
deployments:
- name: $deployment_name
  version: $version
  tags:
$(echo "$tags" | sed 's/^/  /')
  concurrency_limit: $concurrency_limit
  description: $description
  entrypoint: $entrypoint
  parameters: $parameters
  work_pool:
    name: $work_pool_name
    work_queue_name: $work_queue_name
    job_variables: $job_variables
  enforce_parameter_schema: $enforce_parameter_schema
  schedules: $schedules
EOL

echo "prefect.yaml file has been generated successfully."

prefect deploy $entrypoint \
    -n $deployment_name \
    -p $DEFAULT_AGENT_WORK_POOL_NAME

# Update the pyproject.toml file with the project name
sed -i '' "s/name = \"prefect_default\"/name = \"$name\"/" pyproject.toml
