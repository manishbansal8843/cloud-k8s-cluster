echo "This is master node"
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
sudo apt-get install -y iptables arptables ebtables
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
echo "###########Installing k8s packages. Going to sleep for 60 sec.#############"
sleep 60
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
echo "#####Kubernetes master node is initialized successfully######"
echo "###Current users. checking if home user exists or not###"
CURRENT_USER=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/username?alt=text" -H "Metadata-Flavor: Google")
CURRENT_USER_HOME_DIR=$(grep $CURRENT_USER /etc/passwd | cut -d ":" -f6)
echo "Going to setup kubectl on master node for user $CURRENT_USER inside directory $CURRENT_USER_HOME_DIR"
mkdir -p $CURRENT_USER_HOME_DIR/.kube
sudo cp -i /etc/kubernetes/admin.conf $CURRENT_USER_HOME_DIR/.kube/config
sudo chown $(id -u $CURRENT_USER):$(id -g $CURRENT_USER) $CURRENT_USER_HOME_DIR/.kube/config
echo "###Setting kubectl for root user###"
mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
cd ~
kubectl version
echo "Setting up flannel"
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
echo "K8s master node installation completed successfully!"
kubectl get pods -n kube-system