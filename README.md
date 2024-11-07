# External Secrets Demo

## Project Overview

This repository demonstrates how to inject secrets into a Kubernetes environment from three different secret management platforms:

- **HashiCorp Vault**
- **AWS Secrets Manager**
- **Azure Key Vault**

We use the **External Secrets Operator (ESO)** to synchronize secrets from these external providers into Kubernetes secrets, enabling secure and seamless secret management for your applications.

## Project Purpose

The purpose of this project is to provide a practical example of integrating external secret management systems with Kubernetes using ESO. By following this guide, you will learn how to:

- Set up each secret management provider using Terraform.
- Configure ESO to communicate with each provider.
- Inject secrets into your Kubernetes cluster securely.

## Project Structure

```
external-secrets-demo/
├── README.md                    # Project overview, purpose, structure, and usage
├── vault/
│   ├── terraform/
│   │   ├── main.tf              # Terraform script for Vault setup
│   │   ├── ca.crt               # Kubernetes CA certificate
│   │   └── sa_token.txt         # Service Account token for Kubernetes auth
│   ├── k8s-manifests/
│   │   ├── secret-store.yaml    # SecretStore configuration for Vault
│   │   └── external-secret.yaml # ExternalSecret configuration to sync Vault secrets to Kubernetes
├── aws-secret-manager/
│   ├── terraform/
│   │   └── main.tf              # Terraform script for AWS Secrets Manager setup
│   ├── k8s-manifests/
│   │   ├── secret-store.yaml    # SecretStore configuration for AWS Secrets Manager
│   │   └── external-secret.yaml # ExternalSecret configuration to sync AWS secrets to Kubernetes
├── azure-key-vault/
│   ├── terraform/
│   │   └── main.tf              # Terraform script for Azure Key Vault setup
│   ├── k8s-manifests/
│   │   ├── secret-store.yaml    # SecretStore configuration for Azure Key Vault
│   │   └── external-secret.yaml # ExternalSecret configuration to sync Azure Key Vault secrets to Kubernetes
└── .gitignore                   # Ignore sensitive files, Terraform state, etc.

```