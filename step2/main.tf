data "avi_tenant" "tenant" {
  name = var.avi_tenant
}

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
}
