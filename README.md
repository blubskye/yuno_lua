<div align="center">

# Yuno Gasai Discord Bot - Lua Edition

### *"I'll protect this server forever... just for you~"*

<img src="https://i.imgur.com/jF8Szfr.png" alt="Yuno Gasai" width="300"/>

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-pink.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Lua](https://img.shields.io/badge/Lua-5.1+-ff69b4.svg)](https://www.lua.org/)
[![Discordia](https://img.shields.io/badge/Discordia-2.x-ff1493.svg)](https://github.com/SinisterRectus/Discordia)

*A devoted Discord bot for moderation, leveling, and anime~*

---

</div>

## About

Yuno is a **yandere-themed Discord bot** combining powerful moderation tools with a leveling system and anime features. She'll keep your server safe from troublemakers... *because no one else is allowed near you~*

This is the **Lua port** of the original JavaScript Yuno bot, using the Discordia library.

## Features

| Category | Features |
|----------|----------|
| **Leveling System** | XP gain from messages, level-up announcements, leaderboards, rank rewards |
| **Moderation** | Ban, kick, warn, purge, mod logs, user history tracking |
| **Fun Commands** | 8ball, praise, scold, hug, slap, kiss, neko, urban dictionary |
| **Welcome System** | Customizable welcome messages, DM greetings, member count |
| **Configuration** | Per-server prefixes, toggle features, mention responses |
| **Utility** | Help, stats, ping, invite, source code |

## Requirements

- [Luvit](https://luvit.io/) - Lua + libuv runtime
- [Discordia](https://github.com/SinisterRectus/Discordia) - Discord API wrapper
- [lsqlite3](http://lua.sqlite.org/) - SQLite3 bindings

## Installation

### 1. Install Luvit

```bash
curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh
```

### 2. Install Dependencies

```bash
lit install SinisterRectus/discordia
lit install luvit/json
```

### 3. Configure the Bot

```bash
cp config.example.lua config.lua
nano config.lua
```

### 4. Run the Bot

```bash
luvit init.lua
```

## Configuration

Edit `config.lua` with your settings:

```lua
return {
    bot = {
        token = 'YOUR_BOT_TOKEN_HERE',
        prefix = '?',
        status = 'for levels',
        activity_type = 'watching',
        owner_ids = { 'YOUR_USER_ID' },
    },
    database = {
        path = 'data/yuno.db',
    },
    leveling = {
        xp_per_message_min = 15,
        xp_per_message_max = 25,
    },
}
```

## Commands

### Basic Commands
| Command | Description |
|---------|-------------|
| `?ping` | Check bot latency |
| `?help [command]` | Show help information |
| `?stats` | Display bot statistics |
| `?invite` | Get bot invite link |

### Leveling Commands
| Command | Description |
|---------|-------------|
| `?xp [@user]` | Check XP and level |
| `?leaderboard` | View server leaderboard |
| `?ranks` | View level-up role rewards |
| `?givexp @user <amount>` | Give XP (Admin) |
| `?setlevel @user <level>` | Set level (Admin) |

### Moderation Commands
| Command | Description |
|---------|-------------|
| `?ban @user [reason]` | Ban a user |
| `?kick @user [reason]` | Kick a user |
| `?warn @user [reason]` | Warn a user |
| `?warnings @user` | View warnings |
| `?purge <amount>` | Delete messages |
| `?modstats` | View mod statistics |

### Fun Commands
| Command | Description |
|---------|-------------|
| `?8ball <question>` | Magic 8ball |
| `?praise @user` | Praise someone |
| `?hug @user` | Hug someone |
| `?urban <term>` | Urban Dictionary |
| `?coinflip` | Flip a coin |
| `?roll [XdY]` | Roll dice |

### Configuration Commands
| Command | Description |
|---------|-------------|
| `?setprefix <prefix>` | Change prefix |
| `?config` | View configuration |
| `?toggleleveling` | Toggle leveling |
| `?setwelcome #channel` | Set welcome channel |

## Project Structure

```
Yuno_lua/
├── init.lua
├── config.lua
├── data/
│   └── yuno.db
└── src/
    ├── lib/
    │   ├── config.lua
    │   ├── database.lua
    │   ├── command_manager.lua
    │   └── prompt.lua
    └── commands/
        ├── basic.lua
        ├── leveling.lua
        ├── moderation.lua
        ├── fun.lua
        └── configuration.lua
```

## License

AGPL-3.0 License

---

<div align="center">
  <i>Made with love by Yuno~</i>
</div>
