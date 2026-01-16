variable "environment" {
  description = "Deployment environment (development|production)"
  type        = string
}

variable "portainer_url" {
  description = "Portainer base URL (e.g. https://portainer.example.com)"
  type        = string
}

variable "portainer_token" {
  description = "Portainer API token"
  type        = string
  sensitive   = true
}

variable "portainer_endpoint_id" {
  description = "Portainer endpoint ID where the stack will be deployed"
  type        = string
}

variable "stack_name" {
  description = "Name of the Portainer stack"
  type        = string
}

variable "compose_file_path" {
  description = "Path to the docker-compose file within the repo"
  type        = string
}

variable "git_branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
}

variable "github_username" {
  description = "GitHub username for repository authentication"
  type        = string
}

variable "github_pat" {
  description = "GitHub Personal Access Token for repository authentication"
  type        = string
  sensitive   = true
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token"
  type        = string
  sensitive   = true
}

variable "pg_pass" {
  description = "PostgreSQL database password (maps to PG_PASS in compose)"
  type        = string
  sensitive   = true
}

variable "pg_user" {
  description = "PostgreSQL user (maps to PG_USER in compose)"
  type        = string
  default     = "authentik"
}

variable "pg_db" {
  description = "PostgreSQL database name (maps to PG_DB in compose)"
  type        = string
  default     = "authentik"
}

variable "authentik_secret_key" {
  description = "AUTHENTIK_SECRET_KEY for the Authentik server"
  type        = string
  sensitive   = true
}

variable "authentik_bootstrap_password" {
  description = "Optional bootstrap password for initial Authentik admin"
  type        = string
  sensitive   = true
  default     = ""
}

variable "authentik_image" {
  description = "Auth server image (overrides default)"
  type        = string
  default     = ""
}

variable "authentik_tag" {
  description = "Auth server image tag (overrides default)"
  type        = string
  default     = ""
}

variable "data_path" {
  description = "Host data base path (maps to DATA_PATH)"
  type        = string
  default     = "/data"
}

variable "git_sha" {
  description = "Git commit SHA to trigger updates when code changes"
  type        = string
  default     = ""
}
