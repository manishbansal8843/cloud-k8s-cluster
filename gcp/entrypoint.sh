# Checking if project name is given to create k8s VMs. If not given, a new project will be created.
# It is advisable to pass projectname as new projects will consume the limited projects quota.
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

# Setting compute zone, project id in the cloud shell
gcloud config set project $MY_PROJECT_ID
gcloud config set compute/zone us-east1-b
export CLOUDSDK_COMPUTE_ZONE=us-east1-b

# Enabling billing on the project to use compute services.
BILLING_ACCOUNT_ID=$(gcloud alpha billing accounts list | tail -1 | cut -d' ' -f 1)
gcloud beta billing projects link $MY_PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID

# Enabling compute services on the project to spawn new VMs
gcloud services enable compute.googleapis.com

# Instlling master node
gcloud compute instances create master-node \
    --image ubuntu-1604-xenial-v20200223 \
    --image-project ubuntu-os-cloud \
	--create-disk size=50,type=pd-standard \
	--machine-type n1-standard-2 \
    --metadata username=$(whoami) \
	--metadata-from-file startup-script=gcp/install-scripts/gcp-install-master.sh

# SSH setup should have been done already on the cloud shell before executing ssh or scp
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa_cloud_k8s_cluster 2>/dev/null <<< y >/dev/null

# Checking if master node installation is over
while ! gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command="[ -d ~/.kube ]" 2>/dev/null
do
echo "Master node installation is in progress. Sleeping for 30 seconds..."
sleep 30
done
echo "Master node installed successfully!!"
gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command="kubectl get nodes"

# Generating cluster token and ca cert hash from master node to be used by kubeadm on worker nodes
CLUSTER_TOKEN=$(gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command="kubeadm token create" 2>/dev/null)
echo "Cluster token is $CLUSTER_TOKEN"
CLUSTER_DISCOVERY_TOKEN_CA_CERT_HASH=$(gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command="openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* //'")
echo "Cluster ca cert hash is $CLUSTER_DISCOVERY_TOKEN_CA_CERT_HASH"

# Getting master node internal IP to be used by kubeadm to join worker nodes
K8S_MASTER_INTERNAL_IP=$(gcloud compute instances describe master-node \
  --format='get(networkInterfaces[0].networkIP)')
echo "K8s master node internal ip is $K8S_MASTER_INTERNAL_IP"

# Installing worker nodes
if [ $NUM_OF_NODES -gt 1 ]; then
WORKER_NODE=0
while [ $WORKER_NODE -lt $(($NUM_OF_NODES-1)) ]
do
gcloud compute instances create worker-node-$WORKER_NODE \
    --image ubuntu-1604-xenial-v20200223 \
    --image-project ubuntu-os-cloud \
	--create-disk size=50,type=pd-standard \
	--machine-type n1-standard-2 \
    --metadata username=$(whoami),k8s-token=$CLUSTER_TOKEN,k8s-hash=$CLUSTER_DISCOVERY_TOKEN_CA_CERT_HASH,k8s-master-node-ip=$K8S_MASTER_INTERNAL_IP \
    --metadata-from-file startup-script=gcp/install-scripts/gcp-install-worker.sh
WORKER_NODE=$(($WORKER_NODE+1))
done
fi
echo "###All worker nodes installed successfully###"

echo "###Polling to check if all nodes are ready###"
NUM_OF_READY_NODES=$(gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command=$'JSONPATH=\'{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}\'  && kubectl get nodes -o jsonpath="$JSONPATH" | grep -o "Ready=True" | wc -l')
while [ $NUM_OF_READY_NODES -lt $NUM_OF_NODES ]
do
echo "Number of ready nodes are: $NUM_OF_READY_NODES which is less than total number of nodes : $NUM_OF_NODES"
echo "Sleeping for 30 secs..."
sleep 30
NUM_OF_READY_NODES=$(gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command=$'JSONPATH=\'{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}\'  && kubectl get nodes -o jsonpath="$JSONPATH" | grep -o "Ready=True" | wc -l')
done
echo "Number of ready nodes are: $NUM_OF_READY_NODES which is equal to total number of nodes : $NUM_OF_NODES"
echo "All nodes are up!"
gcloud compute ssh master-node --ssh-key-file=~/.ssh/id_rsa_cloud_k8s_cluster --command="kubectl get nodes"
