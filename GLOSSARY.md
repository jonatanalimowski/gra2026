# Arcane Rogue: Glossary

Shared words for design talk, code and UI text. When a term has a code name, it's in `code`.
Status: ✅ in the game · 🛠 partly there · 💭 planned (see `ROADMAP.md`).

---

## Pacts & curses

| Term | Meaning | Code |
|---|---|---|
| **Pact** ✅ | A deal offered at an altar: one **blessing** + one **curse**, taken together or not at all. The risky in-run upgrade that shapes your build (the safe one is the boss **stat upgrade**). Taking one is always optional. | `AltarPact` (`Data/Altars/`) |
| **Half / pact half** ✅ | Either side of a pact. Each half is its own resource, so it can be added or removed alone. It holds player modifiers, projectile effects, run effects, enemy modifiers and flags. | `PactHalf` |
| **Blessing** ✅ | The good half of a pact. The only curse-free blessings are boss **stat upgrades**; there are no other standalone blessing rewards. | `Blessing` (`Data/Blessings/`) |
| **Curse** ✅ | The bad half of a pact. Can be **cleansed**, unless it's **binding**. It's also what an **oath** is made of. | `Curse` (`Data/Curses/`) |
| **Pact type** ✅ | What a pact's blessing improves: **SELF** (you), **SPELL** (your projectiles), **ENEMY** (hurts or weakens enemies). Shown as an icon on cards and in the HUD. Curses have no type, by design. | `PactType.Type`, `Blessing.type` |
| **Cleanse** 🛠 | Removing an active curse for the rest of the run. Its blessing stays. The HUD shows the pact in the buff color after that. Every cleanse goes through one function. Logic done; no in-game source yet (dev button only). | `RunState.CleanseCurse(curse)` |
| **Broken curse** 🛠 | A curse that has been cleansed. Kept in a list for the HUD and the end-of-run summary. | `RunState.cleansed_curses` |
| **Binding curse** 🛠 | A curse that can't be cleansed. Used to keep the strongest pacts honest, and for oaths. | `Curse.binding` |
| **Curse trial** 💭 | An optional break condition on a curse ("kill 40 enemies", "clear 3 rooms without getting hit"). A run effect that counts events, then cleanses the curse. | `RunEffect` → `CleanseCurse` |
| **Flag** ✅ | A simple on/off rule a half turns on, checked by name wherever it matters. Good for curses that change rules instead of numbers ("no healing in Sanctuaries"). | `PactHalf.flags`, `RunState.HasFlag()` |
| **Oath** 💭 | A curse you swear before a run, in the Hub, with no blessing. Opt-in difficulty: each oath has a rank, and a higher total rank gives more rewards. Reuses `Curse` resources, usually binding. | `RunState.AddHalf(curse)` at run start |
| **Oath rank** 💭 | How hard an oath is. Your total rank sets reward multipliers and rank-based unlocks. | – |
| **Pact rarity** ✅ | Rare / Epic / Legendary (70/20/10%). Each altar offer rolls a rarity, then a weighted pact within it. Shown as a colored subtitle on the card. | `PactRarity`, `AltarPact.rarity` |
| **Stacking pact** ✅ | A pact that can be taken again; each stack adds its halves once more. | `AltarPact.is_stacking` |
| **Greater altar** 💭 | Treasure-room altar: pick 1 of 4, or pacts with weaker curses. | – |
| **Refusal reward** 💭 | A small gift (heal, mana) for walking away from an altar, so saying no is a real choice. | – |

### Active vs. taken
- **Taken pacts** = everything you picked this run (`RunState.pacts`). Used for the HUD list and so a pact isn't offered twice.
- **Active halves** = the blessings and curses currently in effect (`RunState.halves`). Pacts, oaths and anything later all end up here. Cleansing removes a curse from this list but not the pact from `pacts`.

---

## Run & world

| Term | Meaning | Code |
|---|---|---|
| **Run** ✅ | One attempt, from leaving the Pre-Run screen until death or the end. | `RunState` |
| **Floor** ✅ | One generated dungeon level, ending in a boss room. Endless for now; each floor has a few more rooms. | `RunState.floor_number`, `DungeonGenerator` |
| **Seed** ✅ | The number every floor layout comes from. Ctrl+R keeps it (same floors) or rolls a new one. | `RunState.run_seed`, `GetFloorSeed()` |
| **Room types** ✅ | **Combat** (doors lock, enemies), **Rest / Sanctuary** (heal shrine), **Shrine** (altar), **Treasure** (💭 no scene yet), **Boss**. | `RoomData.room_type` |
| **Altar** ✅ | The interactable in a Shrine room (one guaranteed per floor) that offers pacts (pick 1 of N, or leave). N = 2 + meta bonuses. | `AltarRoom` |
| **Sanctuary** ✅ | The rest room: a heal shrine. Planned: heal *or* cleanse a curse. | `RestRoom` |
| **Upgrade Shrine / stat upgrade** ✅ | Spawns where the boss died: pick a stat upgrade (Vigor +10 max HP, Power +10% damage, Quick Cast +10% fire rate), always stacks, no curse. 2 picks after a **flawless** fight (no damage taken). Taking it starts the next floor. | `UpgradeShrine`, `StatUpgrade` (`Data/StatUpgrades/`) |
| **Flawless** ✅ | Beating a boss without taking damage. Doubles the Upgrade Shrine picks. | `BossRoom.flawless_picks` |
| **Enemy pool** ✅ | A weighted list of enemy scenes; each combat room rolls one pool on entry. | `EnemyPool` (`Data/EnemyPools/`) |
| **Main path / branch** ✅ | Main path = start → combat rooms → boss. Branches lead to reward rooms. | `DungeonGenerator` |
| **Descent** 💭 | Skill tree unlock: start deeper, drafting one pact per skipped floor. | – |
| **Secret floor** 💭 | A floor with a different room pool and look, reached through a hidden room or a pact. | – |

---

## Character & combat

| Term | Meaning | Code |
|---|---|---|
| **Loadout** ✅ | What you start a run with: wand, equipment, scroll. Picked before the run (for now: 1 of 3 wands). | `Loadout` |
| **Wand** ✅ | Your weapon. Holds a **primary** spell (LMB) and a **heavy** spell (RMB). 4 wands so far. | `WandData`, `Wand` |
| **Spell** ✅ | What a wand fires: projectile, damage, cooldown, spread, shot count. | `SpellData`, `SpellCaster` |
| **Heavy spell** ✅ | The RMB spell, paid with **mana** (e.g. Flame Shuriken: 3 exploding shurikens for 100 mana). Purple Saw Staff has none yet. | `Wand.heavy`, `SpellData.mana_cost` |
| **Mana** ✅ | 0-100 bar filled by **mana orbs** that enemies drop on death, spent on heavy spells. Doesn't regenerate, resets to 0 every floor (save it for the boss or spend it now). | `Player.mana`, `AddMana`, `PlayerStats.max_mana` |
| **Mana orb** ✅ | Pickup dropped on death (`mana_drop` stat, ~5 mana each): scatters, then flies to the player. | `ManaOrb` |
| **Rune** ✅ | Changes a spell: stat modifiers and/or effects (Bounce, Pierce). | `RuneData` |
| **Scroll / mobility** ✅ | The Shift ability. Dash for now. | `ScrollData`, `MobilityAbility`, `DashAbility` |
| **Equipment** 🛠 | Armor, rings, amulets: base stat changes and passive effects. | `EquipmentData` |
| **Dodge** ✅ | While dashing you're invulnerable and projectiles fly through you. | `Player.IsDodging()` |
| **Knockback / hitstun** ✅ | Hits push enemies and briefly stop their AI, with an immunity window after. | `EntityBase.ApplyKnockback`, `IsStunned()` |
| **Elite** ✅ | A bigger, tinted version of a normal enemy (~8% of spawns) with more HP, damage and speed. | `EliteData` (`Data/Elites/`), `Entity.is_elite`, `EnemyRoom.elite_chance` |
| **Affix** 💭 | A random extra trait on an elite (shielded, explodes on death, split). | – |

---

## Under the hood

| Term | Meaning | Code |
|---|---|---|
| **Stat block** ✅ | Runtime stats copied from a resource, so the `.tres` is never changed. | `StatBlock` |
| **Stat modifier** ✅ | A flat + multiplier change to one stat. It's added together with a **source** and removed by that source. A pact half is its own source. | `StatModifier`, `AddModifier` / `RemoveModifiersFrom` |
| **Effect** ✅ | A projectile hook (on spawn, every physics frame, on hit, on wall, modify damage). Bounce, Pierce, Ricochet, Vampiric, Exploding, Homing. | `Effect` |
| **Motion** ✅ | The path a projectile flies: straight, sine, random wiggle. One per projectile, set on its stats. | `ProjectileMotion`, `SineMotion`, `RandomMotion` |
| **Run effect** ✅ | An event hook for the whole run (on kill, on hit taken, on room cleared). Gets `OnAdded` / `OnRemoved` when its half comes and goes. | `RunEffect` |
| **Damage info** ✅ | Everything about one hit: amount, source, crit, element, knockback. | `DamageInfo` |
| **Item** ✅ | Anything with a name, icon and description that can be shown on a choice card. | `ItemData` |

---

## Meta progression (between runs)

| Term | Meaning | Code |
|---|---|---|
| **Hub** 🛠 | The between-runs screen: Run, Forge, Skill Tree, Oath altar. Layout only. | `NewMainUI.tscn` |
| **Forge** 💭 | Crafting new loadout options from materials. Horizontal: new choices, not more power. | `ForgeUI.tscn` (layout) |
| **Materials** 💭 | Loot dropped in runs, spent in the Forge. Tiers by floor depth. | – |
| **Blueprint** 💭 | A boss or elite drop that permanently unlocks a Forge recipe. | – |
| **Variant / sidegrade** 💭 | A crafted version of an item that plays differently but isn't stronger ("Purple Bolt: Scatter"). | – |
| **Skill Tree** 💭 | Unlocks things that happen *in* runs (more choices, rerolls, cleansing, oaths). No flat stats. | – |
| **Keystone** 💭 | A skill tree node that changes how you play ("dash leaves a fire trail"). | – |
| **Meta progress** 🛠 | The saved data: unlocks, currencies, best floor, oath rank. Autoload exists and saves to `user://meta_progress.cfg`, only holds the altar offer bonus so far. | `MetaProgress` |
