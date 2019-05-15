#===============================================================================
# VMware vSphere configuration
#===============================================================================

# vCenter IP or FQDN #
vsphere_vcenter = ""

# vSphere username used to deploy the infrastructure #
vsphere_user = ""

# Skip the verification of the vCenter SSL certificate (true/false) #
vsphere_unverified_ssl = "true"

# vSphere datacenter name where the infrastructure will be deployed #
vsphere_datacenter = ""

# vSphere cluster name where the infrastructure will be deployed #
vsphere_drs_cluster = ""

# vSphere resource pool name that will be created to deploy the virtual machines #
vsphere_resource_pool = "kubernetes-kubespray"

# Enable anti-affinity between the Kubernetes master virtual machines. This feature require a vSphere enterprise plus license #
vsphere_enable_anti_affinity = "false"

# vSphere username used by the vSphere cloud provider #
vsphere_vcp_user = ""

# vSphere datastore name where the Kubernetes persistant volumes will be created #
vsphere_vcp_datastore = ""

#===============================================================================
# Global virtual machines parameters
#===============================================================================

# Username used to SSH to the virtual machines #
vm_user = ""

# The linux distribution used by the virtual machines (ubuntu/debian/centos/rhel) #
vm_distro = ""

# The prefix to add to the names of the virtual machines #
vm_name_prefix = "k8s-kubespray"

# The name of the vSphere virtual machine and template folder that will be created to store the virtual machines #
vm_folder = "kubernetes-kubespray"

# The datastore name used to store the files of the virtual machines #
vm_datastore = ""

# The vSphere network name used by the virtual machines #
vm_network = ""

# The netmask used to configure the network cards of the virtual machines (example: 24)#
vm_netmask = ""

# The network gateway used by the virtual machines #
vm_gateway = ""

# The DNS server used by the virtual machines #
vm_dns = ""

# The domain name used by the virtual machines #
vm_domain = ""

# The vSphere template the virtual machine are based on #
vm_template = ""

# Use linked clone (true/false)
vm_linked_clone = "false"

#===============================================================================
# Master node virtual machines parameters
#===============================================================================

# The number of vCPU allocated to the master virtual machines #
vm_master_cpu = "2"

# The amount of RAM allocated to the master virtual machines #
vm_master_ram = "2048"

# The IP addresses of the master virtual machines. You need to define 3 IPs for the masters #
vm_master_ips = {
  "0" = ""
  "1" = ""
  "2" = ""
}

#===============================================================================
# Worker node virtual machines parameters
#===============================================================================

# The number of vCPU allocated to the worker virtual machines #
vm_worker_cpu = "2"

# The amount of RAM allocated to the worker virtual machines #
vm_worker_ram = "2048"

# The IP addresses of the master virtual machines. You need to define 1 IP or more for the workers #
vm_worker_ips = {
  "0" = ""
  "1" = ""
  "2" = ""
}

#===============================================================================
# HAProxy load balancer virtual machine parameters
#===============================================================================

# The number of vCPU allocated to the load balancer virtual machine #
vm_haproxy_cpu = "1"

# The amount of RAM allocated to the load balancer virtual machine #
vm_haproxy_ram = "1024"

# The IP address of the load balancer floating VIP #
vm_haproxy_vip = ""

# The IP address of the load balancer virtual machine #
vm_haproxy_ips = {
  "0" = ""
  "1" = ""
}

#===============================================================================
# Redhat subscription parameters
#===============================================================================

# If you use RHEL 7 as a base distro, you need to specify your subscription account #
rh_subscription_server = "subscription.rhsm.redhat.com"
rh_unverified_ssl = "false"
rh_username = ""
rh_password = ""

#===============================================================================
# Kubernetes parameters
#===============================================================================

# The Git repository to clone Kubespray from #
k8s_kubespray_url = "https://github.com/kubernetes-sigs/kubespray.git"

# The version of Kubespray that will be used to deploy Kubernetes #
k8s_kubespray_version = "v2.10.0"

# The Kubernetes version that will be deployed #
k8s_version = "v1.14.1"

# The overlay network plugin used by the Kubernetes cluster #
k8s_network_plugin = "calico"

# If you use Weavenet as an overlay network, you need to specify an encryption password #
k8s_weave_encryption_password = ""

# The DNS service used by the Kubernetes cluster (coredns/kubedns) #
k8s_dns_mode = "coredns"
