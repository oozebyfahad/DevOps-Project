#!/bin/bash

# Navigate to the project directory
cd "$(dirname "$0")/.."

# Build the Docker image
docker build -t jenkins-ci-webapp .

# Check if the build was successful
if [ $? -ne 0 ]; then
  echo "Docker build failed."
  exit 1
fi

echo "Docker image built successfully."