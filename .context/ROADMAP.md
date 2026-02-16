# ProfilePanel — Roadmap

## Completed

- [x] Project directory structure
- [x] `.toc` manifest (Retail 120001)
- [x] Core namespace and constants (`core/core.lua`)
- [x] Event system with lifecycle events (`core/events.lua`)
- [x] Full stat API with 3-tier system — 18 stats total (`core/api.lua`)
- [x] Main frame with CharacterFrame hook and layout regions (`ui/frame.lua`)
- [x] Character header with name, class/spec, ilvl (`ui/header.lua`)
- [x] 3D character model with mouse-drag rotation (`ui/model.lua`)
- [x] Equipment slot layout with ilvl badges and enchant/gem warnings (`ui/equipment.lua`)
- [x] Stat card grid with colored icons, 3-tier layout, card pooling (`ui/stats.lua`)
- [x] Directory junction to WoW AddOns folder for live testing
- [x] Cursor rules for the project
- [x] Hide Blizzard CharacterFrame chrome (NineSlice, portrait, title, tabs)
- [x] Custom dark frame with subtle border and close button
- [x] Web armory-style header (title, name, achv points, ilvl, guild, realm)
- [x] Stats moved to vertical single-column panel on right side with ScrollFrame
- [x] Enhanced equipment display (item names, enchant text, gem icons per slot)
- [x] ILVL removed from stat cards (now in header)

## Next Steps (Priority Order)

### Polish & Bug Fixes
- [ ] Test in-game, fix any load errors or layout issues
- [ ] Adjust frame sizing and element positioning based on actual rendering
- [ ] Handle edge cases: no spec selected, no items equipped, in combat
- [ ] Tune stat card colors against actual WoW dark backgrounds
- [ ] Add tooltip on stat card hover (show rating breakdown, like CCS does)

### Custom Textures (the diamond icon upgrade)
- [ ] Create `stat-frame.tga` — white diamond (rotated square) border, 64×64 or 128×128
- [ ] Create stat icon TGAs — simplified versions of the website SVG inner icons (heart, potion, lightbulb, cross, crosshair, clock, crown, swords)
- [ ] Wire textures into `ui/stats.lua` replacing the colored-square placeholders
- [ ] Use `SetVertexColor()` on white-base textures for per-stat coloring

### Settings Panel
- [ ] Saved variables for user preferences
- [ ] Toggle: enable/disable ProfilePanel (fall back to default character frame)
- [ ] Font size slider
- [ ] Option to show/hide specific tertiary stats
- [ ] `/pp` slash command

### Future Features
- [ ] Inspect frame support (view other players' gear)
- [ ] Stat comparison on gear hover (current vs. equipped)
- [ ] Gear set integration
- [ ] Export character summary to clipboard (text format)
- [ ] GitHub repo creation and CI/release setup

## Won't Do (out of scope)

- Mythic+ tracking panel (use dedicated addons)
- Raid stats panel
- Classic / TBC / MOP support
- Background animations
- Profile import/export
- Heavy settings UI (keep it minimal)
