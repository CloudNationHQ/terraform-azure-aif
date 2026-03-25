output "account" {
  description = "contains all exported attributes of the ai foundry account"
  value       = azapi_resource.this
}

output "deployments" {
  description = "contains all exported attributes of the deployments"
  value       = azapi_resource.deployment
}

output "policies" {
  description = "contains all exported attributes of the rai policies"
  value       = azapi_resource.policy
}

output "policy_deployments" {
  description = "contains all exported attributes of the policy-linked deployments"
  value       = azapi_resource.policy_deployment
}

output "projects" {
  description = "contains all exported attributes of the ai foundry projects"
  value       = azapi_resource.project
}

output "connections" {
  description = "contains all exported attributes of the account connections"
  value       = azapi_resource.connection
}

output "capability_host" {
  description = "contains all exported attributes of the account capability host"
  value       = azapi_resource.capability_host
}

output "project_connections" {
  description = "contains all exported attributes of the project connections"
  value       = azapi_resource.project_connection
}

output "project_capability_hosts" {
  description = "contains all exported attributes of the project capability hosts"
  value       = azapi_resource.project_capability_host
}
