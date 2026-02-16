# ProfilePanel — Project Context

## What This Is

ProfilePanel is a new World of Warcraft addon (Retail only, Interface 120001) that replaces the default character sheet with a clean, dark UI inspired by the WoW Armory website (worldofwarcraft.com character pages). It is **not** a fork of any existing addon — it is built from scratch using ChonkyCharacterSheet as an API/pattern reference.

## Origin Story

1. User was using **ChonkyCharacterSheet** (`git@github.com:draeginia/ChonkyCharacterSheet.git`) and hit a `Texture:SetScale(): Scale must be > 0` error on a Goblin Warlock (race/class combo where the model background layout returns zero dimensions during init).

2. We fixed that bug with an early-return guard in `ChangeModelBg()`, forked the repo to `git@github.com:sphvn/ChonkyCharacterSheet.git`, and submitted a PR to upstream on branch `fix/setscale-zero-guard`.

3. The user liked ChonkyCharacterSheet's general layout but wanted something cleaner — specifically matching the WoW website's character profile aesthetic with:
   - Stats displayed as colored icon cards (the website uses diamond-shaped SVG icons)
   - Missing enchant/gem callouts
   - Less settings complexity
   - Focus on a magazine-style stat display rather than a dense spreadsheet

4. Decision was made to create a **brand new addon** rather than fork CCS, using CCS only as a reference for WoW API patterns.

5. Name chosen: **ProfilePanel** (other candidates were ArmorySheet, Herald, Sigil).

## Key Decisions Made

| Decision | Choice | Reason |
|----------|--------|--------|
| Addon name | ProfilePanel | "Like viewing your web profile in-game" |
| Scope | Full character panel replacement from start | User wanted gear + stats, not incremental |
| Stat icons | Custom TGA textures (future) | Best quality; using colored-square placeholders for now |
| Stat tiers | 3-tier system | Primary (always), Secondary (always), Tertiary (if >0) |
| Classic support | No | Retail only to keep scope tight |
| Settings | Minimal | Just enable/disable + font size |
| Inspect frame | Deferred | Can add later |
| Mythic+/Raid panels | No | Keep scope tight, not a CCS clone |

## User's Character (for testing context)

- **Character**: Ashkeryn @ Illidan (US)
- **Race/Class**: Goblin Warlock (Destruction spec)
- **Profile**: https://worldofwarcraft.com/en-us/character/us/illidan/ashkeryn/

## Workspace Layout

```
c:\Users\su\src\wow\
├── ChonkyCharacterSheet\    ← reference addon (CCS), has the upstream PR
│   ├── origin → git@github.com:sphvn/ChonkyCharacterSheet.git (fork)
│   └── upstream → git@github.com:draeginia/ChonkyCharacterSheet.git
│
└── ProfilePanel\            ← THIS addon (new, standalone)
    └── origin → (not yet configured, needs GitHub repo)
```

## Live Development Setup

A **directory junction** links the git repo to WoW's AddOns folder:

```
C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\ProfilePanel
  → c:\Users\su\src\wow\ProfilePanel
```

Edit files here → `/reload` in-game → see changes immediately.

The same junction pattern is used for ChonkyCharacterSheet.

## Current Status (as of initial scaffold)

- All 8 core files written and loadable
- Stat system covers all 3 tiers including tertiary stats (Leech, Avoidance, Speed, Move Speed, Armor, Dodge, Parry, Block, Attack Power, Spell Power, Attack Speed, GCD)
- Equipment slots reparented with ilvl badges and missing enchant/gem warnings
- 3D model viewport with mouse-drag rotation
- Header with character name (class-colored), subtitle, large ilvl display
- Stat cards use colored-square placeholders (diamond TGA textures are a future task)
- No custom textures created yet (Media/Textures/ is empty)
- No GitHub repo created for ProfilePanel yet
