# ProfilePanel — Stat System

## 3-Tier Stat Hierarchy

### Tier 1: Primary (always shown)

| Key | Label | Color | API | Format |
|-----|-------|-------|-----|--------|
| PRIMARY | Intellect/Strength/Agility (auto-detect via spec) | INTELLECT/STRENGTH/AGILITY | `GetSpecializationInfo()` → `UnitStat("player", index)` | raw number |
| STAMINA | Stamina | gold (#C69B33) | `UnitStat("player", 3)` | raw number |
| ILVL | Item Level | gold (#FFD700) | `GetAverageItemLevel()` → avgEquipped | rounded integer |

### Tier 2: Secondary (always shown)

| Key | Label | Color | API | Format |
|-----|-------|-------|-----|--------|
| CRIT | Critical Strike | red (#DE3D33) | `GetSpellCritChance()` / `GetCritChance()` / `GetRangedCritChance()` (max) | X.X% |
| HASTE | Haste | teal (#33A680) | `UnitSpellHaste("player")` | X.X% |
| MASTERY | Mastery | purple (#9440B8) | `GetMasteryEffect()` | X.X% |
| VERSATILITY | Versatility | gray (#8C8C8C) | `GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)` + `GetVersatilityBonus()` | X.X% / X.X% (dmg/DR) |

### Tier 3: Tertiary (shown only when value > 0)

| Key | Label | Color | API | Format | Notes |
|-----|-------|-------|-----|--------|-------|
| LEECH | Leech | light green | `GetLifesteal()` | X.XX% | |
| AVOIDANCE | Avoidance | light blue | `GetAvoidance()` | X.XX% | |
| SPEED | Speed (rating) | green | `GetSpeed()` | X.XX% | Gear stat |
| MOVESPEED | Move Speed | green | `GetUnitSpeed("player")` / `BASE_MOVEMENT_SPEED * 100` | X% | Actual movement, incl. buffs |
| ARMOR | Armor | silver | `UnitArmor("player")` | N (X% DR) | Shows value + damage reduction |
| DODGE | Dodge | blue | `GetDodgeChance()` | X.XX% | |
| PARRY | Parry | red | `GetParryChance()` | X.XX% | |
| BLOCK | Block | bronze | `GetBlockChance()` | X.XX% | |
| ATTACKPOWER | Attack Power | dark red | `UnitAttackPower("player")` | raw number | Melee/ranged auto-detect |
| SPELLPOWER | Spell Power | purple-blue | `GetSpellBonusDamage(2)` | raw number | |
| ATTACKSPEED | Attack Speed | orange-gold | `UnitAttackSpeed("player")` | X.XXs / X.XXs | MH / OH if dual wield |
| GCD | GCD | gray | `max(0.75, 1.5 * 100 / (100 + GetHaste()))` | X.XXs | Class overrides for Rogue/Monk/Cat |

## Color Palette (RGB float)

```lua
PP.Colors = {
    STRENGTH    = { 0.78, 0.13, 0.13 },
    AGILITY     = { 1.00, 0.78, 0.24 },
    INTELLECT   = { 0.96, 0.55, 0.10 },
    STAMINA     = { 0.78, 0.61, 0.20 },
    ILVL        = { 1.00, 0.84, 0.00 },
    CRIT        = { 0.87, 0.24, 0.20 },
    HASTE       = { 0.20, 0.65, 0.50 },
    MASTERY     = { 0.58, 0.25, 0.72 },
    VERSATILITY = { 0.55, 0.55, 0.55 },
    LEECH       = { 0.55, 0.82, 0.40 },
    AVOIDANCE   = { 0.35, 0.58, 0.80 },
    SPEED       = { 0.30, 0.69, 0.31 },
    MOVESPEED   = { 0.30, 0.69, 0.31 },
    ARMOR       = { 0.65, 0.65, 0.65 },
    DODGE       = { 0.35, 0.58, 0.80 },
    PARRY       = { 0.80, 0.35, 0.35 },
    BLOCK       = { 0.58, 0.51, 0.30 },
    ATTACKPOWER = { 0.80, 0.30, 0.20 },
    SPELLPOWER  = { 0.40, 0.30, 0.80 },
    ATTACKSPEED = { 0.80, 0.60, 0.20 },
    GCD         = { 0.60, 0.60, 0.60 },
}
```

## Card Abbreviations (icon text)

```
PRIMARY → first 3 of label (INT, STR, AGI)
STAMINA → STA, ILVL → iLv
CRIT → CRT, HASTE → HST, MASTERY → MST, VERSATILITY → VRS
LEECH → LCH, AVOIDANCE → AVD, SPEED → SPD, MOVESPEED → MOV
ARMOR → ARM, DODGE → DDG, PARRY → PRY, BLOCK → BLK
ATTACKPOWER → AP, SPELLPOWER → SP, ATTACKSPEED → AS, GCD → GCD
```

## Enchant/Gem Rules (The War Within)

### Enchantable Slots
Back, Chest, Wrist, Legs, Feet, Ring1, Ring2, MainHand

### Gem Socket Slots
- **1 socket**: Head, Wrist, Waist
- **2 sockets**: Neck, Ring1, Ring2

### Detection Methods
- **Enchants**: Scan tooltip lines with `C_TooltipInfo.GetInventoryItem()`, match against `ENCHANTED_TOOLTIP_LINE`
- **Gems**: `C_Item.GetItemGem(itemLink, index)` — nil means empty socket
