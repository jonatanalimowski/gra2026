# Arcane Rogue: Roadmap

> Top-down spellcasting roguelite (magical / dark fantasy) in Godot 4.5.
> **Core loop:** build a loadout from what you've unlocked → dungeon run, gambling on pacts → kill monsters and bosses → bring back materials and XP → unlock new options (Forge) and new run possibilities (Skill Tree) → repeat.

What's already built (build systems included) is in `CLAUDE.md`.

| Version | Theme | Goal | Status |
|---|---|---|---|
| **v0.11** | Foundation | One full playable floor that loops | ✅ |
| **v0.12** | Content & combat feel | A run stays interesting for 5+ minutes | ✅ mostly |
| **v0.13** | Meta progression I | Skill tree, saving, a reason to start another run | 🔧 **in progress** |
| **v0.14** | Meta progression II | The Forge: loot, crafting, new loadout options | 💭 |
| **v0.15+** | Polish & content | Balancing, juice, more of everything | 💭 |

## Where the project stands (2026-11-18)

The game feels good: replaying it doesn't get boring quickly, even against the same enemies. The build rework (A-F) is in: runs now pull toward a school, picks interact through statuses, and floors get stranger instead of just tankier. First playtests feel good. v0.13 has started: runs now pay out XP, levels give skill points, the post-run screen banks them, and the skill tree works with its first 2 nodes. Next is filling the tree.

- Stop polishing combat for its own sake. Hitstop and death bursts are side tasks for a quick win.
- Replay after each meta step and check that runs still feel this good.
- Small content (a pact, an enemy, a heavy spell) is still worth adding along the way.

## Design pillars

1. **A run is a build.** By floor 3 the player can *name* their build ("frost-storm shatter caster").
2. **Every pick is felt.** Pacts change what a verb does. Percentages live in glyphs and boss upgrades.
3. **Shared vocabulary.** Schools, statuses and verbs are the language. Every pact or glyph references at least one tag; weak pieces get more references.
4. **Pacts open doors, glyphs walk through them.** One pact per floor, always with a curse, and the only way into a school. Glyphs are free but only deepen what you already chose.
5. **Commitment pays, pivoting is possible.** Points → attunements, pairs → duos, wand + school → evolution. Slots can be overwritten.
6. **Curses shape play.** A curse changes how or what you fight; no plain stat taxes.
7. **The dungeon gets stranger, not just tankier.** Scaling comes from behavior: elites, affixes, waves, omens. Stronger enemies give more build fuel.
8. **Read the fight at a glance.** Every status and affix has an icon, a color and (if strong) a body effect. A flash means a hit, and nothing else.
9. **Meta progression is horizontal.** The tree and Forge unlock schools, duos, wands, omens and room types. Never flat stats.
10. **Mana is a per-floor resource earned by killing.** No regen. The Orb slot makes it a build axis.
11. **Difficulty is opt-in** (Oaths).

## Build rework (A-F) 🔧

*Goal: pacts interact, runs pull toward a playstyle.* How it works: `CLAUDE.md`. All six phases are implemented; next is a balance pass from playtests (glyph rate 30 vs 40%, curse load by floor 6, Brittle vs bosses).

- [x] A: status stacking + readability (Burn, Chill/Freeze, icon bar, outlines) - playtest pending
- [x] B: schools + verb slots (Ember & Frost: 10 slot pacts, Tier I) - playtest pending
- [x] C: glyphs + Sanctuary rework (14 glyphs, Tier II for Ember/Frost) - playtest pending
- [x] D: Storm & Blood (10 slot pacts, 8 glyphs, Tier I/II) - playtest pending
- [x] E: shrine payoffs (6 duos, 4 evolutions, rank II for all 20 slot pacts) - playtest pending
- [x] F: enemy scaling (floor retune, elite behaviors, 4 affixes, waves, omens, champion packs) - playtest pending

## v0.13: Skill Tree 🔧

*Goal: dying is no longer a full reset.*

- [x] Run summary (`PostRunScreen`: XP, kills, floor) + currency (XP -> levels -> skill points)
- [x] Save data (`MetaProgress`: XP, level, points, runs, unlocked skills)
- [x] Tree data and logic (`SkillData`, `SkillManager`, prerequisites, refund)
- [x] Tree screen (`SkillTreeUI`, pan camera, details panel)
- [ ] First 6-8 nodes (2 so far: Additional Health, Ricochet for Purple Bolt)
- [ ] UNLOCK_WEAPON / PASSIVE reward types
- [ ] Playtest

**Order:** run summary + currency → save data → tree data and logic → tree screen → first 6-8 nodes → playtest. The Hub comes later; it's only a menu until the Forge exists.

**Decisions (2026-11-01)**
- ~~**No "clear" yet.** Floors stay endless, every run pays out on death, and `best_floor` is the goal.~~ Replaced 2026-11-18 by Acts (see Design notes).
- **XP is credited directly on kill** (built as `experience_drop`, banked into levels and skill points after the run; first planned as "soul shards"). A second orb type would only add clutter. Elites and bosses pay more.
- **Summons pay 0 XP**, or Swarmers and JumperBoss can be farmed.
- **Ctrl+R should bank the run's XP.** It was earned by kills, so there's nothing to exploit. (Not yet: Ctrl+R skips `PostRunScreen`, so that run's XP is lost.)
- **Nodes are `SkillData` resources saved by id**, so moving files can't break a save. Done 2026-11-18: `MetaProgress.unlocked_ids`, `SkillManager.IsUnlocked`, `SkillDatabase`, rewards as `SkillReward` subclasses collected into the loadout at run start.
- **Existing pacts stay unlocked.** The pool is thin, so unlockable pacts are new ones.
- **No curse-free pacts from the tree** (pillar 1). Cleansing is fine, since you still take the curse first.

**Decisions (2026-11-18): tree layout**
- **5 paths:** one per school (Ember, Frost, Storm, Blood) + one Misc path (altar offers, rerolls, Sanctuary, wands...).
- **Schools are unlocked in the tree.** A school's root node unlocks it; the rest of its path upgrades it (new pacts/glyphs for that school, better attunements, school-specific runes).
- **Future schools (Hex, ...) sit behind existing schools** in the tree (e.g. Hex needs a node deep in Blood).
- **Schools are picked in the loadout:** before a run you choose which unlocked schools can appear. Altar/glyph/duo offers only roll from those. (Hint: needs a `RunState.allowed_schools` that `AltarRoom.RollOffers` / `GlyphShrine.RollOffers` / `UpgradeShrine.BuildOffers` filter on, and a `SchoolUnlockReward` = add a school id to `MetaProgress`. Decide a minimum, e.g. at least 2 schools, so offers don't run dry.)

**First nodes:** +1 altar offer, pact reroll, Sanctuary heal-or-cleanse, wand reroll, 2-3 "new pacts" nodes.

**Later nodes (toward 15-25):** visible curse trials, free cleanse per run, secret floors, new room types, new wands and enemies, Oaths, Descent, keystones that change play ("dash leaves a fire trail").

## v0.12 leftovers

- [x] ~~Heavy spell for Purple Saw Staff~~ (wand removed)
- [x] Form slot pacts (one per slot) so a save with no schools unlocked still fills its slots
- [x] Enemy scaling by *behavior*: elites with behaviors, affixes, waves, omens (new enemy types still missing)
- [ ] Treasure rooms: greater altar (pick 1 of 4), full mana, heal, reroll token
- [ ] HUD cooldowns for primary, heavy and dash
- [x] More pacts: 22 in the pool (20 slot + 2 Form), plus 22 glyphs, 6 duos, 4 evolutions
- [ ] More runes: Burn, Split, Chain Lightning
- [ ] Reward for refusing an altar (small heal or mana)
- [ ] More enemy roles (mortar/lobber, shielded tank, support healer, hazard layer) and a 3rd boss
- [x] Elite affixes and floor themes (omens)
- [ ] Arena and trap rooms

## Design notes

**Pacts**
- Prefer behavior changes to stats, in blessings and curses alike ("enemies explode on death", "every 3rd shot misfires").
- Make Legendary build-defining; consider `min_floor` so floor 1 doesn't decide the run.
- Mana is a good axis: "orbs give 50% mana", "heavies refund mana per kill".
- Highlight a card when it synergizes with your wand or runes.
- Watch enemy curses stacking unfairly by pact 8.

**Removing curses:** curse trials are the recommended route ("kill 40 enemies", a `RunEffect` that calls `CleanseCurse`). The Sanctuary choice is the other. The Skill Tree unlocks them, and the strongest curses should be `binding`.

**Oaths (opt-in difficulty):** curses with no blessing, sworn before a run for more rewards and unique unlocks. An Oath is just a `Curse` added with `RunState.AddHalf` after `Begin`, so it's cheap to build. Unlock after the first boss kill. A curse only works as an Oath if it makes sense without its blessing.

**Descent (tree unlock):** start at your deepest cleared floor, drafting one pact per skipped floor. (Superseded by Acts below: you pick an act instead.)

**Acts and run structure (decided 2026-11-18, replaces "No clear yet")**
- **An act = 3 distinct floors.** Before a run you pick which unlocked act to play (in the loadout / pre-run screen).
- **Each floor gets harder, and enemy pools are set per floor, not per room:** floor 1 = pool A, floor 2 = A + B, floor 3 = B + C. (Hint: an `ActData` resource with `floors: Array[FloorData]`, each `FloorData` holding its `EnemyPool`s + `FloorModifier`; `EnemyRoom.enemy_pools` goes away and rooms ask `RunState` for the floor's pool.)
- **Beating floor 3's boss = act cleared** (`EndRun(true)`, finally used). The shrine then offers **End run** (victory, bank everything) or **Descend further**.
- **Descending (endless):** enemies from all 3 floors mixed, scaling more aggressive than in the act, drops (XP, later materials) multiply the deeper you go. Push-your-luck: leave at any boss shrine.
- **Further acts unlock by beating the previous one** (`MetaProgress.acts_cleared`), not with skill points. Each act is slightly harder (its own base `FloorModifier`) and has its own pools/tint.
- **Materials (v0.14):** banked fully on victory or leaving; dying keeps a share (e.g. 50%). Deeper/later-act materials drop from bosses and elites, so starting a later act is how you farm them, not grinding floor 1.
- Fits pillar 1: later acts are harder, stronger Forge options are how you keep up; act 1 with a plain loadout stays the baseline.

## v0.14: The Forge 🔨

*Goal: enemies drop loot, and you craft new loadout options. **Not stronger, but different.***

**Order:** materials + inventory → blueprints found in runs → crafting → variants → Forge and Loadout screens (`ForgeUI.tscn` layout exists, reuse `StatsCard`).

- **Content:** armor (Mage Robes: fast, fragile, more mana; Plate Mail: slow, tanky), rings and amulets, scrolls (blink, decoy).
- **Sidegrades, not upgrade levels** ("Purple Bolt: Scatter", "Purple Bolt: Lance"). Every item needs a tradeoff, and should be flashy since it can't be stronger.
- **Materials:** 2-3 tiers tied to floor depth and Oath rank. Every run, even a failed one, should be a visible step forward.
- **Prep (same rule as the skill tree: save ids, derive everything):** `MetaProgress` holds `owned_wand_ids`, `owned_rune_ids`, `materials: {id: count}` and saved loadouts as plain dicts (`{wand: id, runes: [ids], armor: id}`). An `ItemDatabase` (like `SkillDatabase`) turns ids back into resources, `InventoryManager.GetWands()` returns owned wands. Equipping a rune adds an id, never edits `WandData.runes`. `GameFlow.StartRun` stays the one place that builds the run: saved loadout -> `Loadout` -> `SkillManager.CollectRewards`. Weapon unlocks = a `WeaponUnlockReward` (`SkillReward` subclass).

## v0.15+: Polish and ideas ✨

- **Polish:** hitstop, death particles, music, boss intros, balance pass, keybinds, screenshake toggle, controller, first-run hints.
- **Ideas:** elemental interactions, named synergies, daily seed runs, codex, NPC events (merchant, gambler, cursed chest), loadout presets.

## Open risks

- **Pact pool depth.** 22 pacts + glyphs now, but only 5 enemy types: variety on the enemy side is the thinner one.
- **Boss-fight mana.** CasterBoss has no adds, so a spent heavy stays spent. If that feels bad, drop orbs at HP thresholds; don't carry mana over.
- **Saving mana for the boss** must not become "never use heavies on the floor". If it does, make elites drop more orbs.
- **Refusing pacts must stay viable.** Boss upgrades alone should carry a skilled player a few floors.
- **Dash i-frames are generous.** Keep them short and add hazards dashing can't skip.
- **Curse removal can erase the risk.** Keep it costly.
- **Forge scope and grind.** It's the hardest system, so follow the order and avoid exact-number recipes.
- **Mix-and-match becoming solved or overwhelming.** Unlock slots gradually; use forced-loadout Oaths, dailies and first-clear bonuses.
