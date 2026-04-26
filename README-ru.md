# Hermes Agent — Аддон для Home Assistant

AI-ассистент с расширенными возможностями вызова инструментов, интегрированный с Home Assistant.

## Возможности

- 🤖 **AI-ассистент** — диалоговый ИИ через MiniMax, OpenAI, Anthropic и др.
- 🏠 **Интеграция с Home Assistant** — читает датчики, управляет устройствами через HA API
- 💬 **Мультиплатформа** — Telegram, Discord, Slack, WhatsApp и другие
- ⏰ **Cron-задачи** — планировщик задач и напоминаний
- 🧠 **Память** — сохраняет контекст между сессиями
- 🔧 **Навыки** — расширяемая система навыков для специализированных задач

## Архитектура

```
┌─────────────────────────────────────┐
│   Home Assistant Supervised        │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   Hermes Agent Аддон         │  │
│  │   (Docker контейнер)         │  │
│  │                               │  │
│  │   hermes-agent (git clone)   │  │
│  │   └── venv/                  │  │
│  │   └── hermes gateway         │  │
│  │   └── ~/.hermes/             │  │
│  │       └── config.yaml        │  │
│  │       └── skills/            │  │
│  │       └── secrets/           │  │
│  └──────────────────────────────┘  │
│               ↕ HA API              │
│  ┌──────────────────────────────┐  │
│  │   Home Assistant Core         │  │
│  │   (192.168.1.4:8123)         │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Быстрый старт

### 1. Установка

1. **Settings → Add-ons → Add-on Store**
2. **⋮ → Add repository** → вставить:
   ```
   https://github.com/ZhenyaRUS39/hermes-agent-ha-addon
   ```
3. Найти **Hermes Agent** → **Install**

### 2. Настройка

После установки откройте аддон и добавьте токен Home Assistant:

```yaml
ha_token: "eyJhbGciOiJIUzI1NiIs..."  # Long-Lived Access Token
log_level: info
update_on_start: false
git_branch: master
```

**Как получить токен:**
- Home Assistant → Profile (аватар) → Long-Lived Access Tokens
- Нажмите **Create Token** → скопируйте и вставьте выше

### 3. Запуск

- Нажмите **Start** — токен автоматически сохранится в постоянное хранилище
- Откройте UI через **Боковая панель → Hermes AI** (ingress на порту 8000)

> ⚠️ Токен хранится в `/data/.hermes/secrets/credentials.json` (persistent share) и никогда не покидает ваш Home Assistant.

## Опции аддона

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `ha_token` | string | `""` | Home Assistant Long-Lived Access Token |
| `log_level` | enum | `info` | Уровень логирования |
| `update_on_start` | bool | `false` | Обновить hermes-agent из git перед запуском |
| `git_branch` | string | `master` | Git-ветка для отслеживания |

## Обновление Hermes Agent

По умолчанию аддон использует зафиксированную версию hermes-agent из git. Для обновления:

```yaml
update_on_start: true  # ← включить автообновление
```

При каждом запуске аддон выполнит `git pull` и обновит зависимости.

## Порт и доступ

- **Внутренний порт:** `8000`
- **Ingress URL:** автоматически через `/api/hassio_ingress/<token>/` (боковая панель)
- **Host network:** включён — Hermes имеет прямой доступ к сети

## Структура хранилища

```
/data/                              # Persistent share (homeassistant/share)
└── hermes-agent/                   # Git-клон hermes-agent
    ├── venv/                       # Python virtualenv
    └── .hermes/                    # Конфигурация
        ├── config.yaml             # Основной конфиг
        ├── skills/                 # Навыки (skills)
        ├── secrets/credentials.json # Токены и ключи
        └── sessions/               # История сессий
```

## Устранение неполадок

**Аддон не запускается?**
- Проверьте логи: **Hermes Agent → Log**
- Убедитесь, что `ha_token` скопирован полностью (без пробелов)

**Ошибка 502?**
- Подождите 10-15 секунд после Start — Hermes запускается не мгновенно
- Проверьте что порт 8000 свободен

**Обновление не работает?**
```yaml
update_on_start: true
git_branch: master
```
Перезапустите аддон после изменения.

## Полезные ссылки

- [Hermes Agent на GitHub](https://github.com/NousResearch/hermes-agent)
- [Документация Home Assistant](https://www.home-assistant.io)
- [Репо этого аддона](https://github.com/ZhenyaRUS39/hermes-agent-ha-addon)
