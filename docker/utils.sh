#!/bin/bash

# Script: utils.sh
# Reusable functions go in here for better readability and maintainability

# Get the current date and time
get_current_datetime() {
  date +'%Y%m%d%H%M%S'
}

## Create mlops_logs file and clear its contents it already exists
mkdir -p mlops_logs

mlops_logs="$root_path/mlops_logs/mlops_logs_$(date +'%Y%m%d%H%M%S').txt"
> "$mlops_logs"

# Function to pull the latest data from S3
function pull_data_s3() {
  aws s3 cp $S3_PATH/data/ $root_path/data --recursive --exclude "data/08_reporting/delivery/*"
}

# Function to push the updated data to S3
function push_data_s3() {
  aws s3 cp $root_path/data $S3_PATH/data/ --recursive
}

# Function to pull logs from S3
function pull_logs_s3() {
  aws s3 cp $S3_PATH/logs/ $root_path/logs  --recursive
}

# Function to push logs to S3
function push_logs_s3() {
  aws s3 cp $root_path/logs $S3_PATH/logs/ --recursive
}

# Function to push mlops logs to S3
function push_mlops_logs_s3() {
  aws s3 cp $root_path/mlops_logs $S3_PATH/mlops_logs/ --recursive
}

# Function to pull email folder from S3
function pull_email_s3() {
  aws s3 cp  $S3_PATH/email/ $root_path --recursive

}

# Function to push email folder to S3
function push_email_s3() {
  aws s3 cp $root_path/email.txt $S3_PATH/email/
}


# function to update job level logs
# Parameters:
#   $1 (string): job id
#   $2 (string): job name
#   $3 (sysdate): job_start_time
#   $4 (sysdate): job_end_time
#   $5 (string): status
#   $6 (string): comments
function job_update() {
    echo "CALL $DASHBOARD_SCHEMA.sp_bia_mlops_pipeline_job_log('$SOURCE_NAME', $1, $2, $3, $4, $5, $6);" >> "$mlops_logs"
    psql -h $host -p 5439 -d $db_name -U $rs_uid -c "CALL $DASHBOARD_SCHEMA.sp_bia_mlops_pipeline_job_log('$SOURCE_NAME', $1, $2, $3, $4, $5, $6);" &
    wait
}

# function to update pipeline level logs
#   $1 (string): pipeline name
#   $2 (sysdate): pipeline_start_time
#   $3 (sysdate): pipeline_end_time
#   $4 (string): status
#   $5 (string): comments
function pipeline_update() {
    echo "CALL $DASHBOARD_SCHEMA.sp_bia_mlops_pipeline_exec_log('$SOURCE_NAME', $1, $2, $3, $4, $5, $6);" >> "$mlops_logs"
    psql -h $host -p 5439 -d $db_name -U $rs_uid -c "CALL $DASHBOARD_SCHEMA.sp_bia_mlops_pipeline_exec_log('$SOURCE_NAME', $1, $2, $3, $4, $5, $6);" &
    wait
}

function send_email() {
  subject=$1
  message=$2

  if [ -n "$4" ]; then
    attachmentpath1=\"$4\"
    echo "$(get_current_datetime) : Mail Attachment path --> $attachmentpath1" >> "$mlops_logs"
  else
    attachmentpath1=NULL
  fi

  if [ -n "$5" ]; then
    attachmentpath2=\"$5\"
    echo "$(get_current_datetime) : Mail Attachment path --> $attachmentpath2" >> "$mlops_logs"
  else
    attachmentpath2=NULL
  fi

  cd ..

  echo "$message" > content.txt

  R -e "source('$root_path/send_email.R'); send_email(\"$EM_FROM\", \"$3\", \"$subject\", \"content.txt\", $attachmentpath1, $attachmentpath2)"
  cd $root_path
}

function generate_input_files_path() {

  ## Reading brands and generating lines for python execution in impact and impact_combination
  brands=$1
  filename=$2

  # Remove brackets and split the brands into an array
  brands="${brands:1:-1}"  # Remove brackets

  # Replace commas with newline characters
  brands=$(echo "$brands" | tr ',' '\n')

  # Read each line into an array
  items=()
  while read -r line; do
      items+=("$line")
  done <<< "$brands"

  # Generate lines
  lines=()
  for item in "${items[@]}"; do
      lines+=("data/08_reporting/parameters_${item}.yml/${filename} ")
  done

  # Join lines with backslash and newline
  formatted_lines=$(printf "%s\n" "${lines[@]}")

  # Print the formatted lines
  echo -e "$formatted_lines"
}
