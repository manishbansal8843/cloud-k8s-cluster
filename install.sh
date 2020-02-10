#!/bin/bash
set -e
echo "=====================================Welcome to cloud k8s cluster installer====================================="
echo "Usage: ./install.sh NUM_OF_NODES=3 CLOUD_PROVIDER=gcp"
SUPPORTED_CLOUD_PROVIDERS=("gcp")
NUM_OF_NODES=3
DEFAULT_CLOUD_PROVIDER="gcp"
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            NUM_OF_NODES) NUM_OF_NODES=${VALUE} ;;
            CLOUD_PROVIDER) CLOUD_PROVIDER=${VALUE} ;;     
            *)   
    esac    


done

if [ $NUM_OF_NODES -lt 1]; then
echo "NUM_OF_NODES cannot be less than 1"
exit 1
fi

WORKER_NODES=$(($NUM_OF_NODES - 1))

if [ -z $CLOUD_PROVIDER ]
then
  CLOUD_PROVIDER=$DEFAULT_CLOUD_PROVIDER
  echo "Cloud provider name is missing. Will deploy it on GCP by default."
  . $CLOUD_PROVIDER/entrypoint.sh
  exit 0
else
  for i in "${SUPPORTED_CLOUD_PROVIDERS[@]}"
  do
    if [ "$i" -eq "$CLOUD_PROVIDER" ]; then
          echo "Going to install k8s cluster on $CLOUD_PROVIDER"
          . $CLOUD_PROVIDER/entrypoint.sh
          exit 0
	  fi
  done
  echo "$CLOUD_PROVIDER cloud provider is not supported as of now. Kindly check documentation for supported cloud providers."
  exit 1
fi
