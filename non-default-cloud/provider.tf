terraform {
  required_providers {
    avi = {
      source  = "vmware/avi"
      version = "22.1.5"
    }
  }
}

provider "avi" {
  avi_username    = "admin"
  avi_password    = var.avi_current_password
  avi_controller  = var.avi_controller_ips[0]
  avi_tenant      = var.avi_tenant
  avi_version     = var.avi_version
  avi_api_timeout = 50
}


provider "vsphere" {
  vsphere_server = var.vcenter_url
  user           = var.vcenter_username
  password       = var.vcenter_password
  allow_unverified_ssl = true
}