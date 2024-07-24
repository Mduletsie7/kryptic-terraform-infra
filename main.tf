# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.113.0"
    } 
  }
    cloud {
  organization = "Mdumisi-dev"

  workspaces {
    name = "dev-kryptic-ws"
     }
    }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
 features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create a container registry
resource "azurerm_container_registry" "acr" {
  name                = "krypticRegistry1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "null_resource" "Docker_deploy_script" {
  provisioner "local-exec" {
    command = "chmod +x ${path.cwd}/../bash/deploy.sh; ${path.cwd}/../../bash/deploy.sh"
    interpreter = ["bash", "-c"]
  }
  depends_on = [ azurerm_container_registry.acr ]
}

# Create log analytics workspace
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "acr01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


# PROBLEMATIC SECTION 

# Create container app environment
resource "azurerm_container_app_environment" "aca_env" {
  name                       = "Example-Environment"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

# Create container app
resource "azurerm_container_app" "aca" {
  name                         = "kryptic-container-app"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "krypticRegistry1"
      image  = "krypticRegistry1.azurerc.io/azuredocs/krypticthadonbeats:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
  ingress {
    external_enabled           = true
    allow_insecure_connections = true
    target_port                = 3000
    transport                  = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }


}