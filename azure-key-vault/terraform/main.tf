# Configure the Azure Resource Manager provider
provider "azurerm" {
  features {}
}

# Configure the Azure Active Directory provider, using tenant ID from azurerm_client_config
provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

# Retrieve the current Azure account configuration
data "azurerm_client_config" "current" {}

# Variables for resource names
variable "resource_group_name" {
  default = "rg-eso-demo"
}

# Replace it with your region
variable "location" {
  default = "West Europe"
}

variable "vault_name" {
  default = "kv-esodemo"
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create an Azure Key Vault, using tenant ID from data source
resource "azurerm_key_vault" "vault" {
  name                        = var.vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7

  # Access policy for the current user (for management purposes)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }
}

# Add secrets to the Key Vault
resource "azurerm_key_vault_secret" "example_secret" {
  name         = "webapp-username"
  value        = "azure-example-username"
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "example_password" {
  name         = "webapp-password"
  value        = "azure-example-password"
  key_vault_id = azurerm_key_vault.vault.id
}

# Create an Azure AD Application for ESO to access the Key Vault
resource "azuread_application" "eso_app" {
  display_name = "ESOServicePrincipal"
}

# Create a Service Principal for the application
resource "azuread_service_principal" "eso_sp" {
  client_id = azuread_application.eso_app.client_id
}

# Create a password (client secret) for the Service Principal
resource "azuread_application_password" "eso_app_password" {
  application_id = azuread_application.eso_app.id
}

# Assign Key Vault access to the Service Principal
resource "azurerm_key_vault_access_policy" "eso_kv_access" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_service_principal.eso_sp.object_id

  # Grant permissions for ESO to access secrets
  secret_permissions = ["Get", "List"]
}

# Output Service Principal credentials
output "client_id" {
  value = azuread_application.eso_app.client_id
}

output "client_secret" {
  value     = azuread_application_password.eso_app_password.value
  sensitive = true
}
