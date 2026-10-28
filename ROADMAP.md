# Arcane Rogue: Roadmap

> Top-down spellcasting roguelite (magical / dark fantasy) in Godot 4.5.
> **Core loop:** build a loadout from what you've unlocked → dungeon run, gambling on pacts → kill monsters and bosses → bring back materials and XP → unlock new options (Forge) and new run possibilities (Skill Tree) → repeat.

| Version | Theme | Goal |
|---|---|---|
| **v0.11** | Current state | One full playable floor that loops |
| **v0.12** | Content | A run stays interesting for 5+ minutes |
| **v0.13** | Meta progression I | Skill tree, saving, a reason to start another run |
| **v0.14** | Meta progression II | The Forge: loot, crafting, unlocking new loadout options |
| **v0.15+** | Polish & content | Balancing, juice, more of everything |

---

## Design pillars (decisions, 2026-10-28)

1. **Pacts are the only in-run upgrade.** No standalone blessings: a blessing only exists as the good half of a pact. Power during a run comes from risk: every buff has a curse. Pacts are always optional.
2. **Meta progression is horizontal, not vertical.** The Forge unlocks *more starting choices* (wands, runes, scrolls, armor, rings) to mix and match. They change how you play, not how strong you start.
3. **The Skill Tree unlocks things that happen in runs:** more choices, rerolls, secret floors, ways to remove curses. It doesn't give flat stats.
4. **Mana works like Isaac's active items:** kills charge it, heavy spells spend it.
5. **Difficulty is opt-in** (see "Difficulty & early-run pacing"). The base game shouldn't get easier just because you've played a lot.

---

## v0.11: Where we are now ✅

**Run flow**
- Main Menu → Pre-Run screen (pick 1 of 3 wands) → run → back to Pre-Run on death or boss kill
- Ctrl+R restart (same loadout, new seed); the floor loops into the next one after the boss (infinite floors)

**World**
- Seeded dungeon generator: start → main path of combat rooms → boss room, side branches with reward rooms, occasional loops
- Room types: Combat, Rest (Sanctuary heal shrine), Shrine (Altar room); Treasure exists as a type, no scene yet
- Fog-of-war minimap, shared 0x72-style tileset with floor variation

**Combat**
- 6 wands with LMB primary spells; runes: Bounce, Pierce (+ Ricochet, Vampiric effects)
- Projectile paths (motions): straight, sine (Blue Blinker), random wiggle
- Shift dash with invulnerability frames (projectiles fly through)
- Knockback, hitstun with stun immunity window, crits, damage numbers
- Enemies: Slime (jumper), Skeleton (circles you, telegraphed charge from behind), Shooter; 1 Boss
- Corpses with death animations

**In-run upgrades**
- Altar pacts (blessing + curse as separate resources, curses cleansable): Swiftness, Vampiric, Volatile; typed SELF / SPELL / ENEMY with icons
- Run effects: Explode on Kill

**Tech / UI**
- StatBlock + StatModifier stat system, Effect / RunEffect hooks, global Signals bus
- HUD (HP, spell slots, stat lists, boss bar, pact list), generic pick-1-of-N ChoiceOverlay
- Dev tools (F6 panel, F7 altar offer, invincible, infinite floors)

---

## v0.12: Content update 🧟

*Goal: a run should feel varied and interesting for at least 5 minutes.*

### Your list
- [ ] **More enemies.** Aim for 6-8 types across distinct roles (see suggestions below)
- [ ] **More bosses.** At least 2-3, so looping floors don't always end in the same fight
- [ ] **More pacts.** Aim for ~15 now and 30+ long term. Pacts are the whole in-run build, so they carry the variety (see "Pact design" below)
- [ ] **Enemy scaling with floors.** HP / damage / speed scale with `floor_number`, plus new enemy types unlocked at deeper floors

### From the design doc (fits here)
- [ ] **Heavy spells (RMB) + mana.** The `heavy` caster already exists. Explosions, shockwaves, summons, paid with mana charged by kills (see "Mana" below). *Probably the single biggest boost to moment-to-moment fun.*
- [ ] **More runes.** Burn, Split, Chain Lightning (doc examples)
- [ ] **Treasure rooms.** The room type exists; give it a scene. Rewards without blessings: a "greater altar" (pick 1 of 4, or a pact with a weaker curse), a full mana charge, a heal, a pact reroll token, or materials once the Forge exists
- [ ] **HUD:** cooldowns for primary and dash, mana charge bar for heavy

### Pact system work
- [x] **Refactor pacts so curses are removable** *(done, see "Architecture: removable curses")*
- [ ] **A way to cleanse in-game** (Sanctuary choice or curse trials; only a dev button so far)
- [ ] **Pact pacing.** Guaranteed altar after each boss, plus 1-2 shrine rooms per floor; tune `max_per_floor`
- [ ] **Reward for refusing.** Walking away from an altar gives something small (heal or mana charge), so refusing is a real choice and not just the cautious option

### Mana (Isaac-style charges)
- Mana = **charge pips**, not a regenerating bar. Each kill adds 1 pip (maybe more for elites), and room clears add a bonus.
- Each heavy spell has a pip cost: cheap (2 pips, small effect) or big (6 pips, room-clearing). This is a great **sidegrade axis for the Forge**.
- **Boss fights have no kills.** Give charge every X% boss HP lost, or have bosses spawn adds. Without this, heavy spells disappear in exactly the fights where they matter most.
- **Overflow:** kills at full charge are wasted, which pushes "use it, don't hoard it". Good, but show clearly when the bar is full (flash/sound).
- Pacts can hook into mana (curse: "kills only charge 50%"; buff: "heavy spell refunds 1 pip per kill it makes"). A new pact axis for free.

### Suggestions
- **Enemy roles** (cover each at least once):
  - *Swarmer*: weak, fast, comes in packs (slime splitter that splits on death?)
  - *Charger*: skeleton ✅
  - *Ranged*: shooter ✅, maybe a mortar/lobber that fires telegraphed AoE (reuse `Explosion`)
  - *Tank / shielded*: a frontal shield you need Bounce/Ricochet or flanking to beat
  - *Support*: buffs or heals nearby enemies, a priority target
  - *Area denial*: leaves hazards (poison puddles, fire trails)
- **Elites.** A normal enemy plus 1-2 random affixes (fast, explodes on death, shielded). Cheap way to multiply variety; can reuse pact curse modifiers.
- **Floor themes.** Even just a tint and a different enemy table per floor makes looping feel like progress.
- **Room variety.** Arena events (survive waves for 30s), trap rooms, a cursed room with a better reward.

---

## Pact design

Since pacts are now the only in-run growth, their design matters most:

- **Pacts that change behavior, not just stats.** In the SPELL category, pacts can *grant rune effects* ("your projectiles split, but fire 30% slower"). A pact can be a found rune, so runs feel different without adding a second reward system.
- **Curses that change play, too.** "-10% damage" is boring to have. "Enemies explode on death", "you can't heal in Sanctuaries", "every 3rd shot misfires", "dash cooldown doubled but dash damages" are memorable.
- **Rarity tiers.** Minor pacts (small buff, small curse) early; major pacts (build-defining) later or in greater altars. This keeps floor 1 from deciding the whole run.
- **Show synergies.** When a pact interacts with your wand/runes, give its card a small highlight. Players love seeing "this works with my build".
- **Watch curse stacking.** By pact 8, the enemy curses together may produce unfair combinations (fast + exploding + shielded). Cap enemy-side curses or let cleansing (below) keep the list short.

---

## Architecture: removable curses ✅

Done (2026-10-28). Terms are in `GLOSSARY.md`.

```
AltarPact (ItemData, Data/Altars/)     PactHalf (Resource)
├─ blessing: Blessing                  ├─ display_name, description
├─ curse:    Curse                     ├─ player_modifiers / effects / run_effects
└─ weight, min_floor                   ├─ enemy_modifiers
                                       └─ flags   # RunState.HasFlag(&"...")
Blessing extends PactHalf (+ type)     Curse extends PactHalf (+ binding)
Data/Blessings/*.tres                  Data/Curses/*.tres
```

- `RunState.halves` is the one list of active blessings + curses. `AddPact` adds both halves; `AddHalf` / `RemoveHalf` work on one (oaths will call `AddHalf(curse)` directly).
- Each half is the **source** of its own modifiers, so `RemoveModifiersFrom(half)` takes back exactly what it gave. The same half resource can only be active once.
- Player and enemies apply all halves on spawn and listen to `half_added` / `half_removed`, so live enemies update right away (enemy max HP now follows `stat_changed`).
- `RunState.CleanseCurse(curse)` is the single entry point (refuses binding curses), fills `cleansed_curses`, emits `curse_cleansed`. HUD shows a pact with a broken curse in the buff color.
- `RunEffect.OnRemoved(player)` exists to undo `OnAdded`.
- Curses that change rules use **flags** instead of code inside the blessing (Volatile: `kill_explosions_hit_player`).
- Dev: "Cleanse curses" button in the F6 panel.

**Design note:** a curse should make sense on its own if it will ever be an oath. "Reckless Blast" (explosions hurt you) does nothing without its blessing. That's fine for a pact curse, but don't put it in the oath pool.

**Ways to remove a curse (gameplay):**
- **Curse trials (recommended).** Each curse has an optional break condition ("kill 40 enemies", "clear 3 rooms without getting hit", "beat the boss"). It's a `RunEffect` that counts events and calls `CleanseCurse` when done. This turns curses into small quests: risky players take more pacts because they plan to break the curses.
- **Sanctuary choice.** The rest room offers *heal* OR *cleanse one curse*. A real decision on every visit.
- **Skill tree unlocks** these options (trials visible, Sanctuary cleanse, 1 free cleanse per run). Removing curses is a reward you earn, not the default.
- Some curses should be **"binding"** (can't be cleansed) to keep the strongest pacts honest.

---

## Difficulty & early-run pacing

**The problem:** stacking upgrades makes runs easy, especially the start, once you've played a lot.

**What doesn't work well:**
- *Scaling with player level* punishes leveling up (the "Oblivion problem"): getting stronger makes everything stronger, so progress feels fake.
- *Just starting on a higher floor* skips content but doesn't make anything more interesting.

**What's already solved by the pillars:** horizontal Forge + choice-based Skill Tree means the meta adds very little raw power. The early game stays similar in difficulty run after run. That's the biggest fix, so keep this pillar strict when adding content.

**Recommended: Oaths (an opt-in heat / ascension system built from pacts)**
- Before a run, at an altar in the Hub, you can swear **Oaths**: permanent curses for the whole run with no buff. Each Oath has a rank. The higher your total rank, the more materials/XP you earn, plus unique unlocks for clearing at a given rank (cosmetics, wands, secret floors).
- **It reuses the curse data you already have.** An Oath is a `Curse` added with `RunState.AddHalf` right after `RunState.Begin`, usually binding. Almost no new code.
- It fits the theme perfectly: the whole game is about deals with dark powers, and the meta difficulty is the same idea.
- The player picks *which* kind of hard they want (faster enemies vs. no Sanctuary heals vs. elite-only rooms). That's much more fun than one difficulty slider.
- Unlock Oaths after the first boss kill, so new players never see them.

**Also helps the early run specifically:**
- **Short first floor.** Fewer rooms on floor 1 means you reach the interesting part faster.
- **Early first altar** on every run, so the build starts forming in the first minute.
- **Descent (skill tree unlock):** start at the deepest floor you've cleared, but first draft one pact per skipped floor. That's a quick "build your run" opening, and it's fun for experienced players without making floor 1 harder for everyone.

---

## v0.13: Meta progression I: Skill Tree 🌌

*Goal: dying is no longer a full reset; there is a reason to do "one more run".*

### Your list
- [ ] **Global Skill Tree.** Unlocks *things that happen in runs*, not flat stats:
  - more choices: altars offer 4 pacts instead of 3, pact rerolls, wand-choice rerolls
  - curse removal: trials become visible, Sanctuary cleanse option, 1 free cleanse per run
  - world: secret floors, new room types (gambler, cursed vault), more shrines per floor
  - systems: Oaths, Descent

### Needed for it to work (from the design doc / dependencies)
- [ ] **Save system (`MetaProgress` autoload).** Unlocked nodes, currencies, unlocked items, best floor/oath rank; save to `user://`
- [ ] **A meta currency.** The tree needs something to spend. Drop it from enemies/bosses already in this version (e.g. "XP" or soul shards), even if Forge materials come later
- [ ] **Hub screen script.** `NewMainUI.tscn` layout exists: navigation to Run, Forge (locked/"coming soon"), Skill Tree
- [ ] **Skill Tree screen.** Constellation node map with states: locked / available / unlocked
- [ ] **End-of-run summary screen.** Floors reached, kills, pacts taken, curses broken, currency earned. Makes progress *feel* gained

### Stretch
- [ ] **Oaths** (see "Difficulty & early-run pacing"). Cheap if the pact refactor is done
- [ ] **Secret floors.** `RunState` gets a floor kind (normal / secret); the generator picks a different room pool and tileset tint. Reached via a hidden room or a pact

### Suggestions
- Keep the first tree small (15-25 nodes) with a few **"keystone" nodes** that change play (e.g. "dash leaves a fire trail", "your first pact each run has no curse").
- Use tree nodes to **unlock content** (new pacts in the pool, new room types). Unlocks are more exciting than numbers.
- Make skill tree "more choices" nodes generous but small. Each one adds a bit of control, not power.

---

## v0.14: Meta progression II: The Forge 🔨

*Goal: enemies drop loot, and you craft new loadout options between runs. **Not stronger, but different.***

### Your list
- [ ] **Looting enemies.** Material drops (doc: "material drops for the Forge")
- [ ] **Crafting** new wands, runes, scrolls, armor and rings into your collection
- [ ] **Discovering gear.** Blueprints/recipes found in runs permanently unlock new crafting options
- [ ] **Mix-and-match loadout.** The point of the Forge: more starting choices that change behavior

### From the design doc (fits here)
- [ ] **Forge screen.** Material counters, side-by-side stat comparison, craft button (`ForgeUI.tscn` layout exists)
- [ ] **Armor.** Changes base stats and playstyle (Mage Robes: fast, fragile, more mana; Plate Mail: slow, tanky, slower dash)
- [ ] **Rings & amulets.** Trigger/passive effects (vampirism, crits, material find)
- [ ] **Scrolls (Shift).** Blink teleport, decoy clone, alongside the classic dash
- [ ] **Loadout screen.** Grid-based setup for wand, runes, armor, accessories, scroll (replaces today's pick-1-of-3)

### Suggestions
- Build it in this order: **materials + inventory → blueprints (unlock) → crafting → variants.** Each step is shippable alone.
- **Sidegrade variants instead of upgrade levels:** craft an existing wand into a variant ("Purple Bolt: Scatter": 3 weaker bolts; "Purple Bolt: Lance": slow, piercing). More options, same power.
- **Blueprints** as boss/elite drops: a blueprint unlocks a recipe permanently. This links "discovering gear" to actual gameplay moments.
- **Every item needs a tradeoff** (Plate Mail tanky but slow). Pure upgrades sneak power back in and break pillar 2.
- 2-3 material tiers tied to floor depth (and Oath rank) give deeper runs a reason beyond difficulty.

---

## v0.15+: Polish, balance, content ✨

No new big systems; deepen existing ones.

- **Game feel:** screenshake, hit-stop on crits/kills, particles, sound effects + music, better death and boss intro moments
- **Balance pass:** DPS per wand, enemy TTK, pact strength, scaling curve, mana pip costs
- **Content:** more wands, runes, pacts, curse trials, Oaths, enemies, bosses, rooms, floor themes
- **Accessibility / QoL:** settings menu (volume, keybinds, screenshake toggle), controller support, pause menu
- **Tutorialization:** first-run hints, item tooltips everywhere

### Possible future features (only if you want them later)
- **Elemental interactions:** burn + explosion, wet + lightning chain, frozen enemies shatter. Gives the "Elements" in the doc real meaning
- **Synergy system:** rune + pact combos with named results (shown in the UI when unlocked)
- **Daily seed run:** you already have seeded generation, so this is nearly free (fixed loadout + fixed Oaths makes it fair)
- **Run history / codex:** bestiary, pact collection, curses broken. Fills as you discover things
- **NPC events:** merchant room, gambler (bet HP on a better pact), cursed chest
- **Loadout presets:** save favorite mix-and-match builds

---

## Critiques & concerns

### Resolved by the 2026-10-28 decisions
- ~~Three progression layers might be one too many~~: the Forge and the Skill Tree now have separate jobs (loadout options vs run options).
- ~~Pacts vs blessings identity~~: blessings removed.
- ~~Mana fights the cooldown design~~: kill-charged mana is its own resource with its own rhythm, not a 4th cooldown.

### Still open
**1. Infinite looping + scaling = numbers inflation.**
If enemies only get more HP each loop, later floors feel like slower versions of floor 1. Scaling should add *new behaviors* (new enemy types, elites, affixes, boss phases), with stat scaling as the smaller part. Also decide where a run actually **ends** (e.g. 3-5 floors = win, endless after that as a bonus). "Keep going until you die" makes every run end in a loss, and Oath rewards need a clear "clear".

**2. Primary fire is the whole game right now.**
With only LMB + dash, fights are "hold click and strafe". Heavy spells + mana (v0.12) matter a lot here; also make enemies that require different answers (shielded, flying over walls, fast dodgers), so loadout choice matters.

**3. Forge grind risk.**
If crafting needs many materials, runs turn into farming. Make each run, even a failed one, give a visible step forward, and avoid exact-number recipes that force replaying floor 1 for one material.

**4. Dodge invulnerability is generous.**
Dash = full projectile immunity. Good for feel, but it makes ranged enemies easy once mastered. Keep i-frames short and give some attacks AoE / lingering hazards that dashing can't skip.

**5. Scope sanity.**
The Forge is still the hardest system: items, inventory, saving, UI and drops at once. The step-by-step order above keeps the project from stalling there.

### New, from the decisions
**6. "Pacts are optional" vs. floor scaling.**
If enemies scale but the player only grows through pacts, refusing pacts stops being an option by floor 3. That's fine (the game *is* about deals), but be honest about it in balancing. Decide the target: "a skilled player can clear floor 1-2 with no pacts" sounds right. A "no pacts" Oath turns that into a challenge for experts.

**7. In-run variety now rests on pacts alone.**
Your loadout is fixed before the run, and pacts are the only thing that changes. If 2 runs with the same loadout get similar pacts, they'll feel the same. Mitigations: a big pact pool, pacts that grant rune-like behaviors, rarity tiers, and elite/room variety so the *fights* change even when the build doesn't.

**8. Pre-run choice overload.**
With a fully mixed loadout (wand + runes + scroll + armor + 2 rings), a new player sees a big screen of choices with no context. Unlock slots gradually (wand only → + runes → + armor ...), and add a "random loadout" button.

**9. Mix-and-match becomes "solved".**
Once players find the best combo, they'll use it every time and the Forge's variety is wasted. Ways to push back: pacts that favor certain playstyles, a rune-slot limit per wand, Oaths/daily runs with forced loadouts, and run-end bonuses for using something new ("first clear with this wand: +50% materials").

**10. Curse removal can erase the risk.**
If cleansing is too easy, pacts become free buffs and pillar 1 collapses. Keep at least one of: cleansing costs a real choice (Sanctuary heal *or* cleanse), trials are hard, or the strongest pacts are binding.

**11. The Forge needs a reward feeling without power.**
Horizontal progression sometimes feels like "I grinded and I'm not stronger". Make new items *flashy*: a new projectile visual, a new sound, a new mechanic you can see right away. Unlocking should feel like opening a toy, not like getting +3%.

**12. Mana in boss fights.**
Kill-charged mana is starved in single-target fights (see the Mana section). Solve it before the second boss, or players will learn "save heavy for the boss" and play the whole floor around hoarding.
