# terraform-vsphere-kubespray

## Requirements

* Git
* Ansible >= v2.4
* Jinja >= 2.9
* Python netaddr
* Terraform
* Internet connection on the client machine to download Kubespray.
* Internet connection on the Kubernetes nodes to download the Kubernetes binaries.
* vSphere environment with a vCenter. An enterprise plus license is needed if you would like to configure anti-affinity between the Kubernetes master nodes.
* A Ubuntu 16.04 vSphere template. If linked clone is used, the template needs to have one and only one snapshot.
* A resource pool to place the Kubernetes virtual machines.

## Usage

All the steps to use this Terraform script are described in details here:
https://blog.inkubate.io/install-and-manage-automatically-a-kubernetes-cluster-on-vmware-vsphere-with-terraform-and-kubespray/

### Create a Kubernetes cluster

$ cd terraform-vsphere-kubespray

$ vim terraform.tfvars

$ terraform init

$ terraform plan

$ terraform apply

### Add a worker node

Add one or several worker nodes to the k8s_worker_ips list:

$ vim terraform.tfvars

Execute the terraform script to add the worker nodes:

$ terraform apply -var 'action=add\_worker'

### Delete a worker node

Remove one or several worker nodes to the k8s_worker_ips list:

$ vim terraform.tfvars

Execute the terraform script to remove the worker nodes:

$ terraform apply -var 'action=remove\_worker'

### Upgrade Kubernetes

Modify the k8s_version variable:

$ vim terraform.tfvars

Execute the terraform script to upgrade Kubernetes:

$ terraform apply -var 'action=upgrade'

## Network plugins

* Flannel
* Weave
* Cilium
