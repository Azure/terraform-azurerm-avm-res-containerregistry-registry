module "tasks" {
  source   = "./modules/task"
  for_each = var.tasks

  container_registry_id = azurerm_container_registry.this.id
  task                  = each.value

  depends_on = [
    azurerm_container_registry_agent_pool.this
  ]
}
