#===============================================================================
# vSphere Provider
#===============================================================================

provider "vsphere" {
  version        = "1.5.0"
  vsphere_server = "${var.vsphere_vcenter}"
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"

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

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_resource_pool}"
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
# Templates
#===============================================================================

# Kubespray all.yml template #
data "template_file" "kubespray_all" {
  template = "${file("templates/kubespray_all.tpl")}"

  vars {
    vsphere_vcenter_ip     = "${var.vsphere_vcenter}"
    vsphere_user           = "${var.vsphere_vcp_user}"
    vsphere_password       = "${var.vsphere_vcp_password}"
    vsphere_datacenter     = "${var.vsphere_datacenter}"
    vsphere_datastore      = "${var.vsphere_vcp_datastore}"
    vsphere_working_dir    = "${var.vm_folder}"
    vsphere_resource_pool  = "${var.vsphere_resource_pool}"
    loadbalancer_apiserver = "${var.k8s_haproxy_ip}"
  }
}

# Kubespray k8s-cluster.yml template #
data "template_file" "kubespray_k8s_cluster" {
  template = "${file("templates/kubespray_k8s_cluster.tpl")}"

  vars {
    kube_version        = "${var.k8s_version}"
    kube_network_plugin = "${var.k8s_network_plugin}"
    weave_password      = "${var.k8s_weave_encryption_password}"
  }
}

# Kubespray master hostname and ip list template #
data "template_file" "kubespray_hosts_master" {
  count    = "${length(var.k8s_master_ips)}"
  template = "${file("templates/kubespray_hosts.tpl")}"

  vars {
    hostname = "${var.k8s_node_prefix}-master-${count.index}"
    host_ip  = "${lookup(var.k8s_master_ips, count.index)}"
  }
}

# Kubespray worker hostname and ip list template #
data "template_file" "kubespray_hosts_worker" {
  count    = "${length(var.k8s_worker_ips)}"
  template = "${file("templates/kubespray_hosts.tpl")}"

  vars {
    hostname = "${var.k8s_node_prefix}-worker-${count.index}"
    host_ip  = "${lookup(var.k8s_worker_ips, count.index)}"
  }
}

# Kubespray master hostname list template #
data "template_file" "kubespray_hosts_master_list" {
  count    = "${length(var.k8s_master_ips)}"
  template = "${file("templates/kubespray_hosts_list.tpl")}"

  vars {
    hostname = "${var.k8s_node_prefix}-master-${count.index}"
  }
}

# Kubespray worker hostname list template #
data "template_file" "kubespray_hosts_worker_list" {
  count    = "${length(var.k8s_worker_ips)}"
  template = "${file("templates/kubespray_hosts_list.tpl")}"

  vars {
    hostname = "${var.k8s_node_prefix}-worker-${count.index}"
  }
}

# HAProxy template #
data "template_file" "haproxy" {
  template = "${file("templates/haproxy.tpl")}"

  vars {
    bind_ip = "${var.k8s_haproxy_ip}"
  }
}

# HAProxy server backend template #
data "template_file" "haproxy_backend" {
  count    = "${length(var.k8s_master_ips)}"
  template = "${file("templates/haproxy_backend.tpl")}"

  vars {
    prefix_server     = "${var.k8s_node_prefix}"
    backend_server_ip = "${lookup(var.k8s_master_ips, count.index)}"
    count             = "${count.index}"
  }
}

#===============================================================================
# Local Resources
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
  content  = "${join("", data.template_file.kubespray_hosts_master.*.rendered)}${join("", data.template_file.kubespray_hosts_worker.*.rendered)}\n[kube-master]\n${join("", data.template_file.kubespray_hosts_master_list.*.rendered)}\n[etcd]\n${join("", data.template_file.kubespray_hosts_master_list.*.rendered)}\n[kube-node]\n${join("", data.template_file.kubespray_hosts_worker_list.*.rendered)}\n[k8s-cluster:children]\nkube-master\nkube-node"
  filename = "config/hosts.ini"
}

# Create HAProxy configuration from Terraform templates #
resource "local_file" "haproxy" {
  content  = "${data.template_file.haproxy.rendered}${join("", data.template_file.haproxy_backend.*.rendered)}"
  filename = "config/haproxy.cfg"
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
    command = "rm -rf kubespray && git clone --branch ${var.k8s_kubespray_version} ${var.k8s_kubespray_url}"
  }
}

# Execute create Kubespray Ansible playbook #
resource "null_resource" "kubespray_create" {
  count = "${var.action == "create" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd kubespray && ansible-playbook -i ../config/hosts.ini -b -u ${var.vm_user} -v cluster.yml -e kube_version=${var.k8s_version}"
  }

  depends_on = ["null_resource.kubespray_download", "local_file.kubespray_all", "local_file.kubespray_k8s_cluster", "local_file.kubespray_hosts", "vsphere_virtual_machine.master", "vsphere_virtual_machine.worker", "vsphere_virtual_machine.haproxy"]
}

# Execute scale Kubespray Ansible playbook #
resource "null_resource" "kubespray_add" {
  count = "${var.action == "add_worker" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd kubespray && ansible-playbook -i ../config/hosts.ini -b -u ${var.vm_user} -v scale.yml"
  }

  depends_on = ["null_resource.kubespray_download", "local_file.kubespray_all", "local_file.kubespray_k8s_cluster", "local_file.kubespray_hosts", "vsphere_virtual_machine.master", "vsphere_virtual_machine.worker", "vsphere_virtual_machine.haproxy"]
}

# Execute upgrade Kubespray Ansible playbook #
resource "null_resource" "kubespray_upgrade" {
  count = "${var.action == "upgrade" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd kubespray && ansible-playbook -i ../config/hosts.ini -b -u ${var.vm_user} -v upgrade-cluster.yml -e kube_version=${var.k8s_version}"
  }

  depends_on = ["null_resource.kubespray_download", "local_file.kubespray_all", "local_file.kubespray_k8s_cluster", "local_file.kubespray_hosts", "vsphere_virtual_machine.master", "vsphere_virtual_machine.worker", "vsphere_virtual_machine.haproxy"]
}

# Create the local admin.conf kubectl configuration file #
resource "null_resource" "kubectl_configuration" {
  provisioner "local-exec" {
    command = "ansible -i ${lookup(var.k8s_master_ips, 0)}, -b -u ${var.vm_user} -m fetch -a 'src=/etc/kubernetes/admin.conf dest=config/admin.conf flat=yes' all"
  }

  provisioner "local-exec" {
    command = "sed -i 's/lb-apiserver.kubernetes.local/${var.k8s_haproxy_ip}/g' config/admin.conf"
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

# Create the Kubernetes master VMs #
resource "vsphere_virtual_machine" "master" {
  count            = "${length(var.k8s_master_ips)}"
  name             = "${var.k8s_node_prefix}-master-${count.index}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"

  num_cpus         = "${var.k8s_master_cpu}"
  memory           = "${var.k8s_master_ram}"
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"
  enable_disk_uuid = "true"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.k8s_node_prefix}-master-${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "${var.vm_linked_clone}"

    customize {
      linux_options {
        host_name = "${var.k8s_node_prefix}-${count.index}"
        domain    = "${var.k8s_domain}"
      }

      network_interface {
        ipv4_address = "${lookup(var.k8s_master_ips, count.index)}"
        ipv4_netmask = "${var.k8s_netmask}"
      }

      ipv4_gateway    = "${var.k8s_gateway}"
      dns_server_list = ["${var.k8s_dns}"]
    }
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "${var.vm_user}"
      password = "${var.vm_password}"
    }

    inline = [
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab",
    ]
  }

  depends_on = ["vsphere_virtual_machine.haproxy"]
}

# Create anti affinity rule for the Kubernetes master VMs #
resource "vsphere_compute_cluster_vm_anti_affinity_rule" "master_anti_affinity_rule" {
  count               = "${var.vsphere_enable_anti_affinity == "true" ? 1 : 0}"
  name                = "${var.k8s_node_prefix}-master-anti-affinity-rule"
  compute_cluster_id  = "${data.vsphere_compute_cluster.cluster.id}"
  virtual_machine_ids = ["${vsphere_virtual_machine.master.*.id}"]
}

# Create the Kubernetes worker VMs #
resource "vsphere_virtual_machine" "worker" {
  count            = "${length(var.k8s_worker_ips)}"
  name             = "${var.k8s_node_prefix}-worker-${count.index}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"

  num_cpus         = "${var.k8s_worker_cpu}"
  memory           = "${var.k8s_worker_ram}"
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"
  enable_disk_uuid = "true"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.k8s_node_prefix}-worker-${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "${var.vm_linked_clone}"

    customize {
      linux_options {
        host_name = "${var.k8s_node_prefix}-worker-${count.index}"
        domain    = "${var.k8s_domain}"
      }

      network_interface {
        ipv4_address = "${lookup(var.k8s_worker_ips, count.index)}"
        ipv4_netmask = "${var.k8s_netmask}"
      }

      ipv4_gateway    = "${var.k8s_gateway}"
      dns_server_list = ["${var.k8s_dns}"]
    }
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "${var.vm_user}"
      password = "${var.vm_password}"
    }

    inline = [
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab",
    ]
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "sed 's/${var.k8s_node_prefix}-worker-[0-9]*$//' config/hosts.ini > config/hosts_remove_${count.index}.ini && sed -i '1 i\\${var.k8s_node_prefix}-worker-${count.index}\\ ansible_host=${self.default_ip_address}' config/hosts_remove_${count.index}.ini && sed -i 's/\\[kube-node\\]/\\[kube-node\\]\\n${var.k8s_node_prefix}-worker-${count.index}/' config/hosts_remove_${count.index}.ini"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "cd kubespray && ansible-playbook -i ../config/hosts_remove_${count.index}.ini -b -u ${var.vm_user} -e 'delete_nodes_confirmation=yes' -v remove-node.yml"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm config/hosts_remove_${count.index}.ini"
  }

  depends_on = ["vsphere_virtual_machine.master", "local_file.kubespray_hosts", "local_file.kubespray_k8s_cluster", "local_file.kubespray_all"]
}

# Create the HAProxy load balancer VM #
resource "vsphere_virtual_machine" "haproxy" {
  name             = "${var.k8s_node_prefix}-haproxy"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"

  num_cpus = "${var.k8s_haproxy_cpu}"
  memory   = "${var.k8s_haproxy_ram}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.k8s_node_prefix}-haproxy.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "${var.vm_linked_clone}"

    customize {
      linux_options {
        host_name = "${var.k8s_node_prefix}-haproxy"
        domain    = "${var.k8s_domain}"
      }

      network_interface {
        ipv4_address = "${var.k8s_haproxy_ip}"
        ipv4_netmask = "${var.k8s_netmask}"
      }

      ipv4_gateway    = "${var.k8s_gateway}"
      dns_server_list = ["${var.k8s_dns}"]
    }
  }

  provisioner "file" {
    connection {
      type     = "ssh"
      user     = "${var.vm_user}"
      password = "${var.vm_password}"
    }

    source      = "config/haproxy.cfg"
    destination = "/tmp/haproxy.cfg"
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "${var.vm_user}"
      password = "${var.vm_password}"
    }

    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y haproxy",
      "sudo mv /tmp/haproxy.cfg /etc/haproxy",
      "sudo systemctl restart haproxy",
    ]
  }
}
