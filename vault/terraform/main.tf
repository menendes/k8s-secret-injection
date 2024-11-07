#################################
# Providers
#################################

# Helm Provider to install Vault via Helm
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"  # Adjust if you're using a different kubeconfig
  }
}

# Kubernetes Provider
provider "kubernetes" {
  config_path = "~/.kube/config"  # Adjust if you're using a different kubeconfig
}

# Vault Provider
provider "vault" {
  address    = "http://${var.minikube_ip}:${data.kubernetes_service.vault_service.spec.ports[0].node_port}"
  token      = vault_operator_init.vault_init.root_token
}

provider "vault" {
  alias   = "init"
  address = "http://${var.minikube_ip}:${data.kubernetes_service.vault_service.spec.ports[0].node_port}"
}

provider "vault" {
  alias   = "unseal"
  address = "http://${var.minikube_ip}:${data.kubernetes_service.vault_service.spec.ports[0].node_port}"
}

#################################
# Variables
#################################

# Define the Minikube Kubernetes host
variable "kubernetes_host" {
  description = "The Kubernetes API server address"
  default     = "https://10.96.0.1:443"
}

variable "minikube_ip" {
  description = "The IP address of the Minikube cluster"
  default     = "192.168.49.2"  # Replace with your Minikube IP
}
#################################
# Resources
#################################

# Install Vault via Helm using your values.yaml
resource "helm_release" "vault" {
  name       = "vault"
  namespace  = "vault"  # Change if deploying to a different namespace
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.28.1"  # Specify the chart version

  values = [file("helm-vault-raft-values.yaml")]
}

# Get the Vault Service details
data "kubernetes_service" "vault_service" {
  metadata {
    name      = helm_release.vault.name
    namespace = helm_release.vault.namespace
  }
  depends_on = [helm_release.vault]
}


# Initialize Vault
resource "vault_operator_init" "vault_init" {
  provider = vault.init

  # Ensure Vault is available before initializing
  depends_on = [data.kubernetes_service.vault_service]

  recovery_shares    = 1
  recovery_threshold = 1

  # Store unseal keys and root token (for demonstration purposes; secure this in production)
  plaintext_backup = true
}

# Unseal Vault
resource "vault_operator_unseal" "vault_unseal" {
  provider = vault.unseal

  depends_on = [vault_operator_init.vault_init]

  # Use the unseal key from initialization
  key = vault_operator_init.vault_init.unseal_keys[0]
}

# Wait for Vault to be unsealed and ready
resource "null_resource" "wait_for_vault" {
  depends_on = [vault_operator_unseal.vault_unseal]

  provisioner "local-exec" {
    command = "sleep 15"  # Adjust the sleep time as needed
  }
}

# Enable the KV secrets engine at the path `secret/`
resource "vault_mount" "kv" {
  depends_on = [null_resource.wait_for_vault]

  path    = "secret"
  type    = "kv"
  options = {
    version = "2"
  }
}

# Store a secret in Vault
resource "vault_kv_secret_v2" "webapp_config" {
  depends_on = [vault_mount.kv]

  mount = vault_mount.kv.path

  # Define the secret path
  name = "webapp/config"  # Specify the name for the secret path

  # Secret data
  data_json = jsonencode({
    username = "example-username"
    password = "example-password"
  })
}

# Enable Kubernetes authentication in Vault
resource "vault_auth_backend" "kubernetes" {
  depends_on = [null_resource.wait_for_vault]

  type = "kubernetes"
  path = "auth/kubernetes"
}

# Configure Kubernetes auth method using the environment variable for Kubernetes host
resource "vault_kubernetes_auth_backend_config" "k8s_auth" {
  depends_on = [vault_auth_backend.kubernetes]

  backend             = vault_auth_backend.kubernetes.path
  kubernetes_host     = var.kubernetes_host
  kubernetes_ca_cert  = file("ca.crt")      # Path to the downloaded CA certificate
  token_reviewer_jwt  = file("sa_token.txt")  # Path to the service account token
}

# Create a policy to allow reading the webapp secret
resource "vault_policy" "eso_policy" {
  name   = "eso-policy"
  policy = <<EOT
path "secret/data/webapp/config" {
  capabilities = ["read"]
}
EOT
}

# Create a Kubernetes role for ESO with the policy
resource "vault_kubernetes_auth_backend_role" "eso_role" {
  depends_on = [vault_kubernetes_auth_backend_config.k8s_auth, vault_policy.eso_policy]

  backend                            = vault_auth_backend.kubernetes.path
  role_name                          = "eso-role"
  bound_service_account_names        = ["user-ihk"]
  bound_service_account_namespaces   = ["default"]
  token_policies                     = [vault_policy.eso_policy.name]
}

#################################
# Outputs
#################################

output "vault_root_token" {
  value       = vault_operator_init.vault_init.root_token
  description = "Root token for Vault"
}

output "vault_unseal_keys" {
  value       = vault_operator_init.vault_init.unseal_keys
  description = "Unseal keys for Vault"
}
