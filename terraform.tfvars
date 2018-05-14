# vCenter connection
vsphere_vcenter = ""

vsphere_user = ""

vsphere_password = ""

vsphere_unverified_ssl = "true"

vsphere_datacenter = ""

vsphere_resource_pool = ""

vsphere_vcp_user = ""

vsphere_vcp_password = ""

vsphere_vcp_datastore = ""

# Kubernetes infrastructure
vm_user = ""

vm_password = ""

vm_folder = ""

vm_datastore = ""

vm_network = ""

vm_template = "terraform-template/ubuntu-16.04-terraform-template"

vm_linked_clone = "true"

k8s_kubespray_url = "https://github.com/kubernetes-incubator/kubespray.git"

k8s_kubespray_version = "2.5.0"

k8s_version = "1.10.2"

k8s_master_ips = {
  "0" = ""
  "1" = ""
  "2" = ""
}

k8s_worker_ips = {
  "0" = ""
  "1" = ""
  "2" = ""
}

k8s_haproxy_ip = ""

k8s_netmask = ""

k8s_gateway = ""

k8s_dns = ""

k8s_domain = ""

k8s_network_plugin = "weave"

k8s_weave_encryption_password = ""

k8s_master_cpu = "1"

k8s_master_ram = "2048"

k8s_worker_cpu = "1"

k8s_worker_ram = "2048"

k8s_haproxy_cpu = "1"

k8s_haproxy_ram = "1024"

k8s_node_prefix = "k8s-kubespray"
