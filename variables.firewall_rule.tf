variable "firewall_rules" {
  type = map(object({
    end_ip_address   = string
    start_ip_address = string
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = {}
  description = <<-EOT
 - `end_ip_address` - (Required) Specifies the End IP Address associated with this Firewall Rule.
 - `start_ip_address` - (Required) Specifies the Start IP Address associated with this Firewall Rule.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the MySQL Firewall Rule.
 - `delete` - (Defaults to 30 minutes) Used when deleting the MySQL Firewall Rule.
 - `read` - (Defaults to 5 minutes) Used when retrieving the MySQL Firewall Rule.
 - `update` - (Defaults to 30 minutes) Used when updating the MySQL Firewall Rule.
EOT
}
