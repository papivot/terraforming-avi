data "vsphere_datacenter" "wcp_datacenter" {
	name = var.vcenter_datacenter
}

data "vsphere_distributed_virtual_switch" "wcp_vds" {
  name          = var.vcenter_vds
  datacenter_id = data.vsphere_datacenter.wcp_datacenter.id
}

data "vsphere_network" "wcp_mgmt_network" {
  name          = var.vcenter_management_network
  datacenter_id = data.vsphere_datacenter.wcp_datacenter.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.wcp_vds.id
}

data "vsphere_network" "wcp_vip_network" {
  name          = var.vcenter_vip_network
  datacenter_id = data.vsphere_datacenter.wcp_datacenter.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.wcp_vds.id
}

data "avi_tenant" "tenant" {
  name = var.avi_tenant
}

data "avi_cloud" "default" {
  name = var.cloud_name
}

data "avi_vrfcontext" "vrf_global" {
	name = "global"
}

data "avi_network" "wcp_management" {
  name = var.vcenter_management_network
  cloud_ref = "/api/cloud/?tenant=${var.avi_tenant}&name=${var.cloud_name}"
}

data "avi_network" "wcp_vip_pool" {
  name = var.vcenter_vip_network
  cloud_ref = "/api/cloud/?tenant=${var.avi_tenant}&name=${var.cloud_name}"
}

data "avi_ipamdnsproviderprofile" "wcp_ipam" {
  name = "aviipam"
}

#need to import all the avi_network and ipam
# terraform import avi_network.wcp_management          https://192.168.100.58/api/network/dvportgroup-71-cloud-27875897-ccae-4167-a404-9aa462f1c654
# terraform import avi_network.wcp_vip_pool            https://192.168.100.58/api/network/dvportgroup-72-cloud-27875897-ccae-4167-a404-9aa462f1c654
# terraform import avi_ipamdnsproviderprofile.wcp_ipam https://192.168.100.58/api/ipamdnsproviderprofile/ipamdnsproviderprofile-70e1a9ad-d0f0-4a50-bb6b-741998725b03

output "import_mgmt" {
  value = "terraform import avi_network.wcp_management https://${var.avi_controller_ips[0]}/api/network/${data.vsphere_network.wcp_mgmt_network.id}-${data.avi_cloud.default.uuid}"
}

output "vip" {
  value = "terraform import avi_network.wcp_vip_pool https://${var.avi_controller_ips[0]}/api/network/${data.vsphere_network.wcp_vip_network.id}-${data.avi_cloud.default.uuid}"
}

output "def_ipam" {
  value = "terraform import avi_ipamdnsproviderprofile.wcp_ipam ${data.avi_ipamdnsproviderprofile.wcp_ipam.id}"
}

resource "avi_network" "wcp_management" {
  name                       = var.vcenter_management_network
  tenant_ref                 = data.avi_tenant.tenant.id
  dhcp_enabled               = false
  exclude_discovered_subnets = false
  ip6_autocfg_enabled        = false
  synced_from_se             = true
  vcenter_dvs                = true
  cloud_ref                  = "https://${var.avi_controller_ips[0]}/api/cloud/${data.avi_cloud.default.uuid}"
  vrf_context_ref            = "https://${var.avi_controller_ips[0]}/api/vrfcontext/${data.avi_vrfcontext.vrf_global.uuid}"
  configured_subnets {
      prefix {
        ip_addr {
          addr = "192.168.100.0"
          type = "V4"
        }
        mask = 23
      }
      static_ip_ranges {
          range {
            begin {
              addr = "192.168.100.70"
              type = "V4"
            }
            end {
              addr = "192.168.100.75"
              type = "V4"
            }
          }
          type = "STATIC_IPS_FOR_SE"
        }
    }
}

resource "avi_network" "wcp_vip_pool" {
  name                       = var.vcenter_vip_network
  tenant_ref                 = data.avi_tenant.tenant.id
  dhcp_enabled               = false
  exclude_discovered_subnets = false
  ip6_autocfg_enabled        = false
  synced_from_se             = true
  vcenter_dvs                = true
  cloud_ref                  = "https://${var.avi_controller_ips[0]}/api/cloud/${data.avi_cloud.default.uuid}"
  vrf_context_ref            = "https://${var.avi_controller_ips[0]}/api/vrfcontext/${data.avi_vrfcontext.vrf_global.uuid}"
  configured_subnets {
      prefix {
        ip_addr {
          addr = "192.168.102.0"
          type = "V4"
        }
        mask = 23
      }
      static_ip_ranges {
          range {
            begin {
              addr = "192.168.103.0"
              type = "V4"
            }
            end {
              addr = "192.168.103.100"
              type = "V4"
            }
          }
          type = "STATIC_IPS_FOR_VIP_AND_SE"
        }
    }
}

resource "avi_ipamdnsproviderprofile" "wcp_ipam" {
  name               = "aviipam"
  tenant_ref         = data.avi_tenant.tenant.id
  type               = "IPAMDNS_TYPE_INTERNAL"
  allocate_ip_in_vrf = false
  internal_profile {
    ttl = 30
    usable_networks {
      nw_ref = avi_network.wcp_vip_pool.id
    }
  }
}