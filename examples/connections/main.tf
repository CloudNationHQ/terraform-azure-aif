module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.26"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 2.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "swedencentral"
    }
  }
}

module "storage" {
  source  = "cloudnationhq/sa/azure"
  version = "~> 4.0"

  storage = {
    name                = module.naming.storage_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "cosmosdb" {
  source  = "cloudnationhq/cosmosdb/azure"
  version = "~> 4.0"

  account = {
    name                = module.naming.cosmosdb_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    kind                = "GlobalDocumentDB"
    capabilities        = ["EnableServerless"]

    geo_location = {
      primary = {
        location          = module.rg.groups.demo.location
        failover_priority = 0
      }
    }
  }
}

module "search" {
  source  = "cloudnationhq/srch/azure"
  version = "~> 1.0"

  config = {
    name                = module.naming.search_service.name_unique
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    sku                 = "standard"
  }
}

module "foundry" {
  source  = "cloudnationhq/aif/azure"
  version = "~> 1.0"

  location            = module.rg.groups.demo.location
  resource_group_name = module.rg.groups.demo.name

  config = {
    name                  = "aif-${module.naming.cognitive_account.name_unique}"
    custom_subdomain_name = "aif-${module.naming.cognitive_account.name_unique}"

    capability_host = {
      capability_host_kind = "Agents"
    }

    projects = {
      agent-project = {
        display_name = "Agent Project"
        description  = "Project with agent service enabled"

        connections = {
          storage = {
            category = "AzureStorageAccount"
            target   = module.storage.account.primary_blob_endpoint
            role_assignments = {
              definitions = ["Storage Blob Data Contributor"]
            }
            metadata = {
              ApiType    = "Azure"
              ResourceId = module.storage.account.id
              location   = module.rg.groups.demo.location
            }
          }
          cosmosdb = {
            category = "CosmosDb"
            target   = module.cosmosdb.account.endpoint
            role_assignments = {
              definitions = ["Cosmos DB Operator"]
            }
            metadata = {
              ApiType    = "Azure"
              ResourceId = module.cosmosdb.account.id
              location   = module.rg.groups.demo.location
            }
          }
          search = {
            category = "CognitiveSearch"
            target   = "https://${module.search.search_service.name}.search.windows.net"
            role_assignments = {
              definitions = [
                "Search Index Data Contributor",
                "Search Service Contributor"
              ]
            }
            metadata = {
              ApiType    = "Azure"
              ApiVersion = "2024-05-01-preview"
              ResourceId = module.search.search_service.id
              location   = module.rg.groups.demo.location
            }
          }
        }

        capability_host = {
          storage_connections        = ["storage"]
          thread_storage_connections = ["cosmosdb"]
          vector_store_connections   = ["search"]
        }
      }
    }
  }
}
