# terraform-vsphere-kubespray

## Requirements

* Git
* Ansible v2.6 or v2.7
* Jinja >= 2.9.6
* Python netaddr
* Terraform v0.12
* Internet connection on the client machine to download Kubespray.
* Internet connection on the Kubernetes nodes to download the Kubernetes binaries.
* vSphere environment with a vCenter. An enterprise plus license is needed if you would like to configure anti-affinity between the Kubernetes master nodes.
* A Linux vSphere template. If linked clone is used, the template needs to have one and only one snapshot(due to a current bug in the provider, the template also need to be just a power off VM and not an actual vSphere template).

## Tested Linux distribution

* Ubuntu LTS 16.04 (requirements: open-vm-tools package)
* Ubuntu LTS 18.04 (requirements: VMware tools)
* CentOS 7 (requirements: open-vm-tools package, perl package)
* Debian 9 (requirements: VMware tools, vSphere VM OS configuration set to "Ubuntu Linux (64-bit)", net-tools package)
* RHEL 7 (requirements: open-vm-tools package, perl package)

## Tested Kubernetes network plugins

|         |        RHEL 7      |       CentOS 7     |  Ubuntu LTS 18.04  |  Ubuntu LTS 16.04  |       Debian 9     |
|---------|:------------------:|:------------------:|:------------------:|:------------------:|:------------------:|
| Flannel | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Weave   | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Calico  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Cilium  |        :x:         |        :x:         | :heavy_check_mark: |        :x:         | :heavy_check_mark: |
| Canal   | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |

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

Modify the k8s_version and the k8s_kubespray_version variables:

$ vim terraform.tfvars

| Kubernetes version | Kubespray version |
|:------------------:|:-----------------:|
|      v1.15.3       |      v2.11.0      |
|      v1.14.3       |      v2.10.3      |
|      v1.14.1       |      v2.10.0      |
|      v1.13.5       |      v2.9.0       |
|      v1.12.5       |      v2.8.2       |
|      v1.12.4       |      v2.8.1       |
|      v1.12.3       |      v2.8.0       |

Execute the terraform script to upgrade Kubernetes:

$ terraform apply -var 'action=upgrade'
