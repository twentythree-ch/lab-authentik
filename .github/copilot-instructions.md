# Copilot / AI Agent Instructions for lab-authentik

Summary
- Short: Docker Compose stack that runs Authentik (server + worker), PostgreSQL, and Cloudflared.
- Primary deploy target: Portainer (Git-backed stacks via Terraform).

What to know before editing
- The canonical compose file is `docker/docker-compose.yml` and expects host paths under `/data/lab-authentik-{environment}`.
- Environment variables are passed via Terraform/Portainer, not `.env` files on the host.

Architecture & important patterns
- Services:
  - `server`: Authentik server (`ghcr.io/goauthentik/server`) exposing ports 9000/9443.
  - `worker`: Authentik background worker (same image, `worker` command).
  - `postgresql`: `postgres:16-alpine` using a bind-mounted volume at `/data/lab-authentik-{environment}/db`.
  - `cloudflared`: Cloudflare Tunnel connecting the stack to the internet.
- Networks:
  - `internal`: internal bridge named `authentik` used for service-to-service communication.

Key operational details agents must respect
- Cloudflare Tunnel must be configured to target the Authentik server container (e.g., `http://server:9000`).
- Volumes are bind-mounted to `/data/lab-authentik-{environment}/*`. Any automation that migrates or backs up data should use these host paths.
- Environment variables (`PG_PASS`, `PG_USER`, `PG_DB`, `AUTHENTIK_SECRET_KEY`, `AUTHENTIK_BOOTSTRAP_PASSWORD`, `AUTHENTIK_IMAGE`, `AUTHENTIK_TAG`, `COMPOSE_PORT_HTTP`, `COMPOSE_PORT_HTTPS`, `DATA_PATH`, `CLOUDFLARE_TUNNEL_TOKEN`) are passed via Terraform to Portainer. Always reference `terraform/main.tf` and `terraform/variables.tf` when adding/removing envs.

Developer workflows & useful commands
- **CI/CD deployment**: GitHub Actions in `.github/workflows/` handle automated deployment via Terraform:
  - `deploy.yml`: main workflow triggered on push to `main` (production) or `develop` (development)
  - `_reusable-deploy-terraform-stack.yml`: reusable workflow handling Azure OIDC auth, Terraform init/plan/apply, and NetBird tunnel
  - Manual trigger: Actions → Deploy to Portainer → Run workflow (select environment)
  - Stack names: `lab-authentik-development`, `lab-authentik-production`
- **Terraform state**: Stored in Azure Blob Storage with OIDC authentication
- **Change detection**: Git commit SHA is passed to Terraform to trigger updates when compose files change
- Local/Portainer deploy: Use Portainer Stacks (Git or Web editor) as documented in README.md.
- Quick local bring-up (for debugging only):
  - Create host directories shown in README and set proper permissions.
  - `docker compose -f docker/docker-compose.yml up -d`
  - View logs: `docker compose -f docker/docker-compose.yml logs -f server worker postgresql cloudflared`
- Reset stack (destructive): `docker compose -f docker/docker-compose.yml down -v` (back up `/data/lab-authentik-{environment}` first).

Patterns and conventions to follow
- Infrastructure as Code: All deployment configuration is in Terraform (`terraform/` directory). Stack creation and updates go through the Portainer Terraform provider.
- Config-as-data: prefer editing Docker Compose files and Terraform variables rather than in-image changes.
- Security: secrets are passed via GitHub Actions secrets → Terraform → Portainer environment variables. Never commit secrets.
- Networking: services talk over `internal`.

Files to reference when changing behavior
- Compose and services: `docker/docker-compose.yml`
- Terraform configuration: `terraform/main.tf`, `terraform/variables.tf`
- GitHub Actions deployment: `.github/workflows/deploy.yml` and `.github/workflows/_reusable-deploy-terraform-stack.yml`
- High level instructions and Cloudflare notes: `README.md`

Examples (copy commands)
- Prepare host directories:
  mkdir -p /data/lab-authentik-development/{db,media,certs,templates}
  chmod -R 755 /data/lab-authentik-development
- Run locally for debug:
  docker compose -f docker/docker-compose.yml up -d

If something's unclear
- Ask for the intended deployment target (Portainer via Terraform vs. plain Docker) and whether the Cloudflared tunnel is configured correctly.

End of file
