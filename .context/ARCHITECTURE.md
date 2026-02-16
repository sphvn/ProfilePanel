# ProfilePanel — Architecture

## File Structure

```
ProfilePanel/
├── ProfilePanel.toc            # Addon manifest (Interface 120001)
├── core/
│   ├── core.lua                # Namespace (PP), colors, constants, slot maps, utilities
│   ├── events.lua              # Event registration, dispatch, lifecycle, stat event consolidation
│   └── api.lua                 # Stat definitions (3-tier), equipment info, enchant/gem detection
├── ui/
│   ├── frame.lua               # Main frame, CharacterFrame hook, layout regions
│   ├── header.lua              # Character name, class, spec, ilvl header bar
│   ├── model.lua               # DressUpModel viewport with mouse rotation
│   ├── equipment.lua           # Slot button reparenting, ilvl badges, warning indicators
│   └── stats.lua               # Stat card grid (4 columns, pooled cards, 3 tiers)
├── Media/
│   └── Textures/               # Custom TGA/PNG textures (empty, future work)
├── .context/                   # This documentation directory
└── .cursor/rules/              # Cursor AI rules for this project
```

## Load Order (from .toc)

1. `core/core.lua` — Creates `PP` namespace, defines constants/colors
2. `core/events.lua` — Event system, lifecycle events, Blizzard event forwarding
3. `core/api.lua` — Stat definitions, `PP:GetAllStats()`, `PP:GetSlotInfo()`
4. `ui/frame.lua` — Main frame, CharacterFrame hook
5. `ui/header.lua` — Header bar
6. `ui/model.lua` — 3D model
7. `ui/equipment.lua` — Equipment slot layout
8. `ui/stats.lua` — Stat card grid

## Namespace

- **`PP`** — the addon namespace table, created by `local addonName, PP = ...` in core.lua
- Exposed globally as `ProfilePanel = PP` for debug access
- All files receive it via `local _, PP = ...`

## Event Flow

```
WoW loads addon
  → core.lua creates PP namespace
  → events.lua creates event system
  → api.lua registers stat definitions
  → ui/*.lua register PP_FRAME_CREATED handlers

ADDON_LOADED fires
  → PP_INITIALIZED (saved variables loaded)

PLAYER_LOGIN fires
  → PP_READY
    → frame.lua creates MainFrame, layout regions
    → PP_FRAME_CREATED fires
      → header.lua creates header elements
      → model.lua creates DressUpModel
      → equipment.lua reparents slot buttons, adds overlays
      → stats.lua pre-creates card pool
    → CharacterFrame hooks installed

Player presses 'C' (character panel)
  → PaperDollFrame:Show hook fires
    → PP_SHOW → model updates
    → PP_STATS_UPDATE → header, equipment, stats all refresh

Any stat/equipment Blizzard event fires
  → PP_STATS_UPDATE → all UI refreshes
```

## Custom Events

| Event | When | Handlers |
|-------|------|----------|
| `PP_INITIALIZED` | SavedVariables loaded | — |
| `PP_READY` | PLAYER_LOGIN | frame.lua creates UI |
| `PP_FRAME_CREATED` | MainFrame built | all ui/*.lua init |
| `PP_SHOW` | Panel becomes visible | model.lua |
| `PP_HIDE` | Panel hidden | — |
| `PP_STATS_UPDATE` | Any stat/gear change | header, equipment, stats |

## Layout Regions (MainFrame children)

```
┌───────────────────────────────────────────┬──────────────┐
│  header (70px)                            │              │
│  Title / Name / AchPts / iLvl             │              │
│  Level Race Spec Class <Guild> Realm      │              │
├──────┬──────────────────┬──────┬──────────┤  statsPanel  │
│ gear │                  │ gear │ vert sep │  (scrollable)│
│ Left │   modelArea      │Right │          │  Single-col  │
│(46px)│  (DressUpModel)  │(46px)│          │  stat cards  │
│  8   │                  │  8   │          │              │
│slots │ item names float │slots │          │              │
│      │ over model area  │      │          │              │
├──────┴──────┬───────────┴──────┤          │              │
│  weaponRow  │    (42px)        │          │              │
│  MH    OH   │                  │          │              │
└─────────────┴──────────────────┴──────────┴──────────────┘
```

CharacterFrame is resized to 730×650.
Blizzard chrome (NineSlice, portrait, title bar, tabs) is fully hidden.

## Stat Card Design

Each stat card is a 130×44 Frame containing:
- **Accent bar** (3px left edge, stat-colored)
- **Icon square** (30×30, colored background + 3-letter abbreviation)
- **Value text** (14pt, white, e.g. "27%")
- **Label text** (9pt, gray, e.g. "Critical Strike")

Cards are arranged in a 4-column grid with 6px horizontal / 5px vertical gaps.
Cards are pooled and recycled on each update for performance.

## Equipment Display

Blizzard's slot buttons (CharacterHeadSlot, etc.) are reparented to our layout regions. Each gets:
- **ilvl badge** (9pt, bottom-right corner, colored by item quality)
- **Item name** (9pt, quality-colored, floats over model area next to slot)
- **Enchant text** (8pt, mint green, or red "Missing Enchant" for enchantable slots)
- **Gem icons** (12×12, shown for gem-eligible slots; red indicator for empty sockets)
- **Warning dot** (atlas "communities-icon-notification", top-right, shown if missing enchant/gem)
