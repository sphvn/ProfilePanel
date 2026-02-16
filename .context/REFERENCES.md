# ProfilePanel — References & Links

## External Links

### WoW Website (Design Inspiration)
- **Character profile page**: https://worldofwarcraft.com/en-us/character/us/illidan/ashkeryn/
- The website uses diamond-shaped SVG stat icons in a 4-column grid
- CSS classes: `color-stat-HEALTH`, `color-stat-MANA`, `color-stat-INTELLECT`, `color-stat-STAMINA`, `color-stat-CRITICALSTRIKE`, `color-stat-HASTE`, `color-stat-MASTERY`, `color-stat-VERSATILITY`
- Each stat card: `CharacterStat-media` with `Media-image` (diamond icon) + `Media-text` (value + name)
- SVG icons are embedded inline — we replicate these as TGA textures for the diamond shape

### ChonkyCharacterSheet (API Reference)
- **Upstream repo**: https://github.com/draeginia/ChonkyCharacterSheet
- **User's fork**: https://github.com/sphvn/ChonkyCharacterSheet
- **PR submitted**: fix/setscale-zero-guard branch — guards `SetScale(0)` when frame has zero dimensions
- **Local path**: `c:\Users\su\src\wow\ChonkyCharacterSheet`

### Other Addons Mentioned (Style References)
- **DialogUI** — clean, modern WoW UI replacement
- **Plumber** — quality-of-life addon with polished UI

## ChonkyCharacterSheet Pattern Reference

### Key Files and What We Learned From Them

**`ChonkyCharacterSheet.toc`**
- Multi-version interface support: `120001, 20505, 50503`
- Load order: Libraries → Core → Version modules → Events → Options
- Uses LibStub, LibDeflate, LibSharedMedia

**`core/events.lua` (lines 16-79)**
- Event registration with version gating
- Multiple handlers per event
- Custom event firing via `:FireEvent()`
- Central dispatcher on a single frame

**`Retail/characterStats.lua`**
- Primary stats: `UnitStat("player", statIndex)` — index 1=Str, 2=Agi, 3=Sta, 4=Int
- Crit: `GetSpellCritChance()`, `GetCombatRating(CR_CRIT_SPELL)`, `GetCombatRatingBonus(CR_CRIT_SPELL)`
- Haste: `UnitSpellHaste("player")`, `GetCombatRating(CR_HASTE_SPELL)`
- Mastery: `GetMasteryEffect()`, `GetCombatRating(CR_MASTERY)`, `bonusCoeff` from `GetMasteryEffect()`
- Versatility: `GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)`, `GetCombatRatingBonus()` + `GetVersatilityBonus()` for both damage done and damage taken
- Leech: `GetLifesteal()`, `GetCombatRating(CR_LIFESTEAL)`
- Avoidance: `GetAvoidance()`, `GetCombatRating(CR_AVOIDANCE)`
- Speed: `GetSpeed()`, `GetCombatRating(CR_SPEED)`
- Move Speed: `GetUnitSpeed("player")` / `BASE_MOVEMENT_SPEED * 100`
- Armor: `UnitArmor("player")`, `PaperDollFrame_GetArmorReduction()`
- Dodge: `GetDodgeChance()`, `GetCombatRating(CR_DODGE)`
- Parry: `GetParryChance()`, `GetCombatRating(CR_PARRY)`
- Block: `GetBlockChance()`, `GetShieldBlock()`
- Attack Power: `UnitAttackPower("player")` or `UnitRangedAttackPower("player")`
- Spell Power: `GetSpellBonusDamage(2)`
- Attack Speed: `UnitAttackSpeed("player")` returns mainhand, offhand
- GCD: `max(0.75, 1.5 * 100 / (100 + GetHaste()))` with class-specific overrides

**`core/utils.lua` (lines 1491-2015)**
- Tooltip scanning: `C_TooltipInfo.GetInventoryItem("player", slotID)` (Retail)
- Enchant detection: match `ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)")`
- Gem detection: `C_Item.GetItemGem(itemLink, index)` for gems 1-3
- Missing gem rules (TWW): Head/Wrist/Waist = 1 socket, Neck/Ring1/Ring2 = 2 sockets

**`Retail/characterSheet.lua` (lines 946-960)**
- Frame hooking: `hooksecurefunc(CharacterFrame, "Show", fn)` and `hooksecurefunc(PaperDollFrame, "Show", fn)`
- Hide hook: `hooksecurefunc(CharacterFrame, "Hide", fn)`

### Blizzard Equipment Slot Button Names
```
CharacterHeadSlot, CharacterNeckSlot, CharacterShoulderSlot,
CharacterBackSlot, CharacterChestSlot, CharacterShirtSlot,
CharacterTabardSlot, CharacterWristSlot, CharacterHandsSlot,
CharacterWaistSlot, CharacterLegsSlot, CharacterFeetSlot,
CharacterFinger0Slot, CharacterFinger1Slot,
CharacterTrinket0Slot, CharacterTrinket1Slot,
CharacterMainHandSlot, CharacterSecondaryHandSlot
```

### Inventory Slot Constants
```
INVSLOT_HEAD=1, INVSLOT_NECK=2, INVSLOT_SHOULDER=3,
INVSLOT_BODY=4(shirt), INVSLOT_CHEST=5, INVSLOT_WAIST=6,
INVSLOT_LEGS=7, INVSLOT_FEET=8, INVSLOT_WRIST=9,
INVSLOT_HAND=10, INVSLOT_FINGER1=11, INVSLOT_FINGER2=12,
INVSLOT_TRINKET1=13, INVSLOT_TRINKET2=14, INVSLOT_BACK=15,
INVSLOT_MAINHAND=16, INVSLOT_OFFHAND=17, INVSLOT_TABARD=19
```

## WoW Stat Website SVG Icons

The website embeds inline SVGs for each stat. Key icon shapes:
- **Health**: Heart inside a rotated-square (diamond) border
- **Mana**: Potion/flask inside diamond
- **Intellect**: Lightbulb inside diamond
- **Stamina**: Plus/cross inside diamond
- **Crit**: Crosshair/target inside diamond
- **Haste**: Clock inside diamond
- **Mastery**: Crown/constellation inside diamond
- **Versatility**: Crossed swords inside diamond

Each diamond border is the same rotated-square frame; the inner icon and vertex color change per stat.
For our addon, these will be replicated as white-base TGA textures colored via `SetVertexColor()`.
