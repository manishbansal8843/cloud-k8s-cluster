#!/bin/bash -e

echo "=====================================Welcome to cloud k8s cluster installer====================================="
echo "Usage: NUM_OF_NODES=3 CLOUD_PROVIDER=gcp GCP_PROJECT_NAME=project-name-value ./install.sh"

: ${NUM_OF_NODES:=3}
: ${CLOUD_PROVIDER:="gcp"}
WORKER_NODES=$(($NUM_OF_NODES - 1))

if [[ $NUM_OF_NODES -lt 1 ]]; then
	echo "NUM_OF_NODES cannot be less than 1"
	exit 1
elif ! [[ -f $CLOUD_PROVIDER/entrypoint.sh ]]; then
	echo "$CLOUD_PROVIDER cloud provider is not supported as of now. Kindly check documentation for supported cloud providers."
	exit 2
fi

echo "Going to install k8s cluster on $CLOUD_PROVIDER"
. $CLOUD_PROVIDER/entrypoint.sh
