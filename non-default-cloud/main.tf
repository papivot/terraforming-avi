#####################
# Data capture
#####################

data "vsphere_datacenter" "wcp_datacenter" {
	      name = var.vcenter_datacenter
}

data "vsphere_compute_cluster" "wcp_cluster" {
	      name = var.vcenter_cluster
	      datacenter_id = data.vsphere_datacenter.wcp_datacenter.id
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

#data "avi_cloud" "default" {
#  name = data.vsphere_compute_cluster.wcp_cluster.id
#}

#####################
# Resource creation
#####################

# Stage 1

resource "avi_useraccount" "avi_user" {
  username     = var.avi_tenant
  old_password = var.avi_current_password
  password     = var.avi_password == null ? random_string.avi_password_random.result : var.avi_password
}

resource "random_string" "avi_password_random" {
  length           = 8
  special          = true
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_"
}

resource "local_file" "output_passwd_file_random" {
  count   = var.avi_password == null ? 1 : 0
  content     = "{\"avi_password\": ${jsonencode(random_string.avi_password_random.result)}}"
  filename = "../.password.json"
}

resource "local_file" "output_passwd_file_static" {
  count   = var.avi_password == null ? 0 : 1
  content     = "{\"avi_password\": ${jsonencode(var.avi_password)}}"
  filename = "../.password.json"
}

# Stage 2

resource "avi_sslkeyandcertificate" "wcp_avi_cert" {
  name                 = var.avi_dns_name
  format               = "SSL_PEM"
  certificate_base64   = true
  enable_ocsp_stapling = false
  import_key_to_hsm    = false
  is_federated         = false
  key_base64           = true
  tenant_ref           = data.avi_tenant.tenant.id
  type                 = "SSL_CERTIFICATE_TYPE_SYSTEM"
  certificate {
    days_until_expire   = 365
    self_signed         = true
    version             = "2"
    signature_algorithm = "sha256WithRSAEncryption"
    subject_alt_names   = var.avi_controller_ips
    issuer {
      common_name        = var.avi_dns_name
      distinguished_name = "CN=${var.avi_dns_name}"
    }
    subject {
      common_name        = var.avi_dns_name
      distinguished_name = "CN=${var.avi_dns_name}"
    }
  }
  key_params {
    algorithm = "SSL_KEY_ALGORITHM_RSA"
    rsa_params  {
      exponent = 65537
      key_size = "SSL_KEY_2048_BITS"
    }
  }
  ocsp_config {
    failed_ocsp_jobs_retry_interval = 3600
    max_tries                       = 10
    ocsp_req_interval               = 86400
    url_action                      = "OCSP_RESPONDER_URL_FAILOVER"
  }
  depends_on = [
    avi_useraccount.avi_user
  ]
}

resource "avi_systemconfiguration" "avi_system" {
  common_criteria_mode      = false
  default_license_tier      = var.avi_license
  welcome_workflow_complete = true

  dns_configuration {
    dynamic server_list {
      for_each = flatten(split(",", replace(var.avi_dns_server_ips, " ", "")))
      content {
        addr = server_list.value
        type = "V4"
      }
    }
  }

  ntp_configuration {
    dynamic ntp_servers {
      for_each = flatten(split(",", replace(var.avi_ntp_server_ips, " ", "")))
      content {
        key_number = 1
        server {
          addr = ntp_servers.value
          type = "V4"
        }
      }
    }
  }

  global_tenant_config {
    se_in_provider_context       = true
    tenant_access_to_provider_se = true
    tenant_vrf                   = false
  }

  portal_configuration {
    sslkeyandcertificate_refs = [avi_sslkeyandcertificate.wcp_avi_cert.id]
  }

  depends_on = [
    avi_sslkeyandcertificate.wcp_avi_cert
  ]

  lifecycle {
#    prevent_destroy = true
    ignore_changes = [
      ssh_hmacs, ssh_ciphers, secure_channel_configuration, email_configuration
    ]
  }
}

resource "avi_backupconfiguration" "backup_config" {
  name                   = "Backup-Configuration"
  tenant_ref             = data.avi_tenant.tenant.id
  save_local             = true
  maximum_backups_stored = 4
  backup_passphrase      = var.avi_password
  configpb_attributes {
    version = 1
  }
  depends_on = [
    avi_systemconfiguration.avi_system
  ]

}

# Stage 3

resource "avi_ipamdnsproviderprofile" "wcp_ipam" {
  name               = "aviipam"
  tenant_ref         = data.avi_tenant.tenant.id
  type               = "IPAMDNS_TYPE_INTERNAL"
  allocate_ip_in_vrf = false
  internal_profile {
    ttl = 30
  }
  depends_on = [
    avi_systemconfiguration.avi_system
  ]
}

resource "avi_ipamdnsproviderprofile" "wcp_dns" {
	name	             = "avidns"
	type	             = "IPAMDNS_TYPE_INTERNAL_DNS"
	internal_profile {
		dns_service_domain {
			domain_name  = "k8s.${var.search_domain}"
			pass_through = false
			record_ttl   = 30
		}
	}
  depends_on = [
    avi_systemconfiguration.avi_system
  ]
}

resource "avi_cloud" "vmware_cloud_wcp" {
# name                              = var.cloud_name
  name                              = data.vsphere_compute_cluster.wcp_cluster.id
  vtype                             = "CLOUD_VCENTER"
  dhcp_enabled                      = true
  license_tier                      = "ENTERPRISE"
  license_type                      = "LIC_CORES"
  ipam_provider_ref                 = avi_ipamdnsproviderprofile.wcp_ipam.id
  dns_provider_ref                  = avi_ipamdnsproviderprofile.wcp_dns.id
# se_group_template_ref             = "https://${var.avi_controller_ips[0]}/api/serviceenginegroup/${data.avi_serviceenginegroup.wcp_serviceenginegroup.uuid}"
  tenant_ref                        = data.avi_tenant.tenant.id
  vcenter_configuration {
    privilege               = "WRITE_ACCESS"
    username                = var.vcenter_username
    password                = var.vcenter_password
    vcenter_url             = var.vcenter_url
    datacenter              = var.vcenter_datacenter
    use_content_lib         = false
    management_network      = var.vcenter_management_network
  }
  depends_on = [
    avi_ipamdnsproviderprofile.wcp_dns, avi_ipamdnsproviderprofile.wcp_ipam
  ]
}

resource "avi_vrfcontext" "vrf_global" {
  name           = "global"
  cloud_ref      = avi_cloud.vmware_cloud_wcp.id
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
  depends_on = [
    avi_cloud.vmware_cloud_wcp
  ]
}

resource "avi_network" "wcp_management" {
  name                       = var.vcenter_management_network
  tenant_ref                 = data.avi_tenant.tenant.id
  dhcp_enabled               = false
  exclude_discovered_subnets = false
  ip6_autocfg_enabled        = false
  synced_from_se             = true
  vcenter_dvs                = true
  cloud_ref                  = avi_cloud.vmware_cloud_wcp.id
  vrf_context_ref            = avi_vrfcontext.vrf_global.id
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
  depends_on = [
    avi_cloud.vmware_cloud_wcp, avi_vrfcontext.vrf_global
  ]
}

resource "avi_network" "wcp_vip_pool" {
  name                       = var.vcenter_vip_network
  tenant_ref                 = data.avi_tenant.tenant.id
  dhcp_enabled               = false
  exclude_discovered_subnets = false
  ip6_autocfg_enabled        = false
  synced_from_se             = true
  vcenter_dvs                = true
  cloud_ref                  = avi_cloud.vmware_cloud_wcp.id
  vrf_context_ref            = avi_vrfcontext.vrf_global.id
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
  depends_on = [
    avi_cloud.vmware_cloud_wcp, avi_vrfcontext.vrf_global
  ]
}

resource "avi_ipamdnsproviderprofile" "wcp_ipam1" {
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
  depends_on = [
    avi_network.wcp_vip_pool
  ]
}