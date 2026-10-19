variable "creation_source_database_id" {
  type        = string
  default     = null
  description = "The resource ID of the source database for the point in time restore."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see<https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "restore_point_in_time" {
  type        = string
  default     = null
  description = "The point in time (ISO8601 format) to restore the database from. Required for PointInTimeRestore create mode."
}
