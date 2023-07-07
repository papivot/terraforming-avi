data "vsphere_content_library" "library" {
  name = "avi"
}

data "vsphere_datacenter" "wcp_datacenter" {
	name = var.vcenter_datacenter
}

data "vsphere_distributed_virtual_switch" "wcp_vds" {
  name          = "Pacific-VDS"
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

data "vsphere_compute_cluster" "wcp_cluster" {
	name = var.vcenter_cluster
	datacenter_id = data.vsphere_datacenter.wcp_datacenter.id
}

data "avi_tenant" "tenant" {
  name = var.tenant
}

data "avi_cloud" "default" {
  name = var.cloud_name
}

data "avi_vrfcontext" "vrf_global" {
	name = "global"
}

data "avi_serviceenginegroup" "wcp_serviceenginegroup" {
  name = "Default-Group"
  cloud_ref = "/api/cloud/?tenant=${var.tenant}&name=${var.cloud_name}"
}

resource "avi_vrfcontext" "vrf_global" {
  name           = "global"
  cloud_ref      = "https://${var.avi_controller_ips[0]}/api/cloud/${data.avi_cloud.default.uuid}"
  tenant_ref     = data.avi_tenant.tenant.id
  system_default = true
  lldp_enable    = true
  static_routes  {
    next_hop {
      addr = "192.168.102.1"
      type = "V4"
    }
    prefix {
      ip_addr {
        addr = "0.0.0.0"
        type = "V4"
      }
      mask = 0
    }
    route_id = "1"
  }
}

resource "avi_ipamdnsproviderprofile" "wcp_ipam" {
  name               = "aviipam"
  tenant_ref         = data.avi_tenant.tenant.id
  type               = "IPAMDNS_TYPE_INTERNAL"
  allocate_ip_in_vrf = false
  internal_profile {
    ttl = 30
  }
}

resource "avi_ipamdnsproviderprofile" "wcp_dns" {
	name	             = "avidns"
	type	             = "IPAMDNS_TYPE_INTERNAL_DNS"
	internal_profile {
		dns_service_domain {
			domain_name  = "k8s.env1.lab.test"
			pass_through = false
			record_ttl   = 30
		}
	}
}

resource "avi_cloud" "vmware_cloud_wcp" {
  name                              = var.cloud_name
  vtype                             = "CLOUD_VCENTER"
#  autoscale_polling_interval        = 60
#  metrics_polling_interval          = 60
#  mtu                               = 1500
#  vmc_deployment                    = false
#  dns_resolution_on_se              = false
#  enable_vip_on_all_interfaces      = false
#  enable_vip_static_routes          = false
#  ip6_autocfg_enabled               = false
#  maintenance_mode                  = false
#  prefer_static_routes              = false
#  state_based_dns_registration      = true
  dhcp_enabled                      = true
  license_tier                      = "ENTERPRISE"
  license_type                      = "LIC_CORES"
  ipam_provider_ref                 = avi_ipamdnsproviderprofile.wcp_ipam.id
  dns_provider_ref                  = avi_ipamdnsproviderprofile.wcp_dns.id
  se_group_template_ref             = "https://${var.avi_controller_ips[0]}/api/serviceenginegroup/${data.avi_serviceenginegroup.wcp_serviceenginegroup.uuid}"
  tenant_ref                        = data.avi_tenant.tenant.id
  vcenter_configuration {
    privilege               = "WRITE_ACCESS"
    username                = var.vcenter_username
    password                = var.vcenter_password
    vcenter_url             = var.vcenter_url
    datacenter              = var.vcenter_datacenter
    use_content_lib         = false
    deactivate_vm_discovery = false
#    is_nsx_environment      = false
    content_lib {
      id = data.vsphere_content_library.library.id
    }
    management_network      = "https://${var.avi_controller_ips[0]}/api/vimgrnwruntime/${data.vsphere_network.wcp_mgmt_network.id}-${data.avi_cloud.default.uuid}"
#    management_network      = var.vcenter_management_network
  }
#  lifecycle {
#    ignore_changes = [
#	      vcenter_configuration
#    ]
#  }
  depends_on = [
    avi_ipamdnsproviderprofile.wcp_dns, avi_ipamdnsproviderprofile.wcp_ipam, avi_vrfcontext.vrf_global
  ]
}