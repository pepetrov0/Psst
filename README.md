# Psst!

> Whisper me the secret word and I'll invite you. Converts to raid if the party is full.

[![WoW](https://img.shields.io/badge/WoW-WotLK%203.3.5a-8b5cf6?style=flat-square)](https://wowpedia.fandom.com/wiki/WoWWiki:WoW_3.3.5)
[![Interface](https://img.shields.io/badge/Interface-30300-3c873a?style=flat-square)](#installation)
[![Lua](https://img.shields.io/badge/Lua-5.1-blue?style=flat-square)](#)

A tiny World of Warcraft addon for WotLK 3.3.5a that runs open recruitment on autopilot. Set a secret word, share it in Trade or guild chat, and anyone who whispers it to you gets invited to your group — no clicking, no typing `/invite`, no alt-tabbing.

## How it works

1. Pick a secret word: `/psst word stormrage`
2. Announce it: `"Whisper me 'stormrage' for invite!"`
3. Players whisper the word to you — Psst! invites them automatically

That's it. The word is matched case-insensitively, and repeat whispers from the same player are ignored for a short cooldown so spam doesn't flood your chat or your party.

## Features

- **Whisper-to-invite** — invites any player who whispers the exact secret word
- **Party → raid conversion** — when your party is full (4/5), Psst! converts to raid and fires the invite once the roster updates
- **Group-aware** — invites as raid leader or assistant in raids, checks your permissions before acting, and skips players already in your group
- **Spam protection** — 5-second cooldown per whisperer, self-whispers are ignored
- **Persistent settings** — your word and enabled state are saved between sessions (`SavedVariables`)
- **Zero dependencies** — a single `.lua` file, no Ace or LibStub libraries required

## Installation

1. Download or clone this repository
2. Copy the `Psst` folder into your addons directory:

   ```
   Interface/AddOns/Psst
   ```

3. Restart WoW (or run `/reload` if you're already logged in)
4. Confirm the addon shows up in your character screen's addon list

## Usage

### Quick start

```
/psst word stormrage     # set the secret word
/psst                    # shows status and available commands
```

### Commands

| Command              | Description                                  |
| -------------------- | -------------------------------------------- |
| `/psst`              | Show status and command list                 |
| `/psst word <secret>`| Set the secret word (case-insensitive match) |
| `/psst on`           | Enable the addon                             |
| `/psst off`          | Disable the addon                            |
| `/psst toggle`       | Toggle enabled/disabled                      |

Settings persist across sessions and reloads.

> [!TIP]
> Leaving the word unset (`/psst` prints a reminder on first load) keeps the listener dormant — whisper matching only runs while the addon is enabled **and** a word is set.

### Invite behavior

| Your group state                        | What Psst! does                                        |
| --------------------------------------- | ------------------------------------------------------ |
| Solo                                    | Invites directly                                       |
| Party, not full                         | Invites directly (you must be party leader)            |
| Party full (4/5)                        | Converts to raid, then invites within a 5s window      |
| Raid                                    | Invites if you're raid leader or assistant (up to 40)  |

> [!NOTE]
> If the party-to-raid conversion doesn't go through within 5 seconds, the pending invite is cancelled and Psst! tells you in chat — you can always `/invite` the player manually.

## Project layout

```
Psst/
├── Psst.toc    # Addon metadata (Interface 30300, SavedVariables)
└── Psst.lua    # All the logic: whisper matching, invites, commands
```