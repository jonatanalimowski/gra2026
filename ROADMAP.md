# Arcane Rogue: Roadmap

> Top-down spellcasting roguelite (magical / dark fantasy) in Godot 4.5.
> **Core loop:** build a loadout from what you've unlocked → dungeon run, gambling on pacts → kill monsters and bosses → bring back materials and XP → unlock new options (Forge) and new run possibilities (Skill Tree) → repeat.

What's already built is in `CLAUDE.md`; the build systems (schools, slots, glyphs, boss shrine, enemy scaling) are documented in `BUILD_SYSTEMS.md`; terms are in `GLOSSARY.md`.

| Version | Theme | Goal | Status |
|---|---|---|---|
| **v0.11** | Foundation | One full playable floor that loops | ✅ |
| **v0.12** | Content & combat feel | A run stays interesting for 5+ minutes | ✅ mostly |
| **v0.13** | Meta progression I | Skill tree, saving, a reason to start another run | ⏭ **next** |
| **v0.14** | Meta progression II | The Forge: loot, crafting, new loadout options | 💭 |
| **v0.15+** | Polish & content | Balancing, juice, more of everything | 💭 |

## Where the project stands (2026-11-02)

The game feels good: replaying it doesn't get boring quickly, even against the same enemies. The build rework (A-F) is in: runs now pull toward a school, picks interact through statuses, and floors get stranger instead of just tankier. First playtests feel good. But nothing carries between runs, and that will make the fun stop after a few hours. So v0.13 is next.

- Stop polishing combat for its own sake. Hitstop and death bursts are side tasks for a quick win.
- Replay after each meta step and check that runs still feel this good.
- Small content (a pact, an enemy, a heavy spell) is still worth adding along the way.

## Design pillars

From `BUILD_DESIGN.md` §11 (2026-11-02).

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

*Goal: pacts interact, runs pull toward a playstyle.* Design: `BUILD_DESIGN.md`. What was built and how it works: `BUILD_SYSTEMS.md`. All six phases are implemented; next is a balance pass from playtests (glyph rate 30 vs 40%, curse load by floor 6, Brittle vs bosses).

- [x] A: status stacking + readability (Burn, Chill/Freeze, icon bar, outlines) - playtest pending
- [x] B: schools + verb slots (Ember & Frost: 10 slot pacts, Tier I) - playtest pending
- [x] C: glyphs + Sanctuary rework (14 glyphs, Tier II for Ember/Frost) - playtest pending
- [x] D: Storm & Blood (10 slot pacts, 8 glyphs, Tier I/II) - playtest pending
- [x] E: shrine payoffs (6 duos, 4 evolutions, rank II for all 20 slot pacts) - playtest pending
- [x] F: enemy scaling (floor retune, elite behaviors, 4 affixes, waves, omens, champion packs) - playtest pending

## v0.13: Skill Tree ⏭

*Goal: dying is no longer a full reset.* Checklist: `SKILL_TREE_PLAN.txt`.

**Order:** run summary + currency → save data → tree data and logic → tree screen → first 6-8 nodes → playtest. The Hub comes later; it's only a menu until the Forge exists.

**Decisions (2026-11-01)**
- **No "clear" yet.** Floors stay endless, every run pays out on death, and `best_floor` is the goal.
- **Soul shards are credited directly on kill**, from a `shard_drop` stat. A second orb type would only add clutter. Elites and bosses pay more.
- **Summons pay 0 shards**, or Swarmers and JumperBoss can be farmed.
- **Ctrl+R banks the run's shards.** They were earned by kills, so there's nothing to exploit.
- **Nodes are `SkillNode` resources saved by id**, so moving files can't break a save. Check them with `MetaProgress.HasUnlock(&"...")`.
- **Existing pacts stay unlocked.** The pool is thin, so unlockable pacts are new ones.
- **No curse-free pacts from the tree** (pillar 1). Cleansing is fine, since you still take the curse first.

**First nodes:** +1 altar offer, pact reroll, Sanctuary heal-or-cleanse, wand reroll, 2-3 "new pacts" nodes.

**Later nodes (toward 15-25):** visible curse trials, free cleanse per run, secret floors, new room types, new wands and enemies, Oaths, Descent, keystones that change play ("dash leaves a fire trail").

## v0.12 leftovers

- [x] Heavy spell for Purple Saw Staff (via heavy slot pacts; it still has no heavy of its own)
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

**Descent (tree unlock):** start at your deepest cleared floor, drafting one pact per skipped floor.

## v0.14: The Forge 🔨

*Goal: enemies drop loot, and you craft new loadout options. **Not stronger, but different.***

**Order:** materials + inventory → blueprints found in runs → crafting → variants → Forge and Loadout screens (`ForgeUI.tscn` layout exists, reuse `StatsCard`).

- **Content:** armor (Mage Robes: fast, fragile, more mana; Plate Mail: slow, tanky), rings and amulets, scrolls (blink, decoy).
- **Sidegrades, not upgrade levels** ("Purple Bolt: Scatter", "Purple Bolt: Lance"). Every item needs a tradeoff, and should be flashy since it can't be stronger.
- **Materials:** 2-3 tiers tied to floor depth and Oath rank. Every run, even a failed one, should be a visible step forward.

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
