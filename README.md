# AI Foundry

This terraform module simplifies the creation and management of azure ai foundry resources, providing customizable options for accounts, projects, connections, and capability hosts, all managed through code.

## Features

Creates Azure AI Foundry accounts with configurable networking and authentication options.

Supports managed identities for both accounts and projects.

Provides account-level and project-level connections for storage, cosmosdb, and cognitive search.

Enables capability host configuration for agent services at both account and project level.

Automatically assigns required data plane roles for project connections when capability hosts are configured.

Supports private endpoint integration for secure connectivity.

Utilization of terratest for robust validation.

> **Note:** This module uses the azapi provider because `azurerm_ai_foundry` creates `Microsoft.MachineLearningServices/workspaces` (the legacy ML workspace model), while the new Foundry model uses `Microsoft.CognitiveServices/accounts` with `allowProjectManagement = true`. Only the CognitiveServices-based model supports connections and capability hosts. Tracking issue: [hashicorp/terraform-provider-azurerm#31820](https://github.com/hashicorp/terraform-provider-azurerm/issues/31820).

> **Known issue:** The Azure CognitiveServices API does not support parallel modifications to resources under the same project. Destroying multiple project connections simultaneously may fail with an etag conflict (409). Re-running the destroy resolves this.

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azapi_resource.capability_host](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.connection](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.project](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.project_capability_host](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.project_connection](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_role_assignment.project_connection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

## Required Inputs

The following input variables are required:

### <a name="input_config"></a> [config](#input\_config)

Description: n/a

Type:

```hcl
object({
    name                             = string
    resource_group_name              = optional(string)
    location                         = optional(string)
    tags                             = optional(map(string))
    kind                             = optional(string, "AIServices")
    custom_subdomain_name            = string
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
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_location"></a> [location](#input\_location)

Description: default azure region to be used.

Type: `string`

Default: `null`

### <a name="input_naming"></a> [naming](#input\_naming)

Description: contains naming convention

Type: `map(string)`

Default: `{}`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: default resource group to be used.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: tags to be added to the resources

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_account"></a> [account](#output\_account)

Description: contains all exported attributes of the ai foundry account

### <a name="output_capability_host"></a> [capability\_host](#output\_capability\_host)

Description: contains all exported attributes of the account capability host

### <a name="output_connections"></a> [connections](#output\_connections)

Description: contains all exported attributes of the account connections

### <a name="output_project_capability_hosts"></a> [project\_capability\_hosts](#output\_project\_capability\_hosts)

Description: contains all exported attributes of the project capability hosts

### <a name="output_project_connections"></a> [project\_connections](#output\_project\_connections)

Description: contains all exported attributes of the project connections

### <a name="output_projects"></a> [projects](#output\_projects)

Description: contains all exported attributes of the ai foundry projects
<!-- END_TF_DOCS -->

## Goals

For more information, please see our [goals and non-goals](./GOALS.md).

## Testing

For more information, please see our testing [guidelines](./TESTING.md)

## Notes

Using a dedicated module, we've developed a naming convention for resources that's based on specific regular expressions for each type, ensuring correct abbreviations and offering flexibility with multiple prefixes and suffixes.

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory.

To update the module's documentation run `make doc`

## Contributors

We welcome contributions from the community! Whether it's reporting a bug, suggesting a new feature, or submitting a pull request, your input is highly valued.

For more information, please see our contribution [guidelines](./CONTRIBUTING.md). <br><br>

<a href="https://github.com/cloudnationhq/terraform-azure-aif/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=cloudnationhq/terraform-azure-aif" />
</a>

## License

MIT Licensed. See [LICENSE](https://github.com/cloudnationhq/terraform-azure-aif/blob/main/LICENSE) for full details.

## References

- [Documentation](https://learn.microsoft.com/azure/ai-foundry/)
- [Rest Api](https://learn.microsoft.com/rest/api/cognitiveservices/)
- [Rest Api Specs](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices)
