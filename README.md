# lab-authentik

A Docker Compose stack running [Authentik](https://goauthentik.io/) (authentication & authorization server) with PostgreSQL and Cloudflare Tunnel, deployed via Portainer with environment configuration from Infisical.

## Overview

This repository contains:
- **Docker Compose stack** (`docker/docker-compose.yml`) defining Authentik server, worker, PostgreSQL database, and Cloudflare Tunnel
- **Environment templates** in `docker/.env.template` showing required configuration
- **GitOps integration** with Portainer for automatic deployment from repository changes

## Architecture

### Services

- **server**: Authentik authentication server (`ghcr.io/goauthentik/server:${AUTHENTIK_TAG}`) on ports 9000 (HTTP) and 9443 (HTTPS)
- **worker**: Authentik background worker for async tasks (same image, `worker` command)
- **postgresql**: PostgreSQL 16 Alpine database (`postgres:16-alpine`) with persistent volume
- **cloudflared**: Cloudflare Tunnel (`cloudflare/cloudflared:latest`) for secure internet bridging

### Networking

Services communicate over an internal bridge network named `authentik`. External access is via Cloudflare Tunnel.

### Volumes (Bind Mounts)

All volumes are bind-mounted from the host at `${DATA_PATH}`:
- `database`: PostgreSQL data at `${DATA_PATH}/db`
- `media`: Authentik media uploads at `${DATA_PATH}/media`
- `certs`: TLS certificates at `${DATA_PATH}/certs`
- `templates`: Custom templates at `${DATA_PATH}/templates`

## Deployment: Portainer + Infisical

### Prerequisites

1. **Portainer** running with GitOps support enabled
2. **Infisical** instance with Authentik application configured for two environments (development, production)
3. **Git repository** access from Portainer (this repository)
4. **Host directories** created at `/data/lab-authentik-{environment}` with proper permissions

### Installation Steps

#### 1. Prepare Host Directories

On the Docker host, create and permission the data directories:

```bash
# Development
mkdir -p /data/lab-authentik-development/{db,media,certs,templates}
chmod -R 755 /data/lab-authentik-development

# Production
mkdir -p /data/lab-authentik-production/{db,media,certs,templates}
chmod -R 755 /data/lab-authentik-production
```

#### 2. Configure Infisical

Set up the Authentik application in Infisical with two environments (Development, Production), each containing all required variables:

**Essential variables (always required):**
```
POSTGRES_DB=authentik
POSTGRES_USER=authentik
POSTGRES_PASSWORD=<secure_database_password>
AUTHENTIK_POSTGRESQL__NAME=authentik
AUTHENTIK_POSTGRESQL__USER=authentik
AUTHENTIK_POSTGRESQL__PASSWORD=<secure_database_password>
AUTHENTIK_SECRET_KEY=<secure_secret_key>
AUTHENTIK_BOOTSTRAP_PASSWORD=<initial_admin_password>
TUNNEL_TOKEN=<cloudflare_tunnel_token>
DATA_PATH=/data/lab-authentik-development
```

**Email configuration (optional, but recommended):**
```
AUTHENTIK_EMAIL__FROM=noreply@authentik.example.com
AUTHENTIK_EMAIL__HOST=smtp.gmail.com
AUTHENTIK_EMAIL__PORT=587
AUTHENTIK_EMAIL__USERNAME=your_email@gmail.com
AUTHENTIK_EMAIL__PASSWORD=<smtp_password>
AUTHENTIK_EMAIL__USE_TLS=true
AUTHENTIK_EMAIL__USE_SSL=false
AUTHENTIK_EMAIL__TIMEOUT=10

DEFAULT_FROM_EMAIL=noreply@authentik.example.com
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your_email@gmail.com
EMAIL_HOST_PASSWORD=<smtp_password>
EMAIL_USE_TLS=true
EMAIL_USE_SSL=false
EMAIL_TIMEOUT=10
```

**Optional variables** (use defaults if omitted):
```
AUTHENTIK_IMAGE=ghcr.io/goauthentik/server
AUTHENTIK_TAG=2025.10.3
```

Configure Infisical to mount/export these env files to the Docker host (typically at `/data/lab-authentik-{environment}/.env`).

#### 3. Create Portainer Stacks

In Portainer, create two stacks with GitOps enabled:

**Development Stack: `lab-authentik-development`**
1. Navigate to Stacks → Add Stack
2. **Git repository**: Point to this repository
3. **Compose file path**: `docker/docker-compose.yml`
4. **Enable GitOps**: Yes (auto-deploy on repo changes)
5. **Environment variables**:
   - `STACK_ENV_FILE`: `/data/lab-authentik-development/.env` (path to Infisical-generated env file)
   - `DATA_PATH`: `/data/lab-authentik-development`
   - `AUTHENTIK_TAG`: `2025.10.3` (or desired version)
6. Deploy

**Production Stack: `lab-authentik-production`**
Repeat above steps with:
- Environment variables pointing to `/data/lab-authentik-production`
- Stack name: `lab-authentik-production`

#### 4. Configure Cloudflare Tunnel

For each environment, configure a Cloudflare Tunnel:
1. Go to [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/) → Networks → Tunnels
2. Create/configure tunnel to target: `http://server:9000` (Authentik server service)
3. Obtain tunnel token and add to Infisical
4. Infisical generates token → mounts to host → stack reads via `CLOUDFLARE_TUNNEL_TOKEN`

**Note**: Both stacks share the full internet-facing setup; separate tunnels per environment or one shared tunnel are both supported depending on your infrastructure.

### Deployment Flow

```
Infisical (secrets management)
    ↓
    Generates env files → `/data/lab-authentik-{environment}/.env`
    ↓
Portainer (container orchestration)
    ↓
    Reads STACK_ENV_FILE, DATA_PATH, AUTHENTIK_TAG env vars
    ↓
docker-compose.yml
    ↓
    Spins up postgresql, server, worker, cloudflared
    ↑
    (Optional) GitOps triggers redeploy on repo changes
```

## Quick Start (Local Debug)

To run locally without Portainer (debugging only):

```bash
# Create local directories
mkdir -p /data/lab-authentik-development/{db,media,certs,templates}

# Create a local .env file (copy from .env.template)
cp docker/.env.template docker/.env

# Bring up stack
docker compose -f docker/docker-compose.yml up -d

# View logs
docker compose -f docker/docker-compose.yml logs -f server worker postgresql cloudflared
```

Reset (destructive):
```bash
docker compose -f docker/docker-compose.yml down -v
```

## Environment Variables Reference

### Portainer Stack Configuration
These are configured directly in Portainer's stack settings (not in Infisical).

| Variable | Purpose | Example |
|----------|---------|---------|
| `STACK_ENV_FILE` | Path to env file generated by Infisical | `/data/lab-authentik-development/.env` |
| `DATA_PATH` | Host directory for volumes | `/data/lab-authentik-development` |
| `AUTHENTIK_TAG` | Authentik image tag (version) | `2025.10.3` |

### PostgreSQL Configuration
These variables configure the PostgreSQL database and Authentik's database connection.

| Variable | Purpose | Example |
|----------|---------|---------|
| `POSTGRES_DB` | PostgreSQL database name | `authentik` |
| `POSTGRES_USER` | PostgreSQL username | `authentik` |
| `POSTGRES_PASSWORD` | PostgreSQL password | (secret) |
| `AUTHENTIK_POSTGRESQL__NAME` | Authentik PostgreSQL DB (mirrors POSTGRES_DB) | `authentik` |
| `AUTHENTIK_POSTGRESQL__USER` | Authentik PostgreSQL user (mirrors POSTGRES_USER) | `authentik` |
| `AUTHENTIK_POSTGRESQL__PASSWORD` | Authentik PostgreSQL password (mirrors POSTGRES_PASSWORD) | (secret) |

### Authentik Core Configuration
Essential Authentik configuration variables.

| Variable | Purpose | Example |
|----------|---------|---------|
| `AUTHENTIK_SECRET_KEY` | Authentik encryption key for sessions and tokens | (secret - generate random 64-char string) |
| `AUTHENTIK_BOOTSTRAP_PASSWORD` | Initial admin user password (used on first init) | (secret) |
| `AUTHENTIK_IMAGE` | Authentik container image URI | `ghcr.io/goauthentik/server` |

### Email Configuration
Two sets of email variables: Authentik-specific (`AUTHENTIK_EMAIL__*`) and generic Django-compatible (`EMAIL_*`).

| Variable | Purpose | Example |
|----------|---------|---------|
| `AUTHENTIK_EMAIL__FROM` | Sender email address | `noreply@authentik.example.com` |
| `AUTHENTIK_EMAIL__HOST` | SMTP server hostname | `smtp.gmail.com` |
| `AUTHENTIK_EMAIL__PORT` | SMTP port | `587` |
| `AUTHENTIK_EMAIL__USERNAME` | SMTP authentication username | `your_email@gmail.com` |
| `AUTHENTIK_EMAIL__PASSWORD` | SMTP authentication password | (secret) |
| `AUTHENTIK_EMAIL__USE_TLS` | Enable STARTTLS | `true` |
| `AUTHENTIK_EMAIL__USE_SSL` | Enable SSL/TLS on connection | `false` |
| `AUTHENTIK_EMAIL__TIMEOUT` | SMTP timeout in seconds | `10` |
| `DEFAULT_FROM_EMAIL` | Generic from address | `noreply@authentik.example.com` |
| `EMAIL_HOST` | Generic SMTP hostname | `smtp.gmail.com` |
| `EMAIL_PORT` | Generic SMTP port | `587` |
| `EMAIL_HOST_USER` | Generic SMTP username | `your_email@gmail.com` |
| `EMAIL_HOST_PASSWORD` | Generic SMTP password | (secret) |
| `EMAIL_USE_TLS` | Generic STARTTLS flag | `true` |
| `EMAIL_USE_SSL` | Generic SSL flag | `false` |
| `EMAIL_TIMEOUT` | Generic SMTP timeout | `10` |

### Deployment & Network Configuration
| Variable | Purpose | Example |
|----------|---------|---------|
| `TUNNEL_TOKEN` | Cloudflare Tunnel authentication token | (secret) |

## File Structure

```
lab-authentik/
├── docker/
│   ├── docker-compose.yml          # Main Compose configuration
│   ├── .env.template               # Template for environment variables
│   ├── .env.development            # Development env (local only)
│   └── .env.production             # Production env (local only)
├── .github/
│   ├── workflows/                  # GitHub Actions (optional CI/CD)
│   └── copilot-instructions.md     # AI agent instructions
├── README.md                       # This file
└── .gitignore
```

## Troubleshooting

### Stack won't start
- Check Portainer logs: Stacks → Select stack → Logs
- Verify host directories exist: `ls -la /data/lab-authentik-{environment}`
- Confirm `STACK_ENV_FILE` path is correct and readable

### Pages won't load (Cloudflare Tunnel issue)
- Verify tunnel token in Infisical is current
- Check Cloudflare dashboard for tunnel status
- Confirm tunnel routes to `http://server:9000`

### Database errors
- Ensure PostgreSQL volume has write permissions: `chmod 755 /data/lab-authentik-{environment}/db`
- Check volume is not full: `du -sh /data/lab-authentik-{environment}/db`

### GitOps not triggering updates
- Verify GitOps is enabled in Portainer stack settings
- Check Portainer can reach repository (ensure SSH keys or PAT if private)
- Manual refresh: Stacks → Select stack → Pull & Redeploy

## Security Notes

- **Secrets in Infisical**: All database passwords, tokens, and keys live in Infisical, never committed to Git
- **Host permissions**: Restrict `/data/lab-authentik-{environment}` access to Portainer/Docker user only
- **Tunnel**: Cloudflare Tunnel provides encrypted, authenticated internet access without exposing ports
- **Network isolation**: Services communicate only over internal bridge; no direct internet access

## References

- [Authentik Documentation](https://docs.goauthentik.io/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Portainer GitOps](https://docs.portainer.io/admin/stacks/create)
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Infisical](https://infisical.com/docs)
