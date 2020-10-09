#===============================================================================
# vSphere Provider
#===============================================================================

provider "vsphere" {
  version              = "1.11.0"
  vsphere_server       = "${var.vsphere_vcenter}"
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"
  allow_unverified_ssl = "${var.vsphere_unverified_ssl}"
}

#===============================================================================
# vSphere Data
#===============================================================================

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "${var.vsphere_drs_cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.vm_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.vm_network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vm_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

#===============================================================================
# Template files
#===============================================================================

# Kubespray all.yml template #
data "template_file" "kubespray_all" {
  template = "${file("templates/kubespray_all.tpl")}"

  vars = {
    vsphere_vcenter_ip     = "${var.vsphere_vcenter}"
    vsphere_user           = "${var.vsphere_vcp_user}"
    vsphere_password       = "${var.vsphere_vcp_password}"
    vsphere_datacenter     = "${var.vsphere_datacenter}"
    vsphere_datastore      = "${var.vsphere_vcp_datastore}"
    vsphere_working_dir    = "${var.vm_folder}"
    vsphere_resource_pool  = "${var.vsphere_resource_pool}"
    loadbalancer_apiserver = "${var.vm_haproxy_vip}"
  }
}

# Kubespray k8s-cluster.yml template #
data "template_file" "kubespray_k8s_cluster" {
  template = "${file("templates/kubespray_k8s_cluster.tpl")}"

  vars = {
    kube_version        = "${var.k8s_version}"
    kube_network_plugin = "${var.k8s_network_plugin}"
    weave_password      = "${var.k8s_weave_encryption_password}"
    k8s_dns_mode        = "${var.k8s_dns_mode}"
  }
}

# HAProxy hostname and ip list template #
data "template_file" "haproxy_hosts" {
  count    = "${length(var.vm_haproxy_ips)}"
  template = "${file("templates/ansible_hosts.tpl")}"

  vars = {
    hostname = "${var.vm_name_prefix}-haproxy-${count.index}"
    host_ip  = "${lookup(var.vm_haproxy_ips, count.index)}"
  }
}

# Kubespray master hostname and ip list template #
data "template_file" "kubespray_hosts_master" {
  count    = "${length(var.vm_master_ips)}"
  template = "${file("templates/ansible_hosts.tpl")}"

  vars = {
    hostname = "${var.vm_name_prefix}-master-${count.index}"
    host_ip  = "${lookup(var.vm_master_ips, count.index)}"
  }
}

# Kubespray worker hostname and ip list template #
data "template_file" "kubespray_hosts_worker" {
  count    = "${length(var.vm_worker_ips)}"
  template = "${file("templates/ansible_hosts.tpl")}"

  vars = {
    hostname = "${var.vm_name_prefix}-worker-${count.index}"
    host_ip  = "${lookup(var.vm_worker_ips, count.index)}"
  }
}

# HAProxy hostname list template #
data "template_file" "haproxy_hosts_list" {
  count    = "${length(var.vm_haproxy_ips)}"
  template = "${file("templates/ansible_hosts_list.tpl")}"

  vars = {
    hostname = "${var.vm_name_prefix}-haproxy-${count.index}"
  }
}

# Kubespray master hostname list template #
data "template_file" "kubespray_hosts_master_list" {
  count    = "${length(var.vm_master_ips)}"
  template = "${file("templates/ansible_hosts_list.tpl")}"

  vars = {
    hostname = "${var.vm_name_prefix}-master-${count.index}"
  }
}

# Kubespray worker hostname list template #
data "template_file" "kubespray_hosts_worker_list" {
  count    = "${length(var.vm_worker_ips)}"
  template = "${file("templates/ansible_hosts_list.tpl")}"

  vars = {
    hostname = "${var.vm_name_prefix}-worker-${count.index}"
  }
}

# HAProxy template #
data "template_file" "haproxy" {
  template = "${file("templates/haproxy.tpl")}"

  vars = {
    bind_ip = "${var.vm_haproxy_vip}"
  }
}

# HAProxy server backend template #
data "template_file" "haproxy_backend" {
  count    = "${length(var.vm_master_ips)}"
  template = "${file("templates/haproxy_backend.tpl")}"

  vars = {
    prefix_server     = "${var.vm_name_prefix}"
    backend_server_ip = "${lookup(var.vm_master_ips, count.index)}"
    count             = "${count.index}"
  }
}

# Keepalived master template #
data "template_file" "keepalived_master" {
  template = "${file("templates/keepalived_master.tpl")}"

  vars = {
    virtual_ip = "${var.vm_haproxy_vip}"
  }
}

# Keepalived slave template #
data "template_file" "keepalived_slave" {
  template = "${file("templates/keepalived_slave.tpl")}"

  vars = {
    virtual_ip = "${var.vm_haproxy_vip}"
  }
}

#===============================================================================
# Local Files
#===============================================================================

# Create Kubespray all.yml configuration file from Terraform template #
resource "local_file" "kubespray_all" {
  content  = "${data.template_file.kubespray_all.rendered}"
  filename = "config/group_vars/all.yml"
}

# Create Kubespray k8s-cluster.yml configuration file from Terraform template #
resource "local_file" "kubespray_k8s_cluster" {
  content  = "${data.template_file.kubespray_k8s_cluster.rendered}"
  filename = "config/group_vars/k8s-cluster.yml"
}

# Create Kubespray hosts.ini configuration file from Terraform templates #
resource "local_file" "kubespray_hosts" {
  content  = "${join("", data.template_file.haproxy_hosts.*.rendered)}${join("", data.template_file.kubespray_hosts_master.*.rendered)}${join("", data.template_file.kubespray_hosts_worker.*.rendered)}\n[haproxy]\n${join("", data.template_file.haproxy_hosts_list.*.rendered)}\n[kube-master]\n${join("", data.template_file.kubespray_hosts_master_list.*.rendered)}\n[etcd]\n${join("", data.template_file.kubespray_hosts_master_list.*.rendered)}\n[kube-node]\n${join("", data.template_file.kubespray_hosts_worker_list.*.rendered)}\n[k8s-cluster:children]\nkube-master\nkube-node"
  filename = "config/hosts.ini"
}

# Create HAProxy configuration from Terraform templates #
resource "local_file" "haproxy" {
  content  = "${data.template_file.haproxy.rendered}${join("", data.template_file.haproxy_backend.*.rendered)}"
  filename = "config/haproxy.cfg"
}

# Create Keepalived master configuration from Terraform templates #
resource "local_file" "keepalived_master" {
  content  = "${data.template_file.keepalived_master.rendered}"
  filename = "config/keepalived-master.cfg"
}

# Create Keepalived slave configuration from Terraform templates #
resource "local_file" "keepalived_slave" {
  content  = "${data.template_file.keepalived_slave.rendered}"
  filename = "config/keepalived-slave.cfg"
}

#===============================================================================
# Locals
#===============================================================================

# Extra args for ansible playbooks #
locals {
  extra_args = {
    ubuntu = "-T 300"
    debian = "-T 300 -e 'ansible_become_method=su'"
    centos = "-T 300"
    rhel   = "-T 300"
  }
}

#===============================================================================
# Null Resource
#===============================================================================

# Modify the permission on the config directory
resource "null_resource" "config_permission" {
  provisioner "local-exec" {
    command = "chmod -R 700 config"
  }

  depends_on = ["local_file.haproxy", "local_file.kubespray_hosts", "local_file.kubespray_k8s_cluster", "local_file.kubespray_all"]
}

# Clone Kubespray repository #

resource "null_resource" "kubespray_download" {
  provisioner "local-exec" {
    command = "cd ansible && rm -rf kubespray && git clone --branch ${var.k8s_kubespray_version} ${var.k8s_kubespray_url}"
  }
}

# Execute register and auto-subscribe RHEL Ansible playbook #
resource "null_resource" "rhel_register" {
  count = "${var.vm_distro == "rhel" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd ansible/rhel && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD rh_username=${var.rh_username} rh_password=$RH_PASSWORD rh_subscription_server=${var.rh_subscription_server} rh_unverified_ssl=${var.rh_unverified_ssl}\" ${lookup(local.extra_args, var.vm_distro)} -v register.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
      RH_PASSWORD           = "${var.rh_password}"
    }
  }

  depends_on = ["local_file.kubespray_hosts", "vsphere_virtual_machine.haproxy", "vsphere_virtual_machine.worker", "vsphere_virtual_machine.master"]
}

# Execute register and auto-subscribe RHEL Ansible playbook when a node is added#
resource "null_resource" "rhel_register_kubespray_add" {
  count = "${var.vm_distro == "rhel" && var.action == "add_worker" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd ansible/rhel && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD rh_username=${var.rh_username} rh_password=$RH_PASSWORD rh_subscription_server=${var.rh_subscription_server} rh_unverified_ssl=${var.rh_unverified_ssl}\" ${lookup(local.extra_args, var.vm_distro)} -v register.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
      RH_PASSWORD           = "${var.rh_password}"
    }
  }

  depends_on = ["local_file.kubespray_hosts", "vsphere_virtual_machine.worker"]
}

# Execute firewalld RHEL Ansible playbook #
resource "null_resource" "rhel_firewalld" {
  count = "${var.vm_distro == "rhel" || var.vm_distro == "centos" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd ansible/rhel && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD\" ${lookup(local.extra_args, var.vm_distro)} -v firewalld.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
    }
  }

  depends_on = ["local_file.kubespray_hosts", "vsphere_virtual_machine.haproxy", "vsphere_virtual_machine.worker", "vsphere_virtual_machine.master"]
}

# Execute firewall RHEL Ansible playbook when a node is added#
resource "null_resource" "rhel_firewalld_kubespray_add" {
  count = "${var.vm_distro == "rhel" || var.vm_distro == "centos" && var.action == "add_worker" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd ansible/rhel && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD\" ${lookup(local.extra_args, var.vm_distro)} -v firewalld.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
    }
  }

  depends_on = ["local_file.kubespray_hosts", "vsphere_virtual_machine.worker"]
}

# Execute HAProxy Ansible playbook #
resource "null_resource" "haproxy_install" {
  count = "${var.action == "create" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd ansible/haproxy && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD\" ${lookup(local.extra_args, var.vm_distro)} -v haproxy.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
    }
  }

  depends_on = ["local_file.kubespray_hosts", "local_file.haproxy", "null_resource.rhel_register", "null_resource.rhel_firewalld", "vsphere_virtual_machine.haproxy"]
}

# Execute create Kubespray Ansible playbook #
resource "null_resource" "kubespray_create" {
  count = "${var.action == "create" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd ansible/kubespray && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD kube_version=${var.k8s_version}\" ${lookup(local.extra_args, var.vm_distro)} -v cluster.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
    }
  }

  depends_on = ["local_file.kubespray_hosts", "null_resource.kubespray_download", "local_file.kubespray_all", "local_file.kubespray_k8s_cluster", "null_resource.haproxy_install", "vsphere_virtual_machine.haproxy", "vsphere_virtual_machine.worker", "vsphere_virtual_machine.master"]
}

# Execute scale Kubespray Ansible playbook #
resource "null_resource" "kubespray_add" {
  count = "${var.action == "add_worker" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd ansible/kubespray && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD kube_version=${var.k8s_version}\" ${lookup(local.extra_args, var.vm_distro)} -v scale.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
    }
  }

  depends_on = ["local_file.kubespray_hosts", "null_resource.kubespray_download", "local_file.kubespray_all", "local_file.kubespray_k8s_cluster", "null_resource.haproxy_install", "vsphere_virtual_machine.haproxy", "vsphere_virtual_machine.worker", "vsphere_virtual_machine.master"]
}

# Execute upgrade Kubespray Ansible playbook #
resource "null_resource" "kubespray_upgrade" {
  count = "${var.action == "upgrade" ? 1 : 0}"

  triggers = {
    ts = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "cd ansible && rm -rf kubespray && git clone --branch ${var.k8s_kubespray_version} ${var.k8s_kubespray_url}"
  }

  provisioner "local-exec" {
    command = "cd ansible/kubespray && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD kube_version=${var.k8s_version}\" ${lookup(local.extra_args, var.vm_distro)} -v upgrade-cluster.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
    }
  }

  depends_on = ["local_file.kubespray_hosts", "null_resource.kubespray_download", "local_file.kubespray_all", "local_file.kubespray_k8s_cluster", "null_resource.haproxy_install", "vsphere_virtual_machine.haproxy", "vsphere_virtual_machine.worker", "vsphere_virtual_machine.master"]
}

# Create the local admin.conf kubectl configuration file #
resource "null_resource" "kubectl_configuration" {
  provisioner "local-exec" {
    command = "ansible -i ${lookup(var.vm_master_ips, 0)}, -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD\" ${lookup(local.extra_args, var.vm_distro)} -m fetch -a 'src=/etc/kubernetes/admin.conf dest=config/admin.conf flat=yes' all"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
    }
  }

  provisioner "local-exec" {
    command = "sed 's/lb-apiserver.kubernetes.local/${var.vm_haproxy_vip}/g' config/admin.conf | tee config/admin.conf.new && mv config/admin.conf.new config/admin.conf && chmod 700 config/admin.conf"
  }

  provisioner "local-exec" {
    command = "chmod 600 config/admin.conf"
  }

  depends_on = ["null_resource.kubespray_create"]
}

#===============================================================================
# vSphere Resources
#===============================================================================

# Create a virtual machine folder for the Kubernetes VMs #
resource "vsphere_folder" "folder" {
  path          = "${var.vm_folder}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# Create a resource pool for the Kubernetes VMs #
resource "vsphere_resource_pool" "resource_pool" {
  name                    = "${var.vsphere_resource_pool}"
  parent_resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
}

# Create the Kubernetes master VMs #
resource "vsphere_virtual_machine" "master" {
  count            = "${length(var.vm_master_ips)}"
  name             = "${var.vm_name_prefix}-master-${count.index}"
  resource_pool_id = "${vsphere_resource_pool.resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"

  num_cpus         = "${var.vm_master_cpu}"
  memory           = "${var.vm_master_ram}"
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"
  enable_disk_uuid = "true"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.vm_name_prefix}-master-${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "${var.vm_linked_clone}"

    customize {
      timeout = "20"

      linux_options {
        host_name = "${var.vm_name_prefix}-master-${count.index}"
        domain    = "${var.vm_domain}"
      }

      network_interface {
        ipv4_address = "${lookup(var.vm_master_ips, count.index)}"
        ipv4_netmask = "${var.vm_netmask}"
      }

      ipv4_gateway    = "${var.vm_gateway}"
      dns_server_list = ["${var.vm_dns}"]
    }
  }

  depends_on = ["vsphere_virtual_machine.haproxy"]
}

# Create anti affinity rule for the Kubernetes master VMs #
resource "vsphere_compute_cluster_vm_anti_affinity_rule" "master_anti_affinity_rule" {
  count               = "${var.vsphere_enable_anti_affinity == "true" ? 1 : 0}"
  name                = "${var.vm_name_prefix}-master-anti-affinity-rule"
  compute_cluster_id  = "${data.vsphere_compute_cluster.cluster.id}"
  virtual_machine_ids = "${vsphere_virtual_machine.master.*.id}"

  depends_on = ["vsphere_virtual_machine.master"]
}

# Create the Kubernetes worker VMs #
resource "vsphere_virtual_machine" "worker" {
  count            = "${length(var.vm_worker_ips)}"
  name             = "${var.vm_name_prefix}-worker-${count.index}"
  resource_pool_id = "${vsphere_resource_pool.resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"

  num_cpus         = "${var.vm_worker_cpu}"
  memory           = "${var.vm_worker_ram}"
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"
  enable_disk_uuid = "true"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.vm_name_prefix}-worker-${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "${var.vm_linked_clone}"

    customize {
      timeout = "20"

      linux_options {
        host_name = "${var.vm_name_prefix}-worker-${count.index}"
        domain    = "${var.vm_domain}"
      }

      network_interface {
        ipv4_address = "${lookup(var.vm_worker_ips, count.index)}"
        ipv4_netmask = "${var.vm_netmask}"
      }

      ipv4_gateway    = "${var.vm_gateway}"
      dns_server_list = ["${var.vm_dns}"]
    }
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "cd ansible/kubespray && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD node=$VM_NAME delete_nodes_confirmation=yes\" -v remove-node.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
      VM_NAME               = "${var.vm_name_prefix}-worker-${count.index}"
    }

    on_failure = "continue"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "sed 's/${var.vm_name_prefix}-worker-[0-9]*$//' config/hosts.ini"
  }

  depends_on = ["vsphere_virtual_machine.master", "local_file.kubespray_hosts", "local_file.kubespray_k8s_cluster", "local_file.kubespray_all"]
}

# Create the HAProxy load balancer VM #
resource "vsphere_virtual_machine" "haproxy" {
  count            = "${length(var.vm_haproxy_ips)}"
  name             = "${var.vm_name_prefix}-haproxy-${count.index}"
  resource_pool_id = "${vsphere_resource_pool.resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"

  num_cpus = "${var.vm_haproxy_cpu}"
  memory   = "${var.vm_haproxy_ram}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.vm_name_prefix}-haproxy-${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "${var.vm_linked_clone}"

    customize {
      timeout = "20"

      linux_options {
        host_name = "${var.vm_name_prefix}-haproxy-${count.index}"
        domain    = "${var.vm_domain}"
      }

      network_interface {
        ipv4_address = "${lookup(var.vm_haproxy_ips, count.index)}"
        ipv4_netmask = "${var.vm_netmask}"
      }

      ipv4_gateway    = "${var.vm_gateway}"
      dns_server_list = ["${var.vm_dns}"]
    }
  }
}
