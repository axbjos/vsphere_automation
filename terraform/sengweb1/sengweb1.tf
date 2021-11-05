variable "vmipaddress" {
  type = string
}

variable "vmhostname" {
  type = string
}

provider "vsphere" {
  user           = "administrator@senglab.local" 
  password       = "SengAdmin1!" 
  vsphere_server = "192.168.200.204" 

  # If you have a self-signed cert
  allow_unverified_ssl = true
}
data "vsphere_datacenter" "dc" {
  name = "SENGLABDC1"
}

# don't use resource pools yet
#data "vsphere_resource_pool" "pool" {
#  name          = "CNET-JOE"
# datacenter_id = data.vsphere_datacenter.dc.id
#}

data "vsphere_datastore" "datastore" {
  name          = "SSD_DATASTORE_202"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "SENGLABCLS1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "VM Network Blue"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "ub20template1" 
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.vmhostname 
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder = "Webservers"

  num_cpus = 1
  memory   = 1024
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.vmhostname 
        domain    = "senglab.net"
      }

      network_interface {
        ipv4_address = var.vmipaddress 
        ipv4_netmask = 16 
      }

      ipv4_gateway = "192.168.1.1"
      dns_suffix_list = ["senglab.net"]
      dns_server_list = ["192.168.1.1"]
    }
  }
}
