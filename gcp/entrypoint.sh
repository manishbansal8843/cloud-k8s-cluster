#gcloud components update
gcloud components install alpha
if [ -z $GCP_PROJECT_NAME ]
then
  echo "GCP_PROJECT_NAME is not passed as an argument. Hence, will create a new project subject to the project quota availability of the user."
  MY_PROJECT_ID=k8s-cluster-${NUM_OF_NODES}-nodes-$RANDOM
  gcloud projects create $MY_PROJECT_ID
  if [ $? -eq 1 ]; then
    echo "Issue occured during project creation. This is unexpected. Exiting abnormally!!"
    exit 1
  fi
else
  echo "GCP_PROJECT_NAME value $GCP_PROJECT_NAME will be used to create new k8s VM instances."
  MY_PROJECT_ID=${GCP_PROJECT_NAME}
  echo "Checking if project $GCP_PROJECT_NAME exists or not"
  gcloud projects list --filter="PROJECT_ID=$GCP_PROJECT_NAME" | grep $GCP_PROJECT_NAME
  if [ $? -eq 1 ]; then
    echo "$GCP_PROJECT_NAME project does not exist. This is unexpected. Exiting abnormally!!"
    exit 1
  fi
  echo "$GCP_PROJECT_NAME exists. Will be using it to create k8s VMs."
fi


gcloud config set project $MY_PROJECT_ID
gcloud config set compute/zone us-east1-b
export CLOUDSDK_COMPUTE_ZONE=us-east1-b
BILLING_ACCOUNT_ID=$(gcloud alpha billing accounts list | tail -1 | cut -d' ' -f 1)
gcloud alpha billing accounts projects link $MY_PROJECT_ID --account-id=$BILLING_ACCOUNT_ID
gcloud services enable compute.googleapis.com
gcloud compute instances create master-node \
    --image ubuntu-1604-xenial-v20200129 \
    --image-project ubuntu-os-cloud \
	--create-disk size=50,type=pd-standard \
	--machine-type n1-standard-2 \
    --metadata username=$(whoami) \
	--metadata-from-file startup-script=gcp/install-scripts/gcp-install-master.sh
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa_cloud_k8s_cluster 2>/dev/null <<< y >/dev/null
# SSH setup should have been done already on the cloud shell before executing scp
while ! gcloud compute scp --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --recurse master-node:~/.kube ~ 2>/dev/null
do
echo "Master node installation is in progress. Sleeping for 30 seconds..."
sleep 30
done
gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command="kubectl get nodes"
CLUSTER_TOKEN=$(gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command="kubeadm token create")
echo "Cluster token is $CLUSTER_TOKEN"
gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command="kubeadm token list"
CLUSTER_DISCOVERY_TOKEN_CA_CERT_HASH=$(gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command="openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* //'")
echo "Cluster ca cert hash is $CLUSTER_DISCOVERY_TOKEN_CA_CERT_HASH"
if [ $NUM_OF_NODES -gt 1 ]; then
WORKER_NODE=0
while [ $WORKER_NODE -lt $(($NUM_OF_NODES-1)) ]
do
gcloud compute instances create worker-node-$WORKER_NODE \
    --image ubuntu-1604-xenial-v20200129 \
    --image-project ubuntu-os-cloud \
	--create-disk size=50,type=pd-standard \
	--machine-type n1-standard-2 \
    --metadata username=$(whoami) \
    --metadata k8s-token=$CLUSTER_TOKEN \
    --metadata k8s-hash=$CLUSTER_DISCOVERY_TOKEN_CA_CERT_HASH \    
	--metadata-from-file startup-script=gcp/install-scripts/gcp-install-worker.sh
WORKER_NODE=$(($WORKER_NODE+1))
done
fi