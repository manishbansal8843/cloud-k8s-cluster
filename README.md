# cloud-k8s-cluster
This repository contains automation scripts to spin up k8s cluster on bare metal cloud compute machines.

The aim of this project is to create scripts for all major cloud providers. However, as a starter, Only GCP is supported.

To read more about this project, one can check below article as well.

https://medium.com/@manishbansal8843/automated-multi-node-kubernetes-installation-on-bare-metal-cloud-vms-3948325e2868

# How to install a 3 node cluster on GCP

1. First go to GCP console and open a cloud shell.
2. If you are a free user, create a project for yourself or use an existing project. For paid users, this step is not required.
3. Clone this git repository in home directory.
`cd ~ && git clone https://github.com/manishbansal8843/cloud-k8s-cluster.git && cd cloud-k8s-cluster`
4. Execute install.sh script with following parameters.
`NUM_OF_NODES=3 GCP_PROJECT_NAME=kubeadm-init ./install.sh`
5. Thats it. This will install a 3 node cluster on GCP with kubectl configured on master node.

Below are the logs of the script for reference.
```
manishbansal8843@cloudshell:~/cloud-k8s-cluster (kubeadm-init)$ NUM_OF_NODES=2 GCP_PROJECT_NAME=kubeadm-init ./install.sh
=====================================Welcome to cloud k8s cluster installer=====================================
Usage: NUM_OF_NODES=3 CLOUD_PROVIDER=gcp GCP_PROJECT_NAME=project-name-value ./install.sh
Cloud provider name is missing. Will deploy it on GCP by default.
GCP_PROJECT_NAME value kubeadm-init will be used to create new k8s VM instances.
Checking if project kubeadm-init exists or not
kubeadm-init  kubeadm-init  859215342347
kubeadm-init exists. Will be using it to create k8s VMs.
Updated property [core/project].
Updated property [compute/zone].
billingAccountName: billingAccounts/0114E6-AEFA99-BAD7BA
billingEnabled: true
name: projects/kubeadm-init/billingInfo
projectId: kubeadm-init
Created [https://www.googleapis.com/compute/v1/projects/kubeadm-init/zones/us-east1-b/instances/master-node].
NAME         ZONE        MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP    STATUS
master-node  us-east1-b  n1-standard-2               10.142.0.19  34.74.174.212  RUNNING
Master node installation is in progress. Sleeping for 30 seconds...
Master node installation is in progress. Sleeping for 30 seconds...
Master node installation is in progress. Sleeping for 30 seconds...
Master node installation is in progress. Sleeping for 30 seconds...
Master node installation is in progress. Sleeping for 30 seconds...
Master node installed successfully!!
NAME          STATUS   ROLES    AGE   VERSION
master-node   Ready    master   44s   v1.17.3
Cluster token is wx5dqt.vp0v6txqoicbb6px
Cluster ca cert hash is 6577eb24d90cc174b896872b26fc4e044fa0b579781052b79ab06b252ebfc48d
K8s master node internal ip is 10.142.0.19
Created [https://www.googleapis.com/compute/v1/projects/kubeadm-init/zones/us-east1-b/instances/worker-node-0].
NAME           ZONE        MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP   STATUS
worker-node-0  us-east1-b  n1-standard-2               10.142.0.20  35.231.12.32  RUNNING
###All worker nodes installed successfully###
###Polling to check if all nodes are ready###
Number of ready nodes are: 1 which is less than total number of nodes : 2
Sleeping for 30 secs...
Number of ready nodes are: 1 which is less than total number of nodes : 2
Sleeping for 30 secs...
Number of ready nodes are: 1 which is less than total number of nodes : 2
Sleeping for 30 secs...
Number of ready nodes are: 1 which is less than total number of nodes : 2
Sleeping for 30 secs...
Number of ready nodes are: 1 which is less than total number of nodes : 2
Sleeping for 30 secs...
Number of ready nodes are: 2 which is equal to total number of nodes : 2
All nodes are up!
NAME            STATUS   ROLES    AGE     VERSION
master-node     Ready    master   4m19s   v1.17.3
worker-node-0   Ready    <none>   40s     v1.17.3
```
