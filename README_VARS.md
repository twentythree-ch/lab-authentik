# Deployment variables & secrets

This file documents the GitHub Actions Variables, Secrets, Terraform variables, and container environment variables required to deploy the Authentik stack via the reusable workflow (`.github/workflows/_reusable-deploy-terraform-stack.yml`).

**Where to set**:
- GitHub repository Settings → Actions → Variables (non-sensitive values)
- GitHub repository Settings → Actions → Secrets → Variables (sensitive values)
- Terraform variables can also be provided during `terraform apply` via `-var` flags or in your CI environment.

## GitHub Actions Variables (recommended)
- `EMAIL_HOST` — SMTP host (e.g. `smtp.example.com`)
- `EMAIL_PORT` — SMTP port (e.g. `587`)
- `EMAIL_HOST_USER` — SMTP username (e.g. `auth@example.com`)
- `EMAIL_USE_TLS` — `true` or `false` (STARTTLS)
- `EMAIL_USE_SSL` — `true` or `false` (SSL/TLS)
- `DEFAULT_FROM_EMAIL` — Default From address (e.g. `Authentik <auth@example.com>`)

Set these in the repository as Actions Variables so the reusable workflow can read them as inputs.

## GitHub Actions Secrets (required)
- `EMAIL_HOST_PASSWORD` — SMTP password (sensitive)

Also keep existing secrets already used by the workflow:
- `portainer_token` (Portainer API key)
- `gh_pat` (GitHub PAT for Portainer repository auth)
- `cloudflare_tunnel_token` (Cloudflare Tunnel token)
- `db_password` (Postgres password)
- `authentik_secret_key` (AUTHENTIK_SECRET_KEY)
- `authentik_bootstrap_password` (optional)
- `netbird_setup_key`, `ssh_private_key` (per workflow requirements)

## Terraform variables (defined in `terraform/variables.tf`)
These are the Terraform variable names exposed by the module and passed from the workflow:
- `email_host` (maps to `EMAIL_HOST`)
- `email_port` (maps to `EMAIL_PORT`)
- `email_host_user` (maps to `EMAIL_HOST_USER`)
- `email_host_password` (sensitive — maps to `EMAIL_HOST_PASSWORD`)
- `email_use_tls` (`true|false`)
- `email_use_ssl` (`true|false`)
- `default_from_email`

Other Terraform variables already in use (for reference):
- `cloudflare_tunnel_token`, `pg_pass`, `pg_user`, `pg_db`, `authentik_secret_key`, `authentik_bootstrap_password`, `authentik_image`, `authentik_tag`, `data_path`, `git_sha`, etc.

## Container environment variables (inside `docker/docker-compose.yml`)
The stack will be provided the following env vars (server and worker):
- `EMAIL_HOST`
- `EMAIL_PORT`
- `EMAIL_HOST_USER`
- `EMAIL_HOST_PASSWORD` (sensitive)
- `EMAIL_USE_TLS`
- `EMAIL_USE_SSL`
- `DEFAULT_FROM_EMAIL`

Additionally, the compose exposes Authentik nested-setting equivalents so the app reads them directly:
- `AUTHENTIK_EMAIL__HOST`, `AUTHENTIK_EMAIL__PORT`, `AUTHENTIK_EMAIL__HOST_USER`, `AUTHENTIK_EMAIL__HOST_PASSWORD`, `AUTHENTIK_EMAIL__USE_TLS`, `AUTHENTIK_EMAIL__USE_SSL`, `AUTHENTIK_EMAIL__DEFAULT_FROM_EMAIL`

## Example: adding values via the workflow call
When invoking the reusable workflow or running the Terraform commands locally, the workflow passes these values to Terraform; an example `terraform apply` snippet the workflow uses is:

```bash
terraform apply -var="email_host=smtp.example.com" \
  -var="email_port=587" \
  -var="email_host_user=auth@example.com" \
  -var="email_host_password=SUPERSECRET" \
  -var="email_use_tls=true" \
  -var="email_use_ssl=false" \
  -var="default_from_email='Authentik <auth@example.com>'" \
  ...other-vars...
```

In CI (recommended):
- Add non-sensitive values as Actions Variables.
- Add `EMAIL_HOST_PASSWORD` as an Actions Secret and ensure the reusable workflow has `secrets.email_host_password` configured (done in the workflow).

## Quick checklist
- [ ] Add Variables: `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_USE_TLS`, `EMAIL_USE_SSL`, `DEFAULT_FROM_EMAIL` (Actions → Variables)
- [ ] Add Secret: `EMAIL_HOST_PASSWORD` (Actions → Secrets)
- [ ] Ensure existing required secrets are present (`portainer_token`, `db_password`, `authentik_secret_key`, etc.)
- [ ] Trigger the deployment workflow (or run `terraform apply`) to propagate envs into the Portainer stack.

If you'd like, I can add this README to the repo (done), or create a small checklist PR that updates `.github/CONTRIBUTING.md` with these steps.
