<div align="center">
<b> BIA_DS_MLOPs Template Repository </b>

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](https://choosealicense.com/licenses/mit/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg?style=flat-square)](https://github.com/psf/black)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?style=flat-square&logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

[![macOS](https://img.shields.io/badge/MacOS-inactive?style=flat-square&logo=macos)]()

<a href="https://github.com/EliLillyCo/BIA_DS_MLOps/generate" alt="click this button to use the template"> DO NOT FORK/CLONE | Click here to use this template </a>

To get started with the template, click on the above link 👆 or "Use this template" button at the top right and create your project based on this template.

Check detailed documentation here: https://confluence link to be provided here
</div>

The following sections provide an overview of the directory structure and instructions for setting up your project workspace.

```

├── DESCRIPTION						<- 📛 File used to specificy packages to be used in R
├── catsinfrastructure.py				<- 📛 CATS Infra file for Prefect
├── conf						<- 📛 Catalog and Parameters.yml files
├── config_sandbox.json			    		<- 📛 Deafult json config file for prefect in CATS
├── data						<- 📂 Input, model, raw data structure
├── docker
    ├── config.env                  			<- 📛 Config values for dockerfile
    ├── run_python.sh               			<- 🔧 Wrapper script to run Python pipelines
    ├── run_r.sh                    			<- 🔧 Wrapper script to run R pipelines
    └── utils.sh	                		<- 🔧 Provides common functionalities such as logging, QS Dashboard psql etc
├── makefile						<- 📦️ For Initial Project Setup
├── poetry.lock						<- 📦️ lock file for poetry which would be used for MLOps productionization
├── prefect_flow_file.py				<- 📦️ Sample Prefect flow file to start
├── prefect_initial_deploy.sh				<- 📦️ Initial deployment script for prefect
├── prefect_redeploy.sh					<- 📦️ Redploymnet script for prefect
├── pyproject.toml					<- 📦️ File where packages to be used for project are mentioned
├── readme.md						<- 📝 Project readme
├── renv.lock						<- 📦️ lock file for R which would be used for MLOps productionization
├── send_email.R					<- 📦️ R email file used to send emails from CATS server
├── send_email.py					<- 📦️ Python email file used to send emails from CATS server
├── src
	├── python					<- 📂 Python pipelines written in Kedro
	└── r						<- 📂 R pipelines written using framebar
└── tests						<- 📂 Unit tests folder that can be levereged for testing the pipelines

```

## 🚀 Features

* 🤓 Simple and comprehensive directory structure for organizing your DS project which can be leveraged to deploy easily on a k8s cluster.

* 😎 Setup script provided for MacOS.  Check [Setup](#%EF%B8%8F-setup) section for more details.

* 🤗 Only requires native Python and Poetry package installed.

* 🤩 Uses [Poetry](https://pipenv.pypa.io/en/latest/#). Here are some of the advantages of using it:

    * **💪 Project Isolation:** Poetry automatically creates and manages virtual environments for your projects. You don’t have to manually activate or deactivate environments; Poetry handles this behind the scenes.

	* **🤌 Simplified Dependency Management:** Poetry removes the need for the requirements.txt file and replaces it with the pyproject.toml, which effectively tracks dependencies. Additionally, Poetry utilizes the poetry.lock to ensure consistent and reliable application builds with packages versions

	* **🤟 Cross-Platform Compatibility:** Poetry supports a wide range of operating systems, including Linux, macOS, and Windows.

    * **💪 Ease of Use :** Poetry combines both dependency management and project packaging into a single tool, so you don’t need to switch between pip, virtualenv, and setuptools. Commands like poetry add, poetry install, and poetry update streamline common tasks.

    * **🤌 Dependency Grouping :** Poetry allows you to easily separate dependencies into groups, such as production and development (using the [tool.poetry.dev-dependencies] section), which can help keep your environment clean and efficient.

    * **🤟 Better Locking and Dependency Resolution :** Poetry is known for its deterministic dependency resolution. It resolves dependency versions before installation, reducing issues like version conflicts.


## 🛠️ Setup

Project setup scripts have been provided separately for MacOS.


This project uses the following configurations:
- **Use R --> Framebar framework for development in R**: [true/false]
- **Use Python --> Kedro framework for development in Python**: [true/false]
- **Enable Experimentation --> No Framebar or Kedro, plain framework to experiment or test in CATS environment**: [true/false]
- **Use Pre-commit --> Enalbe framework that allows to manage and maintain pre-commit hooks**: [true/false]
- **Generate Dockerfile - Based on the above selected options**: [true/false]

## Setup

### Run `Makefile`

This script installs/updates homebrew, Poetry, jq.
Execute the script by running in the root directory:

```make```

**NOTE:** **Before proceeding with the Generate Dockerfile step in makefile, ensure to update the config.env file with the required version for different environment variables.**

You will be prompted to answer the following questions:

Use R --> Framebar framework for development in R [true/false]
Use Python --> Kedro framework for development in Python [true/false]
Enable Experimentation --> No Framebar or Kedro, plain framework to experiment or test in CATS environment [true/false]
Use Pre-commit --> Enalbe framework that allows to manage and maintain pre-commit hooks [true/false]
Generate Dockerfile - Based on the above selected options [true/false]
NOTE: If "Generate Dockerfile" is selected as "true" then you will get the following prompt :
Which stage would you like to build?
1. R or Both R & Python (No GPU) - For USE_R or USE_R & USE_PYTHON (choose R Base Image in config.env)
2. Python with GPU - For USE_PYTHON with GPU requirements (choose GPU Base Image in config.env)
3. Python without GPU - For USE_PYTHON without GPU requirements (choose Python Base Image in config.env)
4. Both R & Python with GPU - For USE_R & USE_PYTHON with GPU requirements (choose GPU Base Image in config.env)
Enter your choice (1, 2, 3, or 4):

Enter the choice (1, 2, 3, or 4) according to the project requirment.

After answering these questions, the Makefile will configure the project based on your inputs.

### config.env
The config.env file contains environment variables that are used to configure various aspects of the Base Image. Below is a description of each variable defined in the file:
1. **PLATFORM:** Specifies the target platform for the build. In this case, it is set to linux/amd64.
2. **PYTHON_VERSION_MAJOR:** Defines the major version of Python to be used. Here, it is set to 3.11(This version is used for poetry env as well)
3. **PYTHON_VERSION_MINOR:** Defines the minor version of Python to be used. Here, it is set to .6.
4. **R_VERSION:** Specifies the version of R to be used. In this case, it is set to 4.4.1.
5. **R_BASE_IMAGE:** Defines the base Docker image for R. Here, it is set to rocker/tidyverse:4.4.1, which includes the Tidyverse collection of R packages.
6. **GPU_BASE_IMAGE:** Specifies the base Docker image for GPU support. In this case, it is set to nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04, which includes CUDA and cuDNN libraries for GPU acceleration.
7. **PYTHON_BASE_IMAGE:** Defines the base Docker image for Python. Here, it is set to python:3.11.6.

These environment variables are used to ensure that the correct versions and configurations are applied consistently throughout the Base Docker Image.

#### CRUD Operations in pyproject.toml
This section provides guidelines on how to perform Create, Read, Update, and Delete (CRUD) operations in the pyproject.toml file, focusing on the argument keys present in the file.

**Note:** Do not modify anything in the Kedro section of the pyproject.toml file. This section is crucial for the Kedro configuration and should remain unchanged to ensure the project functions correctly.

    Create
    To add a new dependency or configuration, locate the appropriate section and add your entry. For example, to add a new dependency:
    [tool.poetry.dependencies]
    new-package = "^1.0.0"
    or
    Run poetry add <package name>

    Read
    To read the current configuration or dependencies, simply open the pyproject.toml file and review the sections. For example, to check the project name:
    [tool.poetry]
    name = "<Project name to be provided here>"

    Update
    To update an existing entry, locate the key you want to modify and change its value. For example, to update the project version:
    [tool.poetry]
    version = "0.2.0"

    Delete
    To remove an entry, locate the key you want to delete and remove the corresponding line. For example, to remove a dependency:
    [tool.poetry.dependencies]
    # Remove the following line to delete the dependency
    # pandas = "2.2.3"
    or
    Run poetry remove <package name>

#### CRUD Operations in DESCRIPTION
Similar CRUD operation can be performed for DESCRIPTION file as well which uses R packages.
Refer documentation for the same

#### Generating poetry.lock file
    To generate the poetry.lock file from the pyproject.toml file, follow these steps:
    1. Navigate to Your Project Directory: Open your terminal and navigate to the directory containing your pyproject.toml file:
    cd /path/to/your/project
    2. Generate the poetry.lock File: Run the following command to generate the poetry.lock file:
    poetry lock
    This command will read the dependencies specified in your pyproject.toml file and create a poetry.lock file with the exact versions of the dependencies to ensure reproducibility.

#### Generating renv.lock file
    To generate the renv.lock file from the DESCRIPTION file in an R project, follow these steps:
    1. Navigate to Your Project Directory: Open your terminal and navigate to the directory containing your DESCRIPTION file:
    cd /path/to/your/project
    2. Initialize renv: If you haven't already initialized renv in your project, you can do so by running the following command in your R console:
    renv::init()
    3. Generate the renv.lock File: Run the following command in your R console to generate the renv.lock file:
    renv::snapshot()
    This command will read the dependencies specified in your DESCRIPTION file and create an renv.lock file with the exact versions of the dependencies to ensure reproducibility.

##### Prefect Confluence
Prefect is a modern workflow orchestration tool designed to help you build, run, and monitor data pipelines at scale. It provides a flexible and user-friendly interface for defining and managing workflows, ensuring that tasks are executed reliably and efficiently. Prefect supports complex dependencies, retries, and logging, making it ideal for data engineering and machine learning workflows. It integrates seamlessly with various data tools and cloud platforms, offering robust scheduling and monitoring capabilities. To learn more about Prefect and its features, please follow the Confluence link.
<a href="https://lilly-confluence.atlassian.net/wiki/spaces/BDS/pages/1609400937/Prefect-+Pipeline+Orchestration" alt="Prefect-+Pipeline+Orchestration">Prefect- Pipeline Orchestration  </a>


##### Pre-Commit Confluence
Pre-commit is a framework for managing and maintaining multi-language pre-commit hooks. It helps ensure code quality by running checks before code is committed to a repository. These hooks can automatically format code, check for syntax errors, enforce coding standards, and run tests. Pre-commit supports a wide range of hooks and can be easily integrated into your development workflow. It is highly configurable and works with various version control systems. To learn more about pre-commit and its features, please follow the Confluence link.
<a href="https://lilly-confluence.atlassian.net/wiki/spaces/BDS/pages/1510408197/Ensuring+Code+Excellence+Automated+Pre-Commit+Checks+in+MLOps+Git+Repos" alt="Prefect-+Pipeline+Orchestration">Automated Pre-Commit Checks in MLOps Git Repos </a>


## 👥 Authors
- [@Mohit Agarwal]()
- [@Raghuram Venugopal]()
