# Hermes Agent — Home Assistant Addon

AI Agent with advanced tool-calling capabilities, integrated with Home Assistant.

## Features

- 🤖 **AI Assistant** — conversational AI via MiniMax, OpenAI, Anthropic, etc.
- 🏠 **Home Assistant Integration** — reads sensors, controls devices via HA API
- 💬 **Multi-platform** — Telegram, Discord, Slack, WhatsApp, and more
- ⏰ **Cron Jobs** — scheduled tasks and reminders
- 🧠 **Memory** — persistent context across sessions
- 🔧 **Skills** — extensible skill system for specialized tasks

## Architecture

```
┌─────────────────────────────────────┐
│   Home Assistant Supervised        │
│                                     │
│  ┌──────────────────────────────┐ │
│  │   Hermes Agent Addon         │ │
│  │   (Docker container)         │ │
│  │                               │ │
│  │   hermes-agent (git clone)   │ │
│  │   └── venv/                  │ │
│  │   └── hermes gateway         │ │
│  │   └── ~/.hermes/             │ │
│  │       └── config.yaml        │ │
│  │       └── skills/            │ │
│  │       └── secrets/           │ │
│  └──────────────────────────────┘ │
│               ↕ HA API             │
│  ┌──────────────────────────────┐ │
│  │   Home Assistant Core        │ │
│  │   (192.168.1.4:8123)         │ │
│  └──────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Configuration

### Required Setup

1. **Get Home Assistant API Token:**
   - Home Assistant → Profile → Long-Lived Access Tokens
   - Create a token, copy it

2. **Configure Hermes config** (via Samba or File Editor addon):
   
   Create `~/.hermes/secrets/credentials.json`:
   ```json
   {
     "ha_token": "YOUR_HA_TOKEN_HERE"
   }
   ```
   
   Edit `~/.hermes/config.yaml`:
   ```yaml
   model:
     default: MiniMax-M2.7
     provider: minimax
   
   # Your Hermes Agent API key
   api_key: "YOUR_HERMES_API_KEY"
   ```

3. **Telegram (optional):**
   ```yaml
   telegram:
     bot_token: "YOUR_BOT_TOKEN"
   ```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `log_level` | enum | `info` | Log verbosity |
| `update_on_start` | bool | `false` | Pull latest git before start |
| `git_branch` | string | `master` | Git branch to track |

## Updating Hermes

### Automatic (per-startup)

Set `update_on_start: true` in addon options. Hermes will `git pull` on each container start.

### Manual via UI

Restart the addon — it will pull latest if `update_on_start: true`.

### Manual via SSH

```bash
# Enter addon shell
docker exec -it addon_hermes-agent-wrapper /bin/sh

# Navigate to Hermes
cd /data/hermes-agent

# Pull latest
git pull origin master

# Reinstall
. venv/bin/activate
pip install -e . --quiet

# Restart addon from HA UI
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 8000 | Hermes Gateway | Main API/websocket endpoint |

## Data Persistence

All Hermes data is stored in `/data` (mapped from `share`):

```
/data/.hermes/
├── config.yaml      # Main config
├── credentials.json # Secrets
├── skills/          # Custom skills
├── secrets/         # API keys
├── logs/            # Log files
└── cache/           # Temp files
```

## Troubleshooting

**Healthcheck fails:**
```bash
# Check if Hermes is running
curl http://127.0.0.1:8000/health

# Check logs
hermes logs --follow
```

**Git clone fails:**
- Check internet access from container
- Verify GitHub is not blocked

**Config not found:**
- Make sure `~/.hermes/config.yaml` exists
- Check file permissions (readable)

## Links

- [Hermes Agent Repository](https://github.com/NousResearch/hermes-agent)
- [Documentation](https://hermesagent.dev)
- [Home Assistant Community Add-ons](https://github.com/hassio-addons/repository)
