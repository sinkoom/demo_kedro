import json

from kubernetes import client


# Load environment variables from config file (dev or prod)
def load_config(env_file):
    with open(env_file, 'r') as f:
        config = json.load(f)
    return config

# define infrastructure block


def pod_spec_load(label, image_tag_dev, config, command, args, pod_name):

    if label == 'serverless':
        pod_spec = client.V1Pod(
            api_version=config['manifest_api_version'],
            kind=config['resource_type'],
            metadata=client.V1ObjectMeta(name=pod_name,
                                         labels=config['serverless_lables']),
            spec=client.V1PodSpec(
                containers=[
                    client.V1Container(
                        name=config['container_name'],
                        image=f"{config['ecr']}/{config['project_repo']}:{image_tag_dev}",
                        command=command,
                        args=args,
                        resources=client.V1ResourceRequirements(
                            requests=config['serverless_base_request'],
                            limits=config['serverless_base_limits']
                        ),
                        env=[client.V1EnvVar(name=item['key'], value=item['value']) for item in config['pod_env_vars']
                             ] +
                            [client.V1EnvVar(name=key,
                                             value_from=client.V1EnvVarSource(
                                                 secret_key_ref=client.V1SecretKeySelector(
                                                     name=value['name'],
                                                     key=value['key']
                                                 )
                                             )
                                             )
                                for key, value in config["cwbdb_creds"].items()
                             ] +
                        [client.V1EnvVar(name=key,
                                         value_from=client.V1EnvVarSource(
                                             secret_key_ref=client.V1SecretKeySelector(
                                                 name=value['name'],
                                                 key=value['key']
                                             )
                                         )
                                         )
                                for key, value in config["biadb_creds"].items()
                         ]
                    )
                ],
                service_account_name=config['service_account_name'],
                restart_policy=config['restart_policy'])
        )

    elif label == 'cpu':
        pod_spec = client.V1Pod(
            api_version=config['manifest_api_version'],
            kind=config['resource_type'],
            metadata=client.V1ObjectMeta(name=pod_name),
            spec=client.V1PodSpec(
                containers=[
                    client.V1Container(
                        name=config['container_name'],
                        image=f"{config['ecr']}/{config['project_repo']}:{image_tag_dev}",
                        command=command,
                        args=args,
                        resources=client.V1ResourceRequirements(
                            requests=config['cpu_base_request'],
                            limits=config['cpu_base_limits']
                        ),
                        env=[client.V1EnvVar(name=item['key'], value=item['value']) for item in config['pod_env_vars']
                             ] +
                            [client.V1EnvVar(name=key,
                                             value_from=client.V1EnvVarSource(
                                                 secret_key_ref=client.V1SecretKeySelector(
                                                     name=value['name'],
                                                     key=value['key']
                                                 )
                                             )
                                             )
                                for key, value in config["cwbdb_creds"].items()
                             ] +
                        [client.V1EnvVar(name=key,
                                         value_from=client.V1EnvVarSource(
                                             secret_key_ref=client.V1SecretKeySelector(
                                                 name=value['name'],
                                                 key=value['key']
                                             )
                                         )
                                         )
                                for key, value in config["biadb_creds"].items()
                         ]
                    )
                ],
                service_account_name=config['service_account_name'],
                restart_policy=config['restart_policy'],
                node_selector=config['node_selector'],
                tolerations=[client.V1Toleration(key=item['key'], value=item['value'], effect=item['effect'])
                             for item in config['cpu_toleration']]
            ),
        )

    elif label == 'gpu':
        pod_spec = client.V1Pod(
            api_version=config['manifest_api_version'],
            kind=config['resource_type'],
            metadata=client.V1ObjectMeta(name=pod_name),
            spec=client.V1PodSpec(
                containers=[
                    client.V1Container(
                        name=config['container_name'],
                        image=f"{config['ecr']}/{config['project_repo']}:{image_tag_dev}",
                        command=command,
                        args=args,
                        resources=client.V1ResourceRequirements(
                            requests=config['gpu_base_request'],
                            limits=config['gpu_base_limits']
                        ),
                        env=[client.V1EnvVar(name=item['key'], value=item['value']) for item in config['pod_env_vars']
                             ] +
                            [client.V1EnvVar(name=key,
                                             value_from=client.V1EnvVarSource(
                                                 secret_key_ref=client.V1SecretKeySelector(
                                                     name=value['name'],
                                                     key=value['key']
                                                 )
                                             )
                                             )
                                for key, value in config["cwbdb_creds"].items()
                             ] +
                        [client.V1EnvVar(name=key,
                                         value_from=client.V1EnvVarSource(
                                             secret_key_ref=client.V1SecretKeySelector(
                                                 name=value['name'],
                                                 key=value['key']
                                             )
                                         )
                                         )
                                for key, value in config["biadb_creds"].items()
                         ]
                    )
                ],
                service_account_name=config['service_account_name'],
                restart_policy=config['restart_policy'],
                node_selector=config['node_selector'],
                tolerations=[client.V1Toleration(key=item['key'], value=item['value'], effect=item['effect'])
                             for item in config['gpu_toleration']]
            ),
        )
    return pod_spec
