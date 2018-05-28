# terraform-vsphere-kubespray

## Requirements

* Git
* Ansible >= v2.4
* Jinja >= 2.9
* Python netaddr
* Terraform
* Internet connection on the client machine to download Kubespray
* Internet connection on the Kubernetes nodes to download the Kubernetes binaries
* A Ubuntu 16.04 vSphere template. If linked clone is used, the template needs to have one and only one snapshot

## Usage

### Create a Kubernetes cluster

$ cd terraform-vsphere-kubespray

$ vim terraform.tfvars

$ terraform init

$ terraform plan

$ terraform apply

### Add a worker node

$ terraform apply -var "action=add\_worker"

### Delete a worker node

$ terraform apply -var "action=remove\_worker" -var 'worker=["ip1", "ip2"]'

### Upgrade Kubernetes

$ terraform apply -var "action=upgrade"

## Network plugins

* Flannel
* Weave
* Cilium
