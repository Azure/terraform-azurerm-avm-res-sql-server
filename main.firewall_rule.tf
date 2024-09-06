resource "azurerm_mssql_firewall_rule" "this" {
  for_each         = var.firewall_rules
  name             = each.key
  server_id        = azurerm_mssql_server.this[0].id
  end_ip_address   = each.value.end_ip_address
  start_ip_address = each.value.start_ip_address

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

