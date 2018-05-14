# terraform-vsphere-kubespray

## Requirements

* Git
* Ansible >= v2.4
* Jinja >= 2.9
* Terraform
* Internet connection on the client machine to download Kubespray
* Internet connection on the Kubernetes nodes to download the Kubernetes binaries
* A Ubuntu 16.04 vSphere template. If linked clone is used, the template needs to have one and only one snapshot

## Usage

$ cd terraform-vsphere-kubespray

$ vim terraform.tfvars

$ terraform init

$ terraform plan

$ terraform apply

## Network plugins

* Flannel
* Weave
* Cilium

