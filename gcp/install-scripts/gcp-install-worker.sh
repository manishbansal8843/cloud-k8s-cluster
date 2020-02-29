echo "This is worker node"

# Installing docker as per documentation given here
# https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Installing kubernetes worker node as per documentatiion.
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
sudo apt-get install -y iptables arptables ebtables
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm
sudo apt-mark hold kubelet kubeadm
echo "###########Installing k8s packages. Going to sleep for 60 sec.#############"
sleep 60

# Fetching token, master node Ip address and ca cert hash from VM metadata passed from installation script
K8S_TOKEN=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/k8s-token?alt=text" -H "Metadata-Flavor: Google")
K8S_HASH=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/k8s-hash?alt=text" -H "Metadata-Flavor: Google")
K8S_MASTER_NODE=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/k8s-master-node-ip?alt=text" -H "Metadata-Flavor: Google")
kubeadm join ${K8S_MASTER_NODE}:6443 --token $K8S_TOKEN \
    --discovery-token-ca-cert-hash sha256:$K8S_HASH
echo "#####Kubernetes worker node is initialized successfully######"
