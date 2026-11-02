# Arcane Rogue: Glossary

Short definitions of the game's terms. Details and numbers: `BUILD_SYSTEMS.md`, architecture: `CLAUDE.md`.

## Run structure
- **Run**: one attempt from the PreRunScreen to death. Floors are endless.
- **Floor**: one generated dungeon (start room → combat rooms → boss room, plus side branches). `RunState.floor_number`.
- **Loadout**: what you pick before a run (wand, later armor/scroll). `RunState.loadout`.
- **Wand**: your weapon. **Primary** (LMB) and **Heavy** (RMB, costs mana) spells. Each wand has a **school affinity**.
- **Mana**: per-floor resource from **mana orbs** dropped by kills; heavies spend it. No regen.

## Pacts and builds
- **Pact**: an altar reward = a **blessing** + a **curse**. 1 altar per floor, pick 1 of 3.
- **Half / PactHalf**: one side of anything that changes the run (blessing, curse, glyph, tier, duo, omen...). Added/removed through `RunState`.
- **Blessing / Curse**: the good / bad half. A **binding** curse can't be cleansed. **Cleanse** = remove a curse.
- **School**: Ember, Frost, Storm, Blood, plus neutral **Form**. Each school owns a status.
- **Verb slot**: Primary, Heavy, Dash, Kill, Orb. One pact per slot; a new one **replaces** the old (blessing and curse).
- **Slot pact / Form pact**: a pact that fills a slot / a slotless projectile-shape pact (Multishot, Homing).
- **School points**: slot pact = 2, glyph = 1 per stack.
- **Attunement / Tier**: a school bonus at 4 points (Tier I) and 8 (Tier II).
- **Glyph**: a small free buff dropped by some room clears; only for schools you own a pact of, or Form.
- **Pity**: +10% glyph chance per room cleared without one.
- **Duo**: a boss-shrine reward for owning two schools.
- **Evolution**: a boss-shrine upgrade of your wand's primary (needs Tier I of the wand's school).
- **Deepen / Rank II**: a boss-shrine upgrade of one slot pact's blessing (same curse).
- **Stat upgrade**: Vigor / Power / Quick Cast at the boss shrine, curse-free. **Flawless** fight = 2 picks.
- **Sanctuary**: rest room, +10 max HP for the run and a 40% heal.
- **Oath**: a curse taken on purpose for rewards (planned).

## Statuses
- **Stack**: how many times a status is applied; more stacks = stronger (up to max stacks).
- **Burn** (Ember): damage over time. **Chill** (Frost): slow; at max stacks → **Freeze** (stunned 1.5s, then immune). Bosses get **Brittle** (take more damage) instead.
- **Shock** (Storm): the next hit **discharges** it into an **arc** that hits nearby enemies.
- **Bleed** (Blood): damage over time that grows with your missing HP. **Blood mote**: heal-only orb.
- **Tick**: one damage pulse of a status. Ticks show small colored numbers and never flash the sprite.
- **Ward / Warded**: immune to one school's statuses.
- **Empowered**: Lifeblood's short damage buff. **Barrier**: Sanguine's overheal shield. **Shield**: Hoarfrost's hit block.

## Enemies
- **Elite**: tougher, bigger, tinted enemy with its own behavior; drops double mana and raises the glyph chance.
- **Affix**: an extra trait on an elite (Volatile, Hasted, Warded, Regenerating), gold-framed in its icon bar.
- **Champion pack**: an elite and 3 copies sharing its affix (floor 5+).
- **Second wave**: a room that spawns again after you clear it (floor 3+).
- **Omen**: one rule for a whole floor (floor 2+), shown under the floor label.
- **Telegraph**: the warning before an attack (the "!" above the head, blinking circles).
- **Hitstun**: a short brain pause after being pushed.
