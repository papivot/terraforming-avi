variable "avi_controller_ips" {
  default = ["192.168.100.58"]
}

variable "avi_dns_name" {
  default = "pacific-avi1.env1.lab.test"
}

variable "avi_dns_server_ips" {
    default = "192.168.100.1"
}

variable "avi_ntp_server_ips" {
  default = "10.188.26.119, 10.166.1.120"
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
  default = "22.1.5"
}

variable "cloud_name" {
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

variable "vcenter_cluster" {
  type    = string
  default = "Supervisor-Cluster"
}

variable "vcenter_vds"{
  type   = string
  default = "Pacific-VDS"
}

# Assumes management and VIP network on the same VDS
variable "vcenter_management_network" {
  type    = string
  default = "DVPG-Management-network"
}

# Assumes management and VIP network on the same VDS
variable "vcenter_vip_network" {
  type    = string
  default = "Workload0-VDS-PG"
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
