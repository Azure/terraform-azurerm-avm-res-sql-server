locals {
  resource_group_name = split("/", var.sql_server.resource_id)[4]
  sql_server_name     = split("/", var.sql_server.resource_id)[8]
}

locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}