# Palworld Management Dashboard

Self-hostable web dashboard for managing a Palworld dedicated server.

## Recommended: palworld-server-tool (PST)

- Repo: https://github.com/zaigie/palworld-server-tool
- License: Apache-2.0, ~1.2k stars, actively maintained
- Stack: Go + Vue, Docker-native

### Features

- Players, guilds, Pals and inventory data viewing
- Server info, metrics, online player list
- Kick, ban, broadcast, graceful shutdown
- Visual map and whitelist management
- Custom and scheduled RCON commands
- Save sync, automatic backups, backup management
- Desktop and mobile responsive UI

### Requirements

- Game server must enable the official REST API (and RCON for some actions)
  in `PalWorldSettings.ini` / `WorldOption.sav` (set `AdminPassword` first)
- Parsing `Level.sav` briefly spikes to 1-3 GB RAM — size the host accordingly
- Data lives in `pst.db` (business data) and `config.db` (config + admin
  credentials); persist both

### Deployment

All-in-one (PST on same host as saves):

```sh
docker run -d --name pst \
  -p 8080:8080 \
  -v /path/to/your/Pal/Saved:/game \
  -v ./backups:/app/backups \
  -v ./pst.db:/app/pst.db \
  -v ./config.db:/app/config.db \
  jokerwho/palworld-server-tool:latest
```

Agent mode (PST on a different host, e.g. in the k8s cluster while the game
server runs elsewhere):

```sh
# On the game server host
docker run -d --name pst-agent \
  -p 8081:8081 \
  -v /path/to/your/Pal/Saved:/game \
  -e SAVED_DIR="/game" \
  jokerwho/palworld-server-tool-agent:latest
```

Then point PST at `http://<game-server-ip>:8081/sync` plus the game server's
RCON/REST API addresses.

### First-run

Visit the web UI, create the admin password (one-time; first visitor becomes
admin), then configure save source (local dir or pst-agent), RCON and REST API
in the settings dialog.

## Alternative: palhelm

- Repo: https://github.com/8tp/palhelm
- Single Docker image, self-hosted web admin panel: live dashboard, player
  management
- Very early project (low adoption) — consider only if PST is a poor fit

## Cluster integration sketch (homelab-infra)

If hosted in the harvester cluster:

1. New `applications/harvester/app_palworld_pst.tf` using the standard service
   module pattern (namespace `games` or similar)
2. Image pinned in `init_versions.tf` (`jokerwho/palworld-server-tool`)
3. Agent mode against the game server host; RCON/REST endpoints via env/config
4. Tailscale ingress for the dashboard, matching gbrain/other services
5. Longhorn PVCs for `pst.db`, `config.db`, backups
