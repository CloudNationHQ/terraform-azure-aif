data "azurerm_client_config" "current" {}

resource "azapi_resource" "this" {
  location = coalesce(
    var.config.location, var.location
  )

  tags = coalesce(
    var.config.tags, var.tags
  )

  name = var.config.name

  identity {
    type         = var.config.identity.type
    identity_ids = var.config.identity.identity_ids
  }

  body = {
    kind = var.config.kind
    properties = {
      allowProjectManagement        = var.config.allow_project_management
      customSubDomainName           = var.config.custom_subdomain_name
      disableLocalAuth              = var.config.disable_local_auth
      publicNetworkAccess           = var.config.public_network_access
      restrictOutboundNetworkAccess = var.config.restrict_outbound_network_access
    }
    sku = {
      name = var.config.sku_name
    }
  }

  type                      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  parent_id                 = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${coalesce(var.config.resource_group_name, var.resource_group_name)}"
  schema_validation_enabled = false
  response_export_values    = ["*"]
}

resource "azurerm_role_assignment" "this" {
  principal_id = coalesce(
    var.config.role_assignment.principal_id, data.azurerm_client_config.current.object_id
  )

  scope                                  = azapi_resource.this.id
  role_definition_name                   = var.config.role_assignment.role_definition_name
  role_definition_id                     = var.config.role_assignment.role_definition_id
  principal_type                         = var.config.role_assignment.principal_type
  name                                   = var.config.role_assignment.name
  description                            = var.config.role_assignment.description
  condition                              = var.config.role_assignment.condition
  condition_version                      = var.config.role_assignment.condition_version
  delegated_managed_identity_resource_id = var.config.role_assignment.delegated_managed_identity_resource_id
  skip_service_principal_aad_check       = var.config.role_assignment.skip_service_principal_aad_check
}

resource "azapi_resource" "project" {
  for_each = lookup(
    var.config, "projects", {}
  )

  name = coalesce(
    each.value.name, each.key
  )

  location = coalesce(
    each.value.location, var.config.location, var.location
  )

  tags = coalesce(
    each.value.tags, var.config.tags, var.tags
  )

  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.identity_ids
  }

  body = {
    properties = {
      displayName = each.value.display_name
      description = each.value.description
    }
  }

  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  parent_id                 = azapi_resource.this.id
  schema_validation_enabled = false
  response_export_values    = ["*"]

  depends_on = [azurerm_role_assignment.this]
}


resource "azapi_resource" "connection" {
  for_each = lookup(
    var.config, "connections", {}
  )

  name = coalesce(
    each.value.name, each.key
  )

  body = {
    properties = {
      category = each.value.category
      target   = each.value.target
      authType = each.value.auth_type
      metadata = each.value.metadata
    }
  }

  type                      = "Microsoft.CognitiveServices/accounts/connections@2025-04-01-preview"
  parent_id                 = azapi_resource.this.id
  schema_validation_enabled = false
}

resource "azapi_resource" "capability_host" {
  for_each = var.config.capability_host != null ? { this = var.config.capability_host } : {}

  name = coalesce(
    each.value.name, "default"
  )

  body = {
    properties = {
      capabilityHostKind       = each.value.capability_host_kind
      storageConnections       = each.value.storage_connections
      threadStorageConnections = each.value.thread_storage_connections
      vectorStoreConnections   = each.value.vector_store_connections
    }
  }

  type                      = "Microsoft.CognitiveServices/accounts/capabilityHosts@2025-04-01-preview"
  parent_id                 = azapi_resource.this.id
  schema_validation_enabled = false

  depends_on = [azapi_resource.connection]
}

resource "azapi_resource" "project_connection" {
  for_each = merge([
    for pk, p in lookup(var.config, "projects", {}) : {
      for ck, c in lookup(p, "connections", {}) :
      "${pk}.${ck}" => merge(c, { project_key = pk })
    }
  ]...)

  name = coalesce(
    each.value.name, element(split(".", each.key), 1)
  )

  body = {
    properties = {
      category = each.value.category
      target   = each.value.target
      authType = each.value.auth_type
      metadata = each.value.metadata
    }
  }

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  parent_id                 = azapi_resource.project[each.value.project_key].id
  schema_validation_enabled = false
}


resource "azapi_resource" "project_capability_host" {
  for_each = {
    for pk, p in lookup(var.config, "projects", {}) :
    pk => p.capability_host if p.capability_host != null
  }

  name = coalesce(
    each.value.name, "default"
  )

  body = {
    properties = {
      capabilityHostKind       = each.value.capability_host_kind
      storageConnections       = each.value.storage_connections
      threadStorageConnections = each.value.thread_storage_connections
      vectorStoreConnections   = each.value.vector_store_connections
    }
  }

  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  parent_id                 = azapi_resource.project[each.key].id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.capability_host,
    azapi_resource.project_connection,
    azurerm_role_assignment.project_connection
  ]
}

resource "azurerm_role_assignment" "project_connection" {
  for_each = merge([
    for pk, p in lookup(var.config, "projects", {}) : merge([
      for ck, c in lookup(p, "connections", {}) : {
        for role in c.role_assignments.definitions :
        "${pk}.${ck}.${role}" => {
          project_key    = pk
          scope          = try(c.metadata.ResourceId, c.metadata.resourceId)
          role           = role
          principal_type = c.role_assignments.principal_type
        }
      }
      if length(c.role_assignments.definitions) > 0 && (contains(keys(c.metadata), "ResourceId") || contains(keys(c.metadata), "resourceId"))
    ]...) if p.capability_host != null
  ]...)

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azapi_resource.project[each.value.project_key].identity[0].principal_id
  principal_type       = each.value.principal_type
}
