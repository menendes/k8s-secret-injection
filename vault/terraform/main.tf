provider "vault" {
  address = "http://192.168.49.2:32724" # Replace with the Vault address if different, in this case this ip represent my minikube ip
  token   = var.vault_token
}

# Define the Minikube Kubernetes host
variable "kubernetes_host" {
  description = "The Kubernetes API server address"
  default     = "https://10.96.0.1:443"
}

variable "vault_token" {
  description = "Vault root token"
  type        = string
  sensitive   = true
}

# Enable the KV secrets engine at the path secret/
resource "vault_mount" "kv" {
  path = "secret"
  type = "kv"
  options = {
    version = "2"
  }
}

# Store a secret in Vault
resource "vault_kv_secret_v2" "webapp_config" {
  mount = vault_mount.kv.path

  # Define the secret path
  name = "webapp/config" # Specify the name for the secret path

  # Secret data
  data_json = jsonencode({
    username = "example-username"
    password = "example-password"
  })
}

# Enable Kubernetes authentication in Vault
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "auth/kubernetes"
}

# Configure Kubernetes auth method using the environment variable for Kubernetes host
resource "vault_kubernetes_auth_backend_config" "k8s_auth" {
  backend             = vault_auth_backend.kubernetes.path
  kubernetes_host     = var.kubernetes_host
  kubernetes_ca_cert  = file("ca.crt")                # Path to the downloaded CA certificate
  token_reviewer_jwt  = file("sa_token.txt")          # Path to the service account token
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
  backend        = vault_auth_backend.kubernetes.path
  role_name      = "eso-role"
  bound_service_account_names = ["user-ihk"]
  bound_service_account_namespaces = ["default"]
  token_policies = [vault_policy.eso_policy.name]
}