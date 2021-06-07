variable "vmipaddress" {
  type = string
}

variable "vmhostname" {
  type = string
}

provider "vsphere" {
  user           = "administrator@axnet.local" 
  password       = "axbRTR95!" 
  vsphere_server = "192.168.2.200" 

  # If you have a self-signed cert
  allow_unverified_ssl = true
}
data "vsphere_datacenter" "dc" {
  name = "AXNETDC1"
}

#data "vsphere_resource_pool" "pool" {
#  name          = "CNET-JOE"
# datacenter_id = data.vsphere_datacenter.dc.id
#}

data "vsphere_datastore" "datastore" {
  name          = "1TB_SSD_1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "AXNETCLS1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "ub18template1" 
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.vmhostname 
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder = "AutomationTestingJA"

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
        domain    = "axnetiot.net"
      }

      network_interface {
        ipv4_address = var.vmipaddress 
        ipv4_netmask = 24
      }

      ipv4_gateway = "192.168.1.1"
      dns_suffix_list = ["axnetiot.net"]
      dns_server_list = ["192.168.1.1"]
    }
  }
}
