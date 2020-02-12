gcloud components update
gcloud components install alpha
MY_PROJECT_ID=k8s-cluster-${NUM_OF_NODES}-nodes-$RANDOM
gcloud projects create $MY_PROJECT_ID
if [ $? -eq 1 ]; then
echo "Issue occured during project creation. This is unexpected. Exiting abnormally!!"
exit 1
fi
gcloud config set project $MY_PROJECT_ID
export CLOUDSDK_COMPUTE_ZONE=us-east1-b
BILLING_ACCOUNT_ID=$(gcloud alpha billing accounts list | tail -1 | cut -d' ' -f 1)
gcloud alpha billing accounts projects link $MY_PROJECT_ID --account-id=$BILLING_ACCOUNT_ID
gcloud services enable compute.googleapis.com
gcloud compute instances create master-node \
    --image ubuntu-1604-xenial-v20200129 \
    --image-project ubuntu-os-cloud \
	--create-disk size=50,type=pd-standard \
	--machine-type n1-standard-2 \
	--metadata-from-file startup-script=gcp/install-scripts/gcp-install-master.sh

if [ $NUM_OF_NODES -gt 1 ]; then
WORKER_NODE=0
while [ $WORKER_NODE -lt $(($NUM_OF_NODES-1)) ]
do
gcloud compute instances create worker-node-$WORKER_NODE \
    --image ubuntu-1604-xenial-v20200129 \
    --image-project ubuntu-os-cloud \
	--create-disk size=50,type=pd-standard \
	--machine-type n1-standard-2 \
	--metadata-from-file startup-script=gcp/install-scripts/gcp-install-worker.sh
WORKER_NODE=$(($WORKER_NODE+1))
done
fi
