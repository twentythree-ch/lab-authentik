
terraform {
  required_providers {
    portainer = {
      source  = "portainer/portainer"
      version = ">= 1.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }

  backend "azurerm" {
    # Configuration provided via -backend-config during init
  }
}

provider "portainer" {
  endpoint        = var.portainer_url
  api_key         = var.portainer_token
  skip_ssl_verify = true  # Required if using self-signed certs
}

# Trigger resource to detect git commit changes
resource "null_resource" "git_change_trigger" {
  triggers = {
    git_sha = var.git_sha
  }
}

# Deploy stack from Git repository using the Portainer provider
resource "portainer_stack" "app" {
  name            = var.stack_name
  deployment_type = "standalone"
  method          = "repository"
  endpoint_id     = tonumber(var.portainer_endpoint_id)

  # Git repository configuration
  repository_url                = "https://github.com/${var.github_repository}"
  repository_reference_name     = "refs/heads/${var.git_branch}"
  file_path_in_repository       = var.compose_file_path
  git_repository_authentication = true
  repository_username           = var.github_username
  repository_password           = var.github_pat

  # Stack behavior
  pull_image   = true
  force_update = true

  # Environment variables for the stack
  env {
    name  = "CLOUDFLARE_TUNNEL_TOKEN"
    value = var.cloudflare_tunnel_token
  }

  env {
    name  = "PG_PASS"
    value = var.pg_pass
  }

  env {
    name  = "PG_USER"
    value = var.pg_user
  }

  env {
    name  = "PG_DB"
    value = var.pg_db
  }

  env {
    name  = "AUTHENTIK_SECRET_KEY"
    value = var.authentik_secret_key
  }

  env {
    name  = "AUTHENTIK_BOOTSTRAP_PASSWORD"
    value = var.authentik_bootstrap_password
  }

  env {
    name  = "AUTHENTIK_IMAGE"
    value = var.authentik_image
  }

  env {
    name  = "AUTHENTIK_TAG"
    value = var.authentik_tag
  }

  env {
    name  = "DATA_PATH"
    value = "${var.data_path}/${var.stack_name}"
  }

  # SMTP / Email environment variables (passed through to the stack)
  env {
    name  = "EMAIL_HOST"
    value = var.email_host
  }

  env {
    name  = "EMAIL_PORT"
    value = var.email_port
  }

  env {
    name  = "EMAIL_HOST_USER"
    value = var.email_host_user
  }

  env {
    name  = "EMAIL_HOST_PASSWORD"
    value = var.email_host_password
  }

  env {
    name  = "EMAIL_USE_TLS"
    value = var.email_use_tls ? "true" : "false"
  }

  env {
    name  = "EMAIL_USE_SSL"
    value = var.email_use_ssl ? "true" : "false"
  }

  env {
    name  = "DEFAULT_FROM_EMAIL"
    value = var.default_from_email
  }

  # Authentik nested-setting equivalents
  env {
    name  = "AUTHENTIK_EMAIL__HOST"
    value = var.email_host
  }

  env {
    name  = "AUTHENTIK_EMAIL__PORT"
    value = var.email_port
  }

  env {
    name  = "AUTHENTIK_EMAIL__HOST_USER"
    value = var.email_host_user
  }

  env {
    name  = "AUTHENTIK_EMAIL__HOST_PASSWORD"
    value = var.email_host_password
  }

  env {
    name  = "AUTHENTIK_EMAIL__USE_TLS"
    value = var.email_use_tls ? "true" : "false"
  }

  env {
    name  = "AUTHENTIK_EMAIL__USE_SSL"
    value = var.email_use_ssl ? "true" : "false"
  }

  env {
    name  = "AUTHENTIK_EMAIL__DEFAULT_FROM_EMAIL"
    value = var.default_from_email
  }

  # Force update when git commit changes
  depends_on = [null_resource.git_change_trigger]
}

output "stack_id" {
  description = "ID of the deployed Portainer stack"
  value       = portainer_stack.app.id
}
