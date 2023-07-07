variable "avi_controller_ips" {
  default = ["192.168.100.58"]
}

variable "avi_dns_server_ips" {
    default = "192.168.100.1"
}

variable "avi_license" {
  default = "ENTERPRISE"
}
variable "avi_default_license_tier" {
  default = "ENTERPRISE"
}

variable "avi_username" {
  type    = string
  default = "admin"
}

variable "avi_current_password" {
  default = "58NFaGDJm(PJH0G"
}

variable "avi_password" {
  type    = string
  default = "VMware1!"
}

variable "avi_version" {
  type    = string
  default = "22.1.3"
}

variable "avi_tenant" {
  default = "admin"
}

variable "cloud_name" {
  type    = string
  default = "Default-Cloud"
}

variable "vcenter_vcenter_url" {
  type    = string
  default = "192.168.100.50"
}

variable "vcenter_username" {
  type    = string
  default = "administrator@vsphere.local"
}

variable "vcenter_password" {
  type    = string
  default = "VMware1!"
}

variable "vcenter_datacenter" {
  type    = string
  default = ""
}

variable "vcenter_management_network" {
  type    = string
  default = ""
}

variable "vcenter_privilege" {
  type    = string
  default = "WRITE_ACCESS"
}

variable "search_domain" {
  default = "env1.lab.test"
}
