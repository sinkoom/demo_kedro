#!/bin/bash

export root_path=$(pwd)
export PGPASSWORD=$rs_pwd

source ./docker/utils.sh

# Assign positional argument passed to this shell script
pipeline=$1
brands=$2
filename=$3
parametersbu=$PARAMETERS_BU
if [[ "$parametersbu" == "parameters.yml" ]]; then
	 bu=""
else
	bu=$(echo "$parametersbu" | sed 's/.*_\([^.]*\)\..*/\1/')
fi

echo "BU value is $bu" >> "$mlops_logs"

if [ -n "$bu" ]; then
  job_pipeline="${pipeline}_${bu}"
else
  job_pipeline=${pipeline}
fi

mkdir -p $root_path/logs/$PARAMETERS_BU/$pipeline

pull_data_s3


#Logs before entering switch statement
echo "$(get_current_datetime) : Pipeline started : $pipeline" >> "$mlops_logs"
echo "Pipeline to run is : $pipeline" >> "$mlops_logs"
echo "-----------------------------------------------------------------------------------------------------" >> "$mlops_logs"
job_update \'$runName\' \'$JOB_NAME\' sysdate NULL \'In_Progress\' \'JOB_EXECUTION_STARTED\'
pipeline_update \'$HOSTNAME\' \'$job_pipeline\' sysdate NULL \'In_Progress\' \'PIPELINE_EXECUTION_IN_PROGRESS\'

case $pipeline in
	"case1")
			echo "inside case case1" >> "$mlops_logs"
			# Your Code goes here ...............
			;;


	"case2")
			echo "inside case case2" >> "$mlops_logs"
			# Your Code goes here ...............
			;;

	*)

	# Handle cases not explicitly defined
	echo "$(get_current_datetime) : Unknown key available in the arguments passed : $pipeline" >> "$mlops_logs"
	;;
esac

#Capture exit code after each switch case execution, so the same can be passed to nextflow
exit_code=$?

if grep -q "Error" "logs/log.txt"; then
	#Failure Condition
	echo "$(get_current_datetime) : Script encountered an error!!! and returned an exit code of : $exit_code" >> "$mlops_logs"
	subject="Execution - Failure"
	message="execution failed. Please see the attached log for details."

	cat "$error_logs" >> "$mlops_logs"

	#Pipeline progress to dashboard
	pipeline_update \'$HOSTNAME\' \'$job_pipeline\' NULL sysdate \'Failure\' \'PIPELINE_EXECUTION_FAILED\'
	job_update \'$runName\' \'$JOB_NAME\' NULL sysdate \'Failure\' \'JOB_EXECUTION_FAILED\'
	echo "$(get_current_datetime) : Job Failed" >> "$mlops_logs"
	push_data_s3
	push_logs_s3
	push_mlops_logs_s3
	send_email "$subject" "$message" "$EM_TO" "$mlops_logs"
	exit 1

elif [ $exit_code -eq 0 ]; then
	#Success Condition
	echo "$(get_current_datetime) : Pipeline Ended : $pipeline" >> "$mlops_logs"
	echo -e "#####################################################\n# Execution of pipeline completed successfully! #\n#####################################################" >> "$mlops_logs"
	subject="Execution - Success"
	message="Executed successfully."

	#Pipeline progress to dashboard
	pipeline_update \'$HOSTNAME\' \'$job_pipeline\' NULL sysdate \'Success\' \'PIPELINE_EXECUTION_SUCCEEDED\'
	push_data_s3
	push_logs_s3
	push_mlops_logs_s3
	send_email "$subject" "$message" "$EM_TO" "$mlops_logs"
	exit $exit_code

else
	#Failure Condition
	echo "$(get_current_datetime) : Script encountered an error!!! and returned an exit code of : $exit_code" >> "$mlops_logs"
	cat "$error_logs" >> "$mlops_logs"
	subject="Execution - Failure"
	message="Execution failed. Please see the attached log for details."

	#Pipeline progress to dashboard
	pipeline_update \'$HOSTNAME\' \'$job_pipeline\' NULL sysdate \'Failure\' \'PIPELINE_EXECUTION_FAILED\'
	job_update \'$runName\' \'$JOB_NAME\' NULL sysdate \'Failure\' \'JOB_EXECUTION_FAILED\'
	echo "$(get_current_datetime) : Job Failed" >> "$mlops_logs"
	push_data_s3
	push_logs_s3
	push_mlops_logs_s3
	send_email "$subject" "$message" "$EM_TO" "$mlops_logs"
	exit $exit_code
fi
