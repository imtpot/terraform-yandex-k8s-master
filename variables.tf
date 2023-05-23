variable "folder_id" {
  type = string
}

variable "name" {
  type    = string
  default = null
}

variable "desc" {
  type    = string
  default = null
}

variable "location" {
  type = object({
    region = optional(string)
    zone   = optional(string)
  })
  default = {
    zone = "ru-central1-a"
  }
}

variable "config" {
  type = object({
    version         = optional(string)
    release_channel = optional(string)
    kms_key_id      = optional(string)
  })
  default = {}
}

variable "network" {
  type = object({
    id                  = string
    security_group_ids  = optional(list(string))
    calico              = optional(bool, false)
    cilium              = optional(bool, false)
    public_ip           = optional(bool, true)
    node_cidr_mask_size = optional(string)
    cluster_ip_range    = optional(string)
    service_ip_range    = optional(string)
  })
}

variable "maintenance_policy" {
  type = object({
    auto_upgrade = optional(bool, true)
    day          = optional(string)
    start_time   = optional(string)
    duration     = optional(string)
  })
  default = {}
}

variable "labels" {
  type    = map(string)
  default = {}
}
