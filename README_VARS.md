# Deployment variables & secrets

This file documents the GitHub Actions Variables, Secrets, Terraform variables, and container environment variables required to deploy the Authentik stack via the reusable workflow (`.github/workflows/_reusable-deploy-terraform-stack.yml`).

Where to set
- GitHub repository Settings → Actions → Variables (non-sensitive values)
- GitHub repository Settings → Actions → Secrets → Variables (sensitive values)
- Terraform variables can also be provided during `terraform apply` via `-var` flags or in your CI environment.

Recommended GitHub Actions Variables (non-sensitive)
- `EMAIL_HOST` — SMTP host (e.g. `smtp.example.com`)
- `EMAIL_PORT` — SMTP port (e.g. `587`)
- `EMAIL_HOST_USER` — SMTP username (e.g. `auth@example.com`)
- `EMAIL_USE_TLS` — `true` or `false` (STARTTLS)
- `EMAIL_USE_SSL` — `true` or `false` (SSL/TLS)
- `EMAIL_TIMEOUT` — SMTP timeout in seconds (default `10`)
- `DEFAULT_FROM_EMAIL` — Default From address (e.g. `Authentik <auth@example.com>`)

Required GitHub Actions Secret
- `EMAIL_HOST_PASSWORD` — SMTP password (sensitive)

Also keep existing secrets required by the workflow:
- `PORTAINER_TOKEN`, `GH_PAT`, `CLOUDFLARE_TUNNEL_TOKEN`, `DB_PASSWORD`, `AUTHENTIK_SECRET_KEY`, `AUTHENTIK_BOOTSTRAP_PASSWORD`, `NETBIRD_SETUP_KEY`, `SSH_PRIVATE_KEY`.

Terraform variables (in `terraform/variables.tf`)
- `email_host` → maps from `EMAIL_HOST`
- `email_port` → maps from `EMAIL_PORT`
- `email_host_user` → maps from `EMAIL_HOST_USER`
- `email_host_password` (sensitive) → maps from `EMAIL_HOST_PASSWORD`
- `email_use_tls` → maps from `EMAIL_USE_TLS`
- `email_use_ssl` → maps from `EMAIL_USE_SSL`
- `email_timeout` → maps from `EMAIL_TIMEOUT` (number, default 10)
- `default_from_email` → maps from `DEFAULT_FROM_EMAIL`

Container environment variables (set in `docker/docker-compose.yml` via the Portainer stack)
These are provided to the `server` and `worker` services and include the documented Authentik keys:
- `AUTHENTIK_EMAIL__HOST`
- `AUTHENTIK_EMAIL__PORT`
- `AUTHENTIK_EMAIL__USERNAME`
- `AUTHENTIK_EMAIL__PASSWORD`
- `AUTHENTIK_EMAIL__USE_TLS`
- `AUTHENTIK_EMAIL__USE_SSL`
- `AUTHENTIK_EMAIL__TIMEOUT`
- `AUTHENTIK_EMAIL__FROM`

The stack also receives intermediate `EMAIL_*` environment variables from Terraform/CI which are mapped to the `AUTHENTIK_EMAIL__*` keys inside the compose file.

Example `.env` snippet (as recommended in the Authentik docs):

```env
# SMTP Host Emails are sent to
AUTHENTIK_EMAIL__HOST=localhost
AUTHENTIK_EMAIL__PORT=25
# Optionally authenticate (don't add quotation marks to your password)
AUTHENTIK_EMAIL__USERNAME=
AUTHENTIK_EMAIL__PASSWORD=
# Use StartTLS
AUTHENTIK_EMAIL__USE_TLS=false
# Use SSL
AUTHENTIK_EMAIL__USE_SSL=false
AUTHENTIK_EMAIL__TIMEOUT=10
# Email address authentik will send from, should have a correct @domain
AUTHENTIK_EMAIL__FROM=authentik@localhost
```

Example `terraform apply` (CI passes values via workflow; local example):

```bash
terraform apply -var="email_host=smtp.example.com" \
  -var="email_port=587" \
  -var="email_host_user=auth@example.com" \
  -var="email_host_password=SUPERSECRET" \
  -var="email_use_tls=true" \
  -var="email_use_ssl=false" \
  -var="email_timeout=10" \
  -var="default_from_email='Authentik <auth@example.com>'" \
  ...other-vars...
```

Quick checklist
- [ ] Add Variables: `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_USE_TLS`, `EMAIL_USE_SSL`, `EMAIL_TIMEOUT`, `DEFAULT_FROM_EMAIL` (Actions → Variables)
- [ ] Add Secret: `EMAIL_HOST_PASSWORD` (Actions → Secrets)
- [ ] Ensure other required secrets are present (`PORTAINER_TOKEN`, `DB_PASSWORD`, etc.)
- [ ] Trigger the deployment workflow (or run `terraform apply`) to propagate envs into the Portainer stack.

If you want, I can open a small PR that adds example (non-sensitive) variables to the repo or update `.github/CONTRIBUTING.md` with these steps.
