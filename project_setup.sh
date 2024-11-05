#!/bin/bash

## Promt user to enter the brief project description
read -p "Enter a brief project description: " project_description

## Project Name Variable
project_name=$(git config --local remote.origin.url | sed -n 's#.*/\([^.]*\)\.git#\1#p' | tr '[:upper:]' '[:lower:]')

# Update the pyproject.toml file with the project name
sed -i '' "s/name = \"<Project name to be provided here>\"/name = \"$project_name\"/" pyproject.toml

# Update the pyproject.toml file with the description
sed -i '' "s/description = \"<Project description to be provided here>\"/description = \"$project_description\"/" pyproject.toml

# Update the DESCRIPTION file with the project name
sed -i '' "s/Package: \"<Project name to be provided here>\"/Package: \"$project_name\"/" DESCRIPTION

# Update the DESCRIPTION file with the project name
sed -i '' "s/Title: \"<Project name to be provided here>\"/Title: \"$project_name\"/" DESCRIPTION

# Update the DESCRIPTION file with the project description
sed -i '' "s/Description: \"<Project description to be provided here>\"/Description: \"$project_description\"/" DESCRIPTION

# Update Homebrew
echo "Updating Homebrew..."
brew update

# Load environment variables from docker/config.env
echo "Loading environment variables from docker/config.env..."
export $(grep -v '^#' docker/config.env | xargs)
 
# Installing python version from config.env
echo "Installing python to $PYTHON_VERSION_MAJOR..."
brew install python@$PYTHON_VERSION_MAJOR

# Install Poetry
echo "Installing Poetry..."
brew install poetry

# Verify Poetry installation
echo "Verifying Poetry installation..."
poetry --version

echo "Poetry installation completed."

# Set poetry to use the specified Python version
echo "Setting python env to $PYTHON_VERSION_MAJOR..."
poetry env use python$PYTHON_VERSION_MAJOR

# Run Poetry install
echo "Running Poetry install..."
poetry install

# Install JQ for JSON parsing
echo "Installing JQ..."
brew install jq

# Update the .gitattributes file by removing lines 4 to 6
echo "Updating .gitattributes file by removing lines 4 to 6..."
sed -i '' '4,6d' .gitattributes
