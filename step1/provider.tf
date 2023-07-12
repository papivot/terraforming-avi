terraform {
  required_providers {
    avi = {
      source  = "vmware/avi"
      version = var.avi_version
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
