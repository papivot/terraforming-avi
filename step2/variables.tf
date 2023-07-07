variable "avi_controller_ips" {
  default = ["192.168.100.58"]
}

variable "avi_dns_name" {
  default = "avi.env1.lab.test"
}

variable "avi_dns_server_ips" {
    default = "192.168.100.1"
}

variable "avi_ntp_server_ips" {
  default = "10.128.152.81, 10.62.4.1"
}

variable "avi_license" {
  default = "ENTERPRISE"
}

variable "avi_default_license_tier" {
  default = "ENTERPRISE"
}

variable "avi_current_password" {
  default = "58NFaGDJm(PJH0G"
}

variable "avi_tenant" {
  default = "admin"
}

variable "avi_username" {
  type    = string
  default = "admin"
}

variable "avi_password" {
  type    = string
  default = "VMware1!"
}

variable "avi_version" {
  type    = string
  default = "22.1.3"
}

variable "avi_cloud_name" {
  type    = string
  default = "Default-Cloud"
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
  default = "Pacific-Datacenter"
}

variable "vcenter_management_network" {
  type    = string
  default = "DVPG-Management-network"
}

variable "vcenter_privilege" {
  type    = string
  default = "WRITE_ACCESS"
}

variable "vcenter_url" {
  type    = string
  default = "192.168.100.50"
}

variable "banner" {
  default = "NSX ALB"
}

variable "search_domain" {
  default = "env1.lab.test"
}
