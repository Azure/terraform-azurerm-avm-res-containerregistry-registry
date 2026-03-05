output "resource" {
  description = "This is the full output for the task resource."
  value       = azurerm_container_registry_task.this
}

output "resource_id" {
  description = "The resource ID of the Container Registry task."
  value       = azurerm_container_registry_task.this.id
}

output "schedule_run_now" {
  description = "The run-now schedule resource output when enabled, or null otherwise."
  value       = try(values(azurerm_container_registry_task_schedule_run_now.this)[0], null)
}
