variable "init" {
  description = "Module init"
}
variable "vapp_name" {
  type = string
}
variable "catalog_name" {
  type    = string
  default = "bolsel"
}
variable "template_name" {
  type    = string
  default = "ubuntu-cloudimg"
}
variable "name" {
  type        = string
  description = "Nama VM"
}
variable "computer_name" {
  type    = string
  default = ""
}
variable "description" {
  type        = string
  description = "Deskripsi VM"
  default     = ""
}
variable "hostname" {
  type    = string
  default = ""
}

variable "memory" {
  type        = number
  default     = 2048
  description = "vm memory. default: 2048"
}

variable "cpus" {
  type        = number
  default     = 1
  description = "vm cpu. default: 1"
}

variable "expose_hardware_virtualization" {
  type    = bool
  default = false
}

variable "firmware" {
  type        = string
  default     = "efi"
  description = "efi or bios"
}

variable "hardware_version" {
  type    = string
  default = "vmx-19"
}

variable "template_disk_size" {
  type        = number
  default     = 0 # 10240 = 10GB 
  description = "jika 0 maka tidak template disk tidak dirubah"
}

variable "networks" {
  type = list(object({
    type               = optional(string, "org")
    adapter_type       = optional(string, "VMXNET3")
    name               = string
    ip_allocation_mode = optional(string, "DHCP")
    ip                 = optional(string, "")
    is_primary         = bool
  }))
}

variable "disks" {
  type = list(object({
    name        = string
    bus_number  = number
    unit_number = number
  }))
  default = []
}

variable "local_admin_username" {
  description = "local admin username."
  type        = string
  default     = "p1x"
}
variable "local_admin_password" {
  description = "local admin password"
  type        = string
}
variable "local_admin_authorized_key" {
  description = "local admin user authorized_key."
  type        = string
}

variable "automation_username" {
  description = "automation username."
  type        = string
  default     = "automation"
}

variable "automation_authorized_key" {
  description = "automation user authorized_key."
  type        = string
}

variable "power_on" {
  type    = bool
  default = true
}

variable "netplan_enabled" {
  type        = bool
  default     = true
  description = "enable netplan config"
}

variable "variables" {
  default = {}
}
