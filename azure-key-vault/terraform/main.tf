provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-external-secrets-demo"
  location = "<Your-Azure-Region>"
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                = "kv-external-secrets-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = "<Your-Azure-Tenant-ID>"

  sku_name = "standard"

  access_policy {
    tenant_id = "<Your-Azure-Tenant-ID>"
    object_id = "<Your-Service-Principal-Object-ID>"

    secret_permissions = [
      "get",
      "list",
    ]
  }
}

# Secret in Key Vault
resource "azurerm_key_vault_secret" "secret" {
  name         = "my-secret"
  value        = "super-secret-value"
  key_vault_id = azurerm_key_vault.kv.id
}

# Service Principal for ESO
resource "azurerm_application" "app" {
  name                       = "app-external-secrets-operator"
  available_to_other_tenants = false
}

resource "azurerm_application_password" "app_password" {
  application_object_id = azurerm_application.app.object_id
  value                 = "ChangeThisToASecurePassword"
  end_date_relative     = "8760h" # 1 year
}

resource "azurerm_service_principal" "sp" {
  application_id               = azurerm_application.app.application_id
  app_role_assignment_required = false
}

# Assign Key Vault permissions to the Service Principal
resource "azurerm_key_vault_access_policy" "sp_access_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = "<Your-Azure-Tenant-ID>"
  object_id    = azurerm_service_principal.sp.object_id

  secret_permissions = [
    "get",
    "list",
  ]
}

# Output the Service Principal credentials
output "client_id" {
  value = azurerm_application.app.application_id
}

output "client_secret" {
  value = azurerm_application_password.app_password.value
}

output "tenant_id" {
  value = "<Your-Azure-Tenant-ID>"
}

output "subscription_id" {
  value = "<Your-Azure-Subscription-ID>"
}