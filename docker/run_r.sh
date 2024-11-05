#!/bin/bash Rscript

touch $HOME/.Renviron

export root_path=$(pwd)
echo $root_path

source ./docker/utils.sh

echo "rs_uid=$rs_uid" >> $HOME/.Renviron
echo "rs_pwd=$rs_pwd" >> $HOME/.Renviron
echo "host=$host" >> $HOME/.Renviron
echo "db_name=$db_name" >> $HOME/.Renviron

export PGPASSWORD=$rs_pwd

# Initialize an empty array args
args=()

# Assign all positional parameters arguments passed to this shell script to this array
args=("$@")

echo "Number of arguments are : $#"

echo " Arguements are : $@"

pipeline_failure_flag=0
pipeline=$1
brand="$3"
brand_parameter="$2"

parametersbu=$PARAMETERS_BU
if [[ "$parametersbu" == "parameters.yml" ]]; then
	 bu=""
else
	bu=$(echo "$parametersbu" | sed 's/.*_\([^.]*\)\..*/\1/')
fi
echo "BU value is $bu" >> "$mlops_logs"

if [[ -n "$brand" && -n "$bu" ]]; then
  job_pipeline="${pipeline}_${brand}_${bu}"
elif [ -n "$bu" ]; then
  job_pipeline="${pipeline}_${bu}"
else
  job_pipeline=${pipeline}
fi
########################################################## Configure whether to send email or not ##############################################################################

# Check if mail has to be sent out after pipelines execution
send_email_flag="false"

function send_controlled_email() {
  # Send email to required recipients as in the arguments key passed
  if [ "$send_email_flag" = "true" ]; then
    if [ "$pipeline" == "email_internal" ]; then
      echo "$(get_current_datetime) : Sending email under case : $pipeline" >> "$mlops_logs"
      sender="$EM_INTERNAL"
      subject=$(head -n 1 "$root_path/email_internal.txt")
      message="<html>
                <head>
                <title>${subject}</title>
                </head>
                <body>
                $(tail -n +2 "$root_path/email_internal.txt")
                </body>
                </html>"
      zip -r $root_path/logs.zipREMOVE $root_path/logs
      send_email "$subject" "$message" "${sender}" "$root_path/data/08_reporting/po_summary_view.png" "$root_path/logs.zipREMOVE"
    else
      echo "$(get_current_datetime) : Sending email under case : $pipeline" >> "$mlops_logs"
      sender="$EM_EXTERNAL"
      subject=$(head -n 1 "$root_path/data/11_delivery/$schema/email.txt")
      message="<html>
                <head>
                <title>${subject}</title>
                </head>
                <body>
                $(tail -n +2 "$root_path/data/11_delivery/$schema/email.txt")
                </body>
                </html>"
      send_email "$subject" "$message" "${sender}"
    fi
  else
    # Handle cases not explicitly defined
    echo "$(get_current_datetime) : Unknown key available in the arguments passed : $pipeline" >> "$mlops_logs"

  fi

}

########################################################## Pipeline Execution Funciton ##############################################################################
# Generic function to run the pipelines in iterative manner based on the params passed while calling this shell script

function run_pipeline() {
#Pull data from S3 before proceeding with execution of pipelines
  pull_data_s3
  pull_logs_s3
  echo "$(get_current_datetime) : Arguments are not empty. The brand passed is: $brand" >> "$mlops_logs"
  echo "Pipeline to run is : $pipeline"
  echo "With brand : $brand"
  echo "Brand Parameter to pass : $brand_parameter"
  echo "Job Pipeline is: $job_pipeline"
  echo "-----------------------------------------------------------------------------------------------------"

  #Constructing the key dynamically to access value at any nested level
  echo "$(get_current_datetime) : Pipeline to run is : $pipeline" >> "$mlops_logs"
  echo "$(get_current_datetime) : With Brand : $brand" >> "$mlops_logs"

  r_expr="framebar::run(\"$pipeline\", \"$brand_parameter\")"
  echo "$(get_current_datetime) : Executing command : $r_expr" >> "$mlops_logs"
  mkdir -p $root_path/logs/$brand_parameter/$pipeline
  echo "$(get_current_datetime) : Pipeline started : $pipeline" >> "$mlops_logs"


  # Pipeline progress to dashboard
  pipeline_update \'$HOSTNAME\' \'$job_pipeline\' sysdate NULL \'In_Progress\' \'PIPELINE_EXECUTION_IN_PROGRESS\'

  output_error_logs="$root_path/logs/$brand_parameter/$pipeline.txt"
  > "$output_error_logs"

  timeout=500 R -e "$r_expr" > "$output_error_logs" 2>&1

  # Check the return code of previous command execution status.
  if [ $? -eq 0 ]; then
    echo "$(get_current_datetime) : Pipeline Ended : $pipeline" >> "$mlops_logs"
    echo -e "#####################################################\n# Execution of $pipeline pipeline completed successfully! #\n#####################################################" >> "$mlops_logs"
    pipeline_failure_flag=1
    subject="$job_pipeline Execution - Success"
    message="$job_pipeline executed successfully."
    #Pipeline progress to dashboard
    pipeline_update \'$HOSTNAME\' \'$job_pipeline\' NULL sysdate \'Success\' \'PIPELINE_EXECUTION_SUCCEEDED\'
    echo "$(get_current_datetime) : Job Succeeded" >> "$mlops_logs"
    push_data_s3
    push_logs_s3
    push_mlops_logs_s3
    push_email_s3
    send_email "$subject" "$message" "$EM_TO" "$mlops_logs"
    exit 0
  else
    echo "$(get_current_datetime) : Script encountered an error!!! and returned an exit code of : $?" >> "$mlops_logs"
    cat "$output_error_logs" >> "$mlops_logs"
    subject="$job_pipeline $pipeline Execution - Failure"
    message="$job_pipeline $pipeline execution failed. Please see the attached log for details."
    pipeline_failure_flag=0
    #Pipeline progress to dashboard
    pipeline_update \'$HOSTNAME\' \'$job_pipeline\' NULL sysdate \'Failure\' \'PIPELINE_EXECUTION_FAILED\'
    job_update \'$runName\' \'$JOB_NAME\' NULL sysdate \'Failure\' \'JOB_EXECUTION_FAILED\'
    echo "$(get_current_datetime) : Job Failed" >> "$mlops_logs"
    push_data_s3
    push_logs_s3
    push_mlops_logs_s3
    push_email_s3
    send_email "$subject" "$message" "$EM_TO" "$mlops_logs"
    exit 1
  fi

}
########################################################## End of Pipeline Execution Funciton ##############################################################################

########################################################## Funciton Calls ##################################################################################################

# Execute job update function
echo "$(get_current_datetime) : Job Started" >> "$mlops_logs"
job_update \'$runName\' \'$JOB_NAME\' sysdate NULL \'In_Progress\' \'JOB_EXECUTION_STARTED\'

# check if email key is passed in email_args and send mail
if [ "$pipeline" == "email_internal" ] || [ "$pipeline" == "email_external" ]; then
  send_email_flag="true"
  pull_email_s3
  pull_data_s3
  pull_logs_s3
  echo "$(get_current_datetime) : Send email flag is --> \"$send_email_flag\" , controlled email would be sent if the send_email_flag is true" >> "$mlops_logs"
  pipeline_update \'$HOSTNAME\' \'$job_pipeline\' sysdate NULL \'In_Progress\' \'PIPELINE_EXECUTION_IN_PROGRESS\'
  send_controlled_email
  pipeline_update \'$HOSTNAME\' \'$job_pipeline\' NULL sysdate \'Success\' \'PIPELINE_EXECUTION_SUCCEEDED\'
  echo "$(get_current_datetime) : Job Completed" >> "$mlops_logs"
else
  run_pipeline $@
fi


########################################################## End of Funciton Calls ###########################################################################################
