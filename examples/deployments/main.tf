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

module "foundry" {
  source  = "cloudnationhq/aif/azure"
  version = "~> 1.0"

  location            = module.rg.groups.demo.location
  resource_group_name = module.rg.groups.demo.name

  config = {
    name                  = module.naming.ai_foundry.name_unique
    custom_subdomain_name = module.naming.ai_foundry.name_unique

    deployments = {
      text-embedding = {
        model = {
          format  = "OpenAI"
          name    = "text-embedding-ada-002"
          version = "2"
        }
        sku = {
          name     = "Standard"
          capacity = 1
        }
      }
    }

    policies = {
      strict = {
        base_policy_name = "Microsoft.DefaultV2"
        mode             = "Asynchronous_filter"
        content_filters = {
          hate = {
            name               = "Hate"
            filter_enabled     = true
            block_enabled      = true
            severity_threshold = "High"
            source             = "Prompt"
          }
        }
        deployments = {
          gpt-4o-mini = {
            model = {
              format  = "OpenAI"
              name    = "gpt-4o-mini"
              version = "2024-07-18"
            }
            sku = {
              name     = "Standard"
              capacity = 1
            }
          }
          gpt-4o = {
            model = {
              format  = "OpenAI"
              name    = "gpt-4o"
              version = "2024-11-20"
            }
            sku = {
              name     = "Standard"
              capacity = 1
            }
          }
        }
      }
    }
  }
}
