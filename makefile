# Prompt user for input
USE_R := $(shell \
  while true; do \
    read -p "Use R --> Framebar framework for development in R (true/false)? " input; \
    if [ "$$input" = "true" ] || [ "$$input" = "false" ]; then \
      echo $$input; \
      break; \
    fi; \
  done \
)

USE_PYTHON := $(shell \
  while true; do \
    read -p "Use Python --> Kedro framework for development in Python (true/false)? " input; \
    if [ "$$input" = "true" ] || [ "$$input" = "false" ]; then \
      echo $$input; \
      break; \
    fi; \
  done \
)

EXPERIMENTATION := $(shell \
  while true; do \
    read -p "Enable Experimentation --> No Framebar or Kedro, plain framework to experiment or test in CATS environment (true/false)? " input; \
    if [ "$$input" = "true" ] || [ "$$input" = "false" ]; then \
      echo $$input; \
      break; \
    fi; \
  done \
)
USE_PRE_COMMIT := $(shell \
  while true; do \
    read -p "Use Pre-commit --> Enalbe framework that allows to manage and maintain pre-commit hooks (true/false)? " input; \
    if [ "$$input" = "true" ] || [ "$$input" = "false" ]; then \
      echo $$input; \
      break; \
    fi; \
  done \
)
GENERATE_DOCKERFILE := $(shell \
  while true; do \
    read -p "Generate Dockerfile - Based on the above selected options (true/false)? " input; \
    if [ "$$input" = "true" ] || [ "$$input" = "false" ]; then \
      echo $$input; \
      break; \
    fi; \
  done \
)


# Default target
all: setup

# Setup target
setup: project_setup clean_pre_commit clean_experimentation clean_r clean_python generate_dockerfile

# Define the error statement
error_statement = "Error: Invalid configuration. USE_R & USE_PYTHON cannot be true when EXPERIMENTATION is true."

check_conditions:
ifeq ($(EXPERIMENTATION), true)
    ifneq ($(USE_R), false)
        $(error $(error_statement))
    endif
    ifneq ($(USE_PYTHON), false)
        $(error $(error_statement))
    endif
else ifneq ($(EXPERIMENTATION), false)
    ifeq ($(USE_R), true)
        $(error $(error_statement))
    endif
    ifeq ($(USE_PYTHON), true)
        $(error $(error_statement))
    endif
endif


# Project setup
project_setup:
	echo "Starting Project Setup..."
	./project_setup.sh

# Clean pre-commit files if use_pre_commit is false
clean_pre_commit:
ifeq ($(USE_PRE_COMMIT), false)
	rm -f .pre-commit-config.yaml .github/workflows/precommit-pr-check.yaml .github/workflows/precommit-push-check.yaml
	echo "Deleted pre-commit files"
else
	brew install pre-commit
	pre-commit install
endif

# Clean experimentation folders if experimentation is true
clean_experimentation:
ifeq ($(EXPERIMENTATION), true)
	rm -rf src/r src/python
	echo "Deleted src/r and src/python folders"
endif

# Clean R folder if use_r is false
clean_r:
ifeq ($(USE_R), false)
	rm -rf src/r send_email.R
	echo "Deleted folder: src/r"
endif

# Clean Python folder if use_python is false
clean_python:
ifeq ($(USE_PYTHON), false)
	rm -rf src/python send_email.py
	echo "Deleted folder: src/python"
endif

# Generate Dockerfile if GENERATE_DOCKERFILE is true
generate_dockerfile:
ifeq ($(GENERATE_DOCKERFILE), true)
	echo "Generating Dockerfile..."
	./docker/generate_dockerfile.sh
endif
