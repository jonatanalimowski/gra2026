# Arcane Rogue: Roadmap

> Top-down spellcasting roguelite (magical / dark fantasy) in Godot 4.5.
> **Core loop:** build a loadout from what you've unlocked → dungeon run, gambling on pacts → kill monsters and bosses → bring back materials and XP → unlock new options (Forge) and new run possibilities (Skill Tree) → repeat.

| Version | Theme | Goal | Status |
|---|---|---|---|
| **v0.11** | Foundation | One full playable floor that loops | ✅ |
| **v0.12** | Content & combat feel | A run stays interesting for 5+ minutes | ✅ mostly (see leftovers) |
| **v0.13** | Meta progression I | Skill tree, saving, a reason to start another run | ⏭ **next** |
| **v0.14** | Meta progression II | The Forge: loot, crafting, unlocking new loadout options | 💭 |
| **v0.15+** | Polish & content | Balancing, juice, more of everything | 💭 |

---

## Where the project stands (2026-10-30)

**Playtest verdict:** the game feels good. Replaying it over and over, even against the same enemies, doesn't get boring quickly. That's the hardest thing to get right in a roguelite and it's there now: the moment-to-moment loop (shoot, dodge, pick up mana, blow it on a heavy, gamble on pacts) carries itself.

**What this means for priorities:**
- The "killing is boring" problem from `COMBAT_PLAN.md` is solved well enough. Stop polishing combat for its own sake; keep it as a side track (hitstop, death bursts) for when you want a quick win.
- The core is fun **within** a run, but nothing carries **between** runs yet. Dying = full reset, and floors are endless with no "win". That's now the biggest gap: it's what will make the fun stop after a few hours. So **v0.13 (saving + a reason to start another run) is next**, before more content.
- Protect what works. When adding meta systems, re-play after each step and check that runs still feel this good (the pillars below exist for exactly that).
- Small content additions (a pact, an enemy, a heavy spell) are still cheap and keep the game fresh for *you* while building the bigger systems. Sprinkle them in.

---

## Design pillars (2026-10-28, revised 2026-10-30 to match the game)

1. **In-run power has two sources: pacts and boss rewards.**
   - **Pacts** shape the *build*: every blessing comes with a curse, they're always optional, and they're where behavior changes come from (homing, piercing, explosions...).
   - **Boss Upgrade Shrines** are the *safe, skill-earned* growth: a small flat stat upgrade (+max HP / +damage / +fire rate) with no curse, doubled for a flawless fight. They keep up with floor difficulty and reward playing well, while pacts reward taking risks.
   - No other standalone blessings (no blessing drops in rooms). A blessing without a curse only exists as a boss stat upgrade.
2. **Meta progression is horizontal, not vertical.** The Forge unlocks *more starting choices* (wands, runes, scrolls, armor, rings) to mix and match. They change how you play, not how strong you start. (In-run vertical growth from boss upgrades is fine; it resets every run.)
3. **The Skill Tree unlocks things that happen in runs:** more choices, rerolls, secret floors, ways to remove curses. It doesn't give flat stats.
4. **Mana is a per-floor resource earned by killing.** Enemies drop mana orbs that fly to you (0-100 bar), heavy spells spend it, and it **resets to 0 every floor**. So each floor has its own "spend it in fights or save it for the boss" decision, and nothing carries over to snowball.
5. **Difficulty is opt-in** (see "Difficulty & early-run pacing"). The base game shouldn't get easier just because you've played a lot.

---

## What's in the game now ✅

**Run flow**
- Main Menu (with Settings) → Pre-Run screen (pick 1 of 3 wands) → run → back to Pre-Run on death
- Ctrl+R restart (same loadout, new seed); Esc = settings mid-run
- Endless floors: the boss drops an Upgrade Shrine (+10 max HP / +10% damage / +10% fire rate, stacks; **2 picks on a flawless boss fight**), taking it starts the next floor. Each floor has a few more rooms

**World**
- Seeded dungeon generator: start → main path of combat rooms → boss room, side branches with reward rooms, occasional loops
- Room types: Combat, Rest (Sanctuary heal shrine), Shrine (Altar room, guaranteed once per floor), Boss; Treasure exists as a type, no scene yet
- Weighted enemy pools per room (Mixed, Skeletons, Slimes, SlimesTurnips, TurnipsShooters)
- Fog-of-war minimap, shared 0x72-style tileset with floor variation

**Combat**
- 4 wands (Blue Blinker, Flame Shuriken, Purple Bolt, Purple Saw Staff), LMB primary spells
- **Heavy spells (RMB) + mana** on 3 wands (Purple Saw Staff has none yet). Enemies drop mana orbs that home in on you
- Runes: Bounce, Pierce; projectile effects: Bounce, Pierce, Ricochet, Vampiric, Exploding, Homing
- Projectile paths (motions): straight, sine (Blue Blinker), random wiggle (unused)
- Shift dash with i-frames (projectiles fly through)
- Knockback, hitstun with stun immunity window, crits, damage numbers, screen shake on explosions
- Enemies: Slime (jumper), Skeleton (circles you, telegraphed charge), Shooter Skeleton, Turnip swarmer (summons mini copies)
- **Elites:** ~8% of spawns, bigger + tinted, x2.5 HP and more damage/speed (`EliteData`, per-enemy override e.g. Shooter Skeleton)
- **2 bosses:** Slime King (jumps, super jumps, summons, enrage) and Skeleton (bullet-hell rings, snipes, bombs, enrage)
- Corpses with death animations

**In-run upgrades**
- 9 altar pacts with rarities (Rare / Epic / Legendary): Swiftness, Vampiric, Volatile, Exploding Shots, Multishot, Rebound, Piercing, Keen Eye, Homing. Blessing + curse as separate resources, curses cleansable (dev only), stacking pacts
- Run effects: Explode on Kill

**Tech / UI**
- StatBlock + StatModifier stat system, Effect / RunEffect hooks, global Signals bus
- HUD (HP, mana, spell slots, Tab stat lists, boss bar, pact list), generic pick-1-of-N ChoiceOverlay, item stats overlay
- Sound system (`Sfx`), volume settings saved to disk
- `MetaProgress` autoload exists and saves (only `altar_offer_bonus` so far)
- Dev tools (F6 panel, F7 altar offer, invincible, x10 damage, all elites, teleport to boss, cleanse curses)

---

## v0.12 leftovers (do alongside v0.13)

Most of v0.12 shipped. What's left, roughly by value:
- [ ] **Heavy spell for Purple Saw Staff** (every wand should have one now that mana exists)
- [ ] **Watch boss-fight mana (tuning, not a redesign).** Saving mana from the floor for the boss is the intended play (pillar 4). The Skeleton boss has no adds, so a heavy you already spent stays spent. If that feels bad, have bosses drop a few orbs at HP thresholds; don't carry mana between floors
- [ ] **Enemy scaling with floors.** Right now only room count grows. Prefer *new behavior* (more elites, new enemy types at deeper floors, enemy pools by depth) over pure HP inflation
- [ ] **A way to cleanse in-game** (Sanctuary choice or curse trials; only a dev button so far)
- [ ] **Treasure rooms.** Give the type a scene: greater altar (pick 1 of 4), full mana, heal, reroll token
- [ ] **HUD cooldowns** for primary, heavy and dash
- [ ] **More pacts.** 9 now; aim for ~15, then 30+. Especially behavior-changing ones and `OnEnemyKilled` / `OnRoomCleared` ones (only Explode on Kill uses those hooks)
- [ ] **More runes** (Burn, Split, Chain Lightning) - they matter more once the Forge exists
- [ ] **Reward for refusing** an altar (small heal or mana), so walking away is a real choice
- [ ] 2-3 more enemy roles (see suggestions) and a 3rd boss

### Enemy role suggestions
- *Swarmer*: turnip ✅
- *Charger*: skeleton ✅
- *Ranged*: shooter ✅, maybe a mortar/lobber that fires telegraphed AoE (reuse `Explosion`)
- *Tank / shielded*: a frontal shield you need Bounce/Ricochet or flanking to beat
- *Support*: buffs or heals nearby enemies, a priority target
- *Area denial*: leaves hazards (poison puddles, fire trails)

### Other ideas
- **Elite affixes.** Elites are stat boosts now. Add 1 random affix (exploding shots, split on death, shielded) for variety; can reuse pact curse modifiers
- **Floor themes.** Even just a tint and a different enemy table per floor makes looping feel like progress
- **Room variety.** Arena events (survive waves for 30s), trap rooms, a cursed room with a better reward

---

## Pact design

Since pacts are the only in-run growth, their design matters most:

- **Pacts that change behavior, not just stats.** In the SPELL category, pacts can *grant rune effects* ("your projectiles split, but fire 30% slower"). Homing, Rebound, Piercing and Exploding already do this, and they're the most fun ones. Keep going in that direction.
- **Curses that change play, too.** "-10% damage" is boring to have. "Enemies explode on death", "you can't heal in Sanctuaries", "every 3rd shot misfires", "dash cooldown doubled but dash damages" are memorable.
- **Rarity tiers** ✅. Next: make Legendary feel legendary (build-defining), and consider `min_floor` so floor 1 doesn't decide the whole run.
- **Mana pacts** are a new axis now that mana exists: curse "orbs give 50% mana", blessing "heavy spells refund mana per kill", "mana orbs heal 1".
- **Show synergies.** When a pact interacts with your wand/runes, give its card a small highlight.
- **Watch curse stacking.** By pact 8, the enemy curses together may produce unfair combinations. Cap enemy-side curses or let cleansing keep the list short.

---

## Architecture: removable curses ✅

Done (2026-10-28). Terms are in `GLOSSARY.md`.

```
AltarPact (ItemData, Data/Altars/)     PactHalf (Resource)
├─ blessing: Blessing                  ├─ display_name, description
├─ curse:    Curse                     ├─ player_modifiers / spell_modifiers
├─ rarity, weight, min_floor           ├─ effects / run_effects
└─ is_stacking                         ├─ enemy_modifiers
                                       └─ flags   # RunState.HasFlag(&"...")
Blessing extends PactHalf (+ type)     Curse extends PactHalf (+ binding)
Data/Blessings/*.tres                  Data/Curses/*.tres
```

- `RunState.halves` is the one list of active blessings + curses. `AddPact` adds both halves; `AddHalf` / `RemoveHalf` work on one (oaths and Upgrade Shrine stat upgrades call `AddHalf` directly).
- Each half is the **source** of its own modifiers, so `RemoveModifiersFrom(half)` takes back exactly what it gave.
- Player and enemies apply all halves on spawn and listen to `half_added` / `half_removed`, so live enemies update right away.
- `RunState.CleanseCurse(curse)` is the single entry point (refuses binding curses), fills `cleansed_curses`, emits `curse_cleansed`. HUD shows a pact with a broken curse in the buff color.
- Curses that change rules use **flags** (Reckless Blast: `explosions_hit_player`).

**Design note:** a curse should make sense on its own if it will ever be an oath. "Reckless Blast" does nothing without its blessing. Fine for a pact curse, but keep it out of the oath pool.

**Ways to remove a curse (gameplay):**
- **Curse trials (recommended).** Each curse has an optional break condition ("kill 40 enemies", "beat the boss flawless"). A `RunEffect` that counts events and calls `CleanseCurse`. Turns curses into small quests.
- **Sanctuary choice.** The rest room offers *heal* OR *cleanse one curse*.
- **Skill tree unlocks** these options. Removing curses is a reward you earn, not the default.
- Some curses should be **binding** to keep the strongest pacts honest.

---

## Difficulty & early-run pacing

**The problem:** stacking upgrades makes runs easy, especially the start, once you've played a lot.

**What doesn't work well:**
- *Scaling with player level* punishes leveling up: getting stronger makes everything stronger, so progress feels fake.
- *Just starting on a higher floor* skips content but doesn't make anything more interesting.

**Already solved by the pillars:** horizontal Forge + choice-based Skill Tree means the meta adds very little raw power. Keep this pillar strict.

**Recommended: Oaths (opt-in heat / ascension built from pacts)**
- Before a run, at an altar in the Hub, swear **Oaths**: curses for the whole run with no buff. Each has a rank; higher total rank = more materials/XP plus unique unlocks.
- **Reuses curse data:** an Oath is a `Curse` added with `RunState.AddHalf` right after `RunState.Begin`, usually binding. Almost no new code.
- The player picks *which* kind of hard they want. More fun than a difficulty slider.
- Unlock Oaths after the first boss kill.

**Also helps the early run:**
- **Short first floor.** Already roughly true (room count grows with floor number).
- **Early first altar** so the build starts forming in the first minute.
- **Descent (skill tree unlock):** start at the deepest floor you've cleared, drafting one pact per skipped floor.

---

## v0.13: Meta progression I: Skill Tree 🌌 ⏭ next

*Goal: dying is no longer a full reset; there is a reason to do "one more run".*

Suggested order (each step is playable on its own):
1. [ ] **Run end + summary screen.** Decide what a "clear" is (e.g. floor 3 boss = win, endless after as a bonus). Show floors reached, kills, pacts taken, curses broken, currency earned. Cheap, and it makes progress *feel* gained even before anything is spendable
2. [ ] **A meta currency** (soul shards / XP) dropped by enemies, elites and bosses. Reuse the `ManaOrb` pattern for the pickup. Saved via `MetaProgress`
3. [ ] **Save system.** Extend `MetaProgress` (already saves to `user://meta_progress.cfg`): unlocked nodes, currency, unlocked items, best floor
4. [ ] **Hub screen script.** `NewMainUI.tscn` layout exists: Run, Forge (locked/"coming soon"), Skill Tree
5. [ ] **Skill Tree screen.** Constellation node map: locked / available / unlocked. Unlocks *things that happen in runs*:
   - more choices: altars offer +1 pact (`altar_offer_bonus` already wired), pact rerolls, wand-choice rerolls
   - curse removal: trials visible, Sanctuary cleanse, 1 free cleanse per run
   - world: secret floors, new room types, more shrines per floor
   - content: new pacts / wands / enemies added to the pool (unlocks beat numbers)
   - systems: Oaths, Descent

### Stretch
- [ ] **Oaths** (cheap thanks to the pact refactor)
- [ ] **Secret floors.** Floor kind on `RunState`; different room pool + tint

### Suggestions
- Keep the first tree small (15-25 nodes) with a few **keystone** nodes that change play ("dash leaves a fire trail", "your first pact each run has no curse").
- Since runs are already fun, the tree mostly needs to *add* variety (new pacts in the pool) and *control* (rerolls), not fix anything.

---

## v0.14: Meta progression II: The Forge 🔨

*Goal: enemies drop loot, and you craft new loadout options between runs. **Not stronger, but different.***

- [ ] **Looting enemies.** Material drops
- [ ] **Crafting** new wands, runes, scrolls, armor and rings into your collection
- [ ] **Discovering gear.** Blueprints found in runs permanently unlock recipes
- [ ] **Mix-and-match loadout**
- [ ] **Forge screen.** Material counters, stat comparison (reuse `StatsCard`), craft button (`ForgeUI.tscn` layout exists)
- [ ] **Armor.** Mage Robes: fast, fragile, more mana; Plate Mail: slow, tanky, slower dash
- [ ] **Rings & amulets.** Trigger/passive effects
- [ ] **Scrolls (Shift).** Blink teleport, decoy clone, alongside the dash
- [ ] **Loadout screen.** Replaces today's pick-1-of-3

### Suggestions
- Order: **materials + inventory → blueprints → crafting → variants.**
- **Sidegrade variants instead of upgrade levels** ("Purple Bolt: Scatter", "Purple Bolt: Lance").
- **Every item needs a tradeoff.** Pure upgrades break pillar 2.
- 2-3 material tiers tied to floor depth (and Oath rank).

---

## v0.15+: Polish, balance, content ✨

- **Game feel:** hitstop on kills/crits, death particles, music, better death and boss intro moments (screen shake + SFX ✅)
- **Balance pass:** DPS per wand, enemy TTK, pact strength, scaling curve, mana costs
- **Content:** more wands, runes, pacts, curse trials, Oaths, enemies, bosses, rooms, floor themes
- **Accessibility / QoL:** keybinds, screenshake toggle, controller support, pause menu (volume settings ✅)
- **Tutorialization:** first-run hints, item tooltips everywhere

### Possible future features
- **Elemental interactions:** burn + explosion, wet + lightning chain, frozen enemies shatter
- **Synergy system:** rune + pact combos with named results
- **Daily seed run:** seeded generation makes this nearly free
- **Run history / codex:** bestiary, pact collection, curses broken
- **NPC events:** merchant, gambler, cursed chest
- **Loadout presets**

---

## Critiques & concerns

### Resolved
- ~~Three progression layers might be one too many~~: Forge and Skill Tree have separate jobs.
- ~~Pacts vs blessings identity~~: blessings live inside pacts; the only curse-free ones are boss stat upgrades (pillar 1).
- ~~Mana fights the cooldown design~~: kill-charged mana has its own rhythm.
- ~~Primary fire is the whole game~~: heavy spells + mana, elites, 2 distinct bosses and 4 enemy types. Playtesting confirms runs stay fun on repeat.
- ~~Killing is boring~~: see `COMBAT_PLAN.md`.

### Still open
**1. Endless floors, no run end.** Every run ends in a loss right now, and scaling only adds rooms. Decide where a run is "cleared" (part of v0.13 step 1); make deeper floors add *behavior* (elites, new types) more than HP.

**2. Fun with no meta = fun with a ceiling.** The game is replayable now, but nothing remembers your runs. That's the next big risk, and the reason v0.13 is next.

**3. Mana in boss fights.** The per-floor reset makes "save it for the boss" a real choice, which is intended. Only watch that it doesn't turn into "never use heavies on the floor". If it does, make floor fights cheaper to blow mana on (more orbs from elites) rather than changing the reset.

**4. Forge grind risk.** Make every run, even a failed one, a visible step forward. Avoid exact-number recipes.

**5. Dodge invulnerability is generous.** Keep i-frames short; add AoE / lingering hazards dashing can't skip (Skeleton boss bombs are a good start).

**6. Scope sanity.** The Forge is still the hardest system. Keep the step-by-step order.

**7. "Pacts are optional" vs. floor scaling.** Boss upgrades are the no-risk growth path, so refusing pacts stays possible. Tune scaling so boss upgrades alone keep a skilled player afloat for a few floors (flawless kills = faster growth), and pacts are what push you further.

**8. In-run variety rests on pacts.** Loadout is fixed before the run. Mitigations: big pact pool, behavior pacts, rarity tiers, elite/room variety. The current fun suggests the *fights* already vary enough; the pact pool (9) is the thinnest part.

**9. Pre-run choice overload** (later). Unlock loadout slots gradually, add a "random loadout" button.

**10. Mix-and-match becomes "solved".** Push back with pacts favoring playstyles, rune-slot limits, forced-loadout Oaths/dailies, first-clear bonuses.

**11. Curse removal can erase the risk.** Keep cleansing costly, trials hard, or the strongest pacts binding.

**12. The Forge needs a reward feeling without power.** New items should be flashy: new visuals, sounds, mechanics.
