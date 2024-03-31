locals {
  default_labels = {
    terraform        = "true"
    terraform_module = basename(abspath(path.root))
  }
  service_accounts_map = {
    k8s-master-sa = ["vpc.publicAdmin", "k8s.clusters.agent", "editor"]
    k8s-ng-sa     = ["container-registry.images.puller", "container-registry.images.pusher", "kms.keys.encrypterDecrypter", "editor"]
  }
}

resource "random_id" "main" {
  byte_length = 4
}

module "service_accounts" {
  for_each = local.service_accounts_map

  source    = "git::https://github.com/agmtr/terraform-yandex-sa.git?ref=v1.0.0"
  folder_id = var.folder_id
  name      = each.key
  roles     = each.value
}

resource "yandex_kubernetes_cluster" "main" {
  name                     = var.name != null ? "${var.name}-${random_id.main.hex}" : "k8s-cluster-${random_id.main.hex}"
  description              = var.desc
  network_id               = var.network.id
  node_ipv4_cidr_mask_size = var.network.node_cidr_mask_size
  cluster_ipv4_range       = var.network.cluster_ip_range
  service_ipv4_range       = var.network.service_ip_range
  network_policy_provider  = var.network.calico ? "CALICO" : null
  dynamic "network_implementation" {
    for_each = var.network.cilium ? [1] : []
    content {
      cilium {
      }
    }
  }
  release_channel = var.config.release_channel
  kms_provider {
    key_id = var.config.kms_key_id
  }
  master {
    version            = var.config.version
    public_ip          = var.network.public_ip
    security_group_ids = var.network.security_group_ids
    dynamic "regional" {
      for_each = var.location.region != null ? [1] : []

      content {
        region = var.location.region
        dynamic "location" {
          for_each = var.location.zones != null ? var.location.zones : []

          content {
            zone = location.value
          }
        }
      }
    }
    dynamic "zonal" {
      for_each = var.location.region == null ? [1] : []
      content {
        zone = var.location.zone
      }
    }
    maintenance_policy {
      auto_upgrade = var.maintenance_policy.auto_upgrade
      dynamic "maintenance_window" {
        for_each = var.maintenance_policy.start_time != null ? [1] : []
        content {
          day        = var.maintenance_policy.day
          start_time = var.maintenance_policy.start_time
          duration   = var.maintenance_policy.duration
        }
      }
    }
  }
  service_account_id      = module.service_accounts.k8s-master-sa.id
  node_service_account_id = module.service_accounts.k8s-ng-sa.id

  labels = merge(local.default_labels, var.labels)

  lifecycle {
    precondition {
      condition     = var.network.calico == false || var.network.cilium == false
      error_message = "You must use only one of calico or cillium options"
    }
    precondition {
      condition     = var.network.cilium == false || (var.network.cilium == true && var.config.release_channel == "RAPID")
      error_message = "Cilium needs RAPID channel"
    }
  }
  depends_on = [
    module.service_accounts
  ]
}
