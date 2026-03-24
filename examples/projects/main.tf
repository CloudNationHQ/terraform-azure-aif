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
    name                  = module.naming.cognitive_account.name_unique
    custom_subdomain_name = module.naming.cognitive_account.name_unique

    projects = {
      ml-project = {
        display_name = "ML Project"
        description  = "Machine learning project"
      }
      data-project = {
        display_name = "Data Project"
        description  = "Data analytics project"
      }
    }
  }
}
