import os
import time
import uuid

from kubernetes import client, config
from prefect import flow, get_run_logger, runtime, task
from prefect.states import Failed

from catsinfrastructure import load_config, pod_spec_load

# Import all the env variables
PREFECT_API_URL = os.environ['PREFECT_API_URL']
DEFAULT_AGENT_WORK_POOL_NAME = os.environ['DEFAULT_AGENT_WORK_POOL_NAME']


def get_pod_name(infra_config, image_tag_dev, task_name):
    logger = get_run_logger()
    project_sn = infra_config["project_short_name"].replace('_', '-')
    task_name_tmp = (task_name).replace('_', '-')
    image_name = f"{infra_config['ecr']}/{infra_config['project_repo']}:{image_tag_dev}"
    logger.info(f"Image Name is: {image_name}")
    unique_id_short = str(uuid.uuid4().hex[:8])
    pod_name = f'{infra_config["pod_prefix"]}-{project_sn}-{task_name_tmp}-{unique_id_short}'
    return pod_name


def manage_pod(pod_spec, pod_name, infra_config):
    """
    common helper method to be used to create/manage pod based on the pod spec
    and infra config file
    """
    logger = get_run_logger()
    config.load_incluster_config()
    v1 = client.CoreV1Api()

    # Create the pod in the default namespace
    v1.create_namespaced_pod(namespace=infra_config['namespace'], body=pod_spec)

    pod_status_prev = ''
    prev_reason = ''
    cancel_job = False
    start_time = time.time()
    timeout = infra_config['timeout']
    time_out = False
    failed = False
    while True:
        pod_status_curr = v1.read_namespaced_pod(name=pod_name, namespace=infra_config['namespace'])
        if pod_status_curr.status.phase != pod_status_prev:
            if pod_status_curr.status.phase in ["Succeeded"]:
                logger.info(f"Pod {pod_name} status: {pod_status_curr.status.phase}")
                break
            elif pod_status_curr.status.phase in ["Failed"]:
                logger.info(f"Pod {pod_name} status: {pod_status_curr.status.phase}")
                failed = True
                break
            else:
                pod_status_prev = pod_status_curr.status.phase
                logger.info(f"Pod {pod_name} status: {pod_status_curr.status.phase}")

        # Check for waiting state in container statuses
        if pod_status_curr.status.phase in ["Pending"]:
            if pod_status_curr.status.container_statuses:
                for container_status in pod_status_curr.status.container_statuses:
                    curr_reason = container_status.state.waiting.reason
                    if container_status.state.waiting and (curr_reason != prev_reason):
                        logger.info(f"Container {container_status.name} is in {container_status.state.waiting.reason} state: {container_status.state.waiting.message}")
                        prev_reason = curr_reason

                    if container_status.state.waiting.reason == 'ErrImagePull':
                        logger.info(f"Image pull failed for container {container_status.name} . Please check the ECR image tag and pass the correct image tag")
                        cancel_job = True
                        break

            if (time.time() - start_time) > timeout:
                logger.info(f"Pod {pod_name} has been pending for too long . Cancelling the job.")
                cancel_job = True
                time_out = True

            if cancel_job:
                break

        time.sleep(5)

    if cancel_job:
        v1.delete_namespaced_pod(name=pod_name, namespace=infra_config['namespace'])
        if not time_out:
            msg = f"Pod {pod_name} deleted successfully as image pull failed"
        else:
            msg = f"Pod {pod_name} deleted successfully as the pod is pending for too long."
        logger.error(msg)
        raise ValueError(msg)

    if failed:
        pod_logs = v1.read_namespaced_pod_log(name=pod_name, namespace=infra_config['namespace'])
        logger.info(f"Pod {pod_name} logs:\n{pod_logs}")

        # Clean up the pod
        v1.delete_namespaced_pod(name=pod_name, namespace=infra_config['namespace'])
        logger.info(f"Pod {pod_name} deleted successfully")
        raise ValueError(f"Pod {pod_name} failed. Please check the logs for more details")

    # Retrieve the logs from the pod
    pod_logs = v1.read_namespaced_pod_log(name=pod_name, namespace=infra_config['namespace'])
    logger.info(f"Pod {pod_name} logs:\n{pod_logs}")

    # Clean up the pod
    v1.delete_namespaced_pod(name=pod_name, namespace=infra_config['namespace'])
    logger.info(f"Pod {pod_name} deleted successfully")
    return 1

# Define task


@task(task_run_name="{name}", persist_result=True, tags=[DEFAULT_AGENT_WORK_POOL_NAME])
def manage_task(name: str, image_tag_dev: str, infra_config: dict, args: str, compute_label: str, dependent_task='default'):
    logger = get_run_logger()
    try:
        config.load_incluster_config()
        logger.info("Kubernetes configuration loaded successfully")
    except Exception as e:
        logger.error(f"Error loading Kubernetes configuration: {e}")
        raise

    try:
        logger.info(f"My flow name is {runtime.flow_run.name}")
        logger.info(f"My task name is {runtime.task_run.name}")
        logger.info(f"My dependent_task name is {dependent_task}")
        pod_name = get_pod_name(infra_config, image_tag_dev, runtime.task_run.name)
        pod_spec = pod_spec_load(label=compute_label, image_tag_dev=image_tag_dev, config=infra_config, command=infra_config['command'], args=[args], pod_name=pod_name)

    except Exception as e:
        logger.error(f"Error creating pod: {e}")
        raise

    try:
        result = manage_pod(pod_spec,pod_name,infra_config)
    except ValueError as e:
        raise ValueError
    return 1  # dependent_task


# Define Flow
@flow(persist_result=True)
async def prefect_new_flow(image_tag_dev='latest', environment='sandbox', args="echo 'hi prefect'; sleep 10", compute_label='serverless', log_prints=True):
    try:
        infra_config = load_config(f"config_{environment}.json")
        image_tag_dev = f"{infra_config['branch']}-sha-{image_tag_dev}"
        featureout = manage_task(name="features", image_tag_dev=image_tag_dev, infra_config=infra_config, args=args, compute_label=compute_label)

        ##### Added Example for Different scenarios to be used based on requirement#######
        #### Scenario1########
        #### Running Sequential execution of a  dependent task#######
        # task1out = manage_task.submit(name="Task1", image_tag_dev=image_tag_dev, infra_config=infra_config, args=args, compute_label=compute_label)
        # task2out = manage_task(name="Task2", image_tag_dev=image_tag_dev, infra_config=infra_config, args=args, compute_label=compute_label,dependent_task=task1out,wait_for=[task1out])

        #### Scenario2########
        #### Running parallel execution of a independant task #######
        # taskout = [manage_task.submit(name="Task1", image_tag_dev=image_tag_dev, infra_config=infra_config, args="echo hi", compute_label=compute_label),
        #            manage_task.submit(name="Task2", image_tag_dev=image_tag_dev, infra_config=infra_config, args="echo hello", compute_label=compute_label),
        #            manage_task.submit(name="Task3", image_tag_dev=image_tag_dev, infra_config=infra_config, args="echo hi prefect", compute_label=compute_label),
        #            manage_task.submit(name="Task4", image_tag_dev=image_tag_dev, infra_config=infra_config, args="echo hello prefect", compute_label=compute_label),
        #            ]

        #### Scenario3########
        #### Running parallel execution of a task for different brand values #######
        # allbrands=["verzenio","jaypirca"]
        # taskout = [manage_task.submit(name=f"{brand}, image_tag_dev=image_tag_dev, infra_config=infra_config, args=args, compute_label=compute_label)
        #            for brand in all brands]

        # ####Scenario4########
        # ####Running parallel execution of a task followed by sequential parallel execution independantly #######
        # taskout = [manage_task.submit(name="Task1", image_tag_dev=image_tag_dev, infra_config=infra_config, args=args, compute_label=compute_label),
        #            manage_task.submit(name="Task2", image_tag_dev=image_tag_dev, infra_config=infra_config, args=args, compute_label=compute_label),
        #            manage_task.submit(name="Task3", image_tag_dev=image_tag_dev, infra_config=infra_config, args=args, compute_label=compute_label),
        #            manage_task.submit(name="Task4", image_tag_dev=image_tag_dev, infra_config=infra_config, args=args, compute_label=compute_label),
        #            ]
        # dependat_parallel_task=[]
        # while taskout :
        #     cnt=5 # as the "Task4 is already there so contining from 5 for task name"
        #     # Check feature extraction tasks
        #     for future in taskout[:]:
        #         if future.state.is_completed():
        #             result =  future.result()
        #             dependat_parallel_task.append(manage_task.submit(name=f"Task{cnt}", image_tag_dev=image_tag_dev, infra_config=infra_config,
        #                                                              args=args, compute_label=compute_label,dependent_task=result))
        #             taskout.remove(future)
        #         elif  future.state.is_failed():
        #             taskout.remove(future)
        #             logger.error(f"Task failed for {future}")
        #         cnt+=1
        #     await asyncio.sleep(0.1)

    except ValueError as e:
        return Failed(message=f"Flow failed")
    except Exception as e:
        logger = get_run_logger()
        logger.error(f"Unexpected error: {e}")
        return Failed(message=f"Flow failed due to unexpected error")

if __name__ == "__main__":
    prefect_new_flow.from_source(
        entrypoint=f"{os.path.basename(__file__)}:prefect_new_flow",
    ).deploy(
        parameters={"image_tag_dev": "latest", "environment": "sandbox", "args": "echo hi prefect; sleep 10", "compute_label": "serverless"},
        work_pool_name=DEFAULT_AGENT_WORK_POOL_NAME
    )
