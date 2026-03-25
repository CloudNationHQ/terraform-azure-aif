variable "config" {
  type = object({
    name                             = string
    resource_group_name              = optional(string)
    location                         = optional(string)
    tags                             = optional(map(string))
    kind                             = optional(string, "AIServices")
    custom_subdomain_name            = optional(string)
    allow_project_management         = optional(bool, true)
    sku_name                         = optional(string, "S0")
    disable_local_auth               = optional(bool, false)
    public_network_access            = optional(string, "Enabled")
    restrict_outbound_network_access = optional(bool, false)
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string))
    }), {})
    role_assignment = optional(object({
      role_definition_name                   = optional(string, "Azure AI Developer")
      role_definition_id                     = optional(string)
      scope                                  = optional(string)
      principal_id                           = optional(string)
      principal_type                         = optional(string)
      name                                   = optional(string)
      description                            = optional(string)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      skip_service_principal_aad_check       = optional(bool)
    }), {})
    connections = optional(map(object({
      name      = optional(string)
      category  = string
      target    = string
      auth_type = optional(string, "AAD")
      metadata  = optional(map(string), {})
    })), {})
    capability_host = optional(object({
      name                       = optional(string)
      capability_host_kind       = optional(string, "Agents")
      storage_connections        = optional(list(string), [])
      thread_storage_connections = optional(list(string), [])
      vector_store_connections   = optional(list(string), [])
    }))
    projects = optional(map(object({
      name         = optional(string)
      display_name = optional(string)
      description  = optional(string)
      location     = optional(string)
      tags         = optional(map(string))
      identity = optional(object({
        type         = optional(string, "SystemAssigned")
        identity_ids = optional(list(string))
      }), {})
      connections = optional(map(object({
        name      = optional(string)
        category  = string
        target    = string
        auth_type = optional(string, "AAD")
        metadata  = optional(map(string), {})
        role_assignments = optional(object({
          definitions    = optional(list(string), [])
          principal_type = optional(string, "ServicePrincipal")
        }), {})
      })), {})
      capability_host = optional(object({
        name                       = optional(string)
        capability_host_kind       = optional(string, "Agents")
        storage_connections        = optional(list(string), [])
        thread_storage_connections = optional(list(string), [])
        vector_store_connections   = optional(list(string), [])
      }))
    })), {})
  })

  validation {
    condition     = var.config.location != null || var.location != null
    error_message = "location must be provided either in the config object or as a separate variable."
  }

  validation {
    condition     = var.config.resource_group_name != null || var.resource_group_name != null
    error_message = "resource group name must be provided either in the config object or as a separate variable."
  }
}

variable "location" {
  description = "default azure region to be used."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "default resource group to be used."
  type        = string
  default     = null
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = map(string)
  default     = {}
}
