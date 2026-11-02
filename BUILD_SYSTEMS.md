# Arcane Rogue: Build Systems Reference

> What the build rework (2026-11-02, phases A-F of `BUILD_DESIGN.md`) added, how each part works,
> and where every number lives so it can be tuned. `BUILD_DESIGN.md` is the *why*; this file is the *what and where*.
> Everything below is plain `.tres` data or a few constants, editable in the Godot inspector.

---

## 1. The build loop in one picture

```
Altar (1/floor) ──pact──> fills a VERB SLOT (Primary / Heavy / Dash / Kill / Orb)  ──> +2 school points
                          (a new pact for a filled slot REPLACES the old one, blessing + curse)
Room clear (30%+) ─glyph─> small free buff, only for schools you own a pact of (+ Form) ──> +1 school point
School points ──────────> Tier I at 4, Tier II at 8 (Attunements, added/removed automatically)
Sanctuary (1/floor) ────> +10 max HP for the run, heal 40%
Boss Upgrade Shrine ────> 3 stat cards, one swapped for Duo > Wand Evolution > Deepen (rank II) if eligible
Enemies ────────────────> statuses (Burn, Chill→Freeze, Shock, Bleed) are the shared language every piece talks in
Floors ─────────────────> more elites, elite behaviors, affixes, second waves, champion packs, floor omens
```

Schools: **Ember** (Burn, spreads), **Frost** (Chill → Freeze, control), **Storm** (Shock, chains), **Blood** (Bleed, HP economy), **Form** (neutral projectile shape: Multishot, Homing, Form glyphs).

---

## 2. Core plumbing (read this before changing anything)

### 2.1 Everything is a `PactHalf`
`Scripts/Altars/PactHalf.gd` is the one bundle type. Blessings, curses, glyph blessings, attunements, duos, evolutions, stat upgrades, the Sanctuary bonus and floor omens are all PactHalves. `RunState.AddHalf(half, can_stack)` / `RemoveHalf(half)` are the only way in or out; the Player and every enemy listen to `half_added` / `half_removed` and apply or undo it live. The half is the StatModifier **source**, so removing it removes exactly what it added.

| Field | Who applies it | Example |
|---|---|---|
| `player_modifiers` | Player stats | Frostbitten: `movement_speed` x0.9 |
| `spell_modifiers` | every wand caster | Power: `damage` x1.2 |
| `primary_modifiers` | primary caster only | Numb Hands: `cooldown` x1.15 |
| `effects` | projectile `Effect`s on every cast | Fracture, Glacier |
| `primary_effects` / `heavy_effects` | only that cast | Kindle: Burn on hit |
| `heavy_override: SpellData` | replaces the heavy spell (last active wins, removal restores the wand's) | Fireburst, Glacial Nova |
| `run_effects` | `RunEffect` event hooks (§2.2) | Volatile Dead, Cold Snap |
| `enemy_modifiers` | every enemy (or its spell if it has the stat) | Barrage, Swarm omen |
| `status_tweaks` | `StatusTweak`: +max stacks / +duration / +stacks per application, **enemies only** | Fuel, Long Fuse, Deep Cuts |
| `flags` | checked in code with `RunState.HasFlag` / `CountFlag` (§2.3) | Slick Floor, Inferno |
| `elite_chance_multiplier` | elite chance (each half counted once) | Awakening, Champions |
| `school` | school points (blessings only) | — |

### 2.2 Hooks
**Projectile `Effect`** (`Scripts/Combat/Effects/ProjectileEffects/`): `OnProjectileSpawned`, `ModifyDamage` (now has `info.target`), `OnHitTarget`, `OnHitWall`, `OnPhysicsProcess`. Per-projectile state in `projectile.effect_state[self]`; per-caster counters (Static, Tempest) are stored as meta on the caster.

**`RunEffect`** (`Scripts/Combat/Effects/RunEffects/RunEffect.gd`), dispatched by `RunState` to every active half:

| Hook | Fired from |
|---|---|
| `OnEnemyKilled(enemy, info)` | `Signals.enemy_killed` (Entity.Die, before queue_free: statuses still readable) |
| `OnPlayerDamaged(player, info)` | `Signals.player_damaged` |
| `OnRoomCleared()` | `Signals.room_cleared` |
| `OnDashStarted(player, pos, dir)` / `OnDashedThrough(player, enemy)` / `OnDashEnded(player, pos)` | Player.UseMobility / dash-only Area2D / EndDash (with Slick Floor: when the slide stops) |
| `OnOrbCollected(player, orb, mana)` / `OnOrbProcess(orb, delta)` | ManaOrb pickup / every frame while an orb homes in |
| `OnHitBlocked(player, info)` | a Hoarfrost shield ate a hit |
| `OnEnemyFrozen(enemy)` | `Signals.enemy_frozen` (Entity.Freeze) |
| `OnEnemyDamaged(enemy, info, amount)` | `Signals.enemy_damaged` (every hit and tick, `amount` = HP actually lost) |
| `OnProcess(player, delta)` | every physics frame (`RunState.ProcessEffects` from Player) |
| `OnAdded` / `OnRemoved` | the half was added / removed (also on every new floor's player) |

RunEffects are **shared resources**: keep run state in `RunState.run_effect_state[self]`, never in a variable on the effect.

### 2.3 Flags (behavior switches checked in code)
`HasFlag` = on/off, `CountFlag` = stacks (each active copy of a half counts).

| Flag | Source | Checked in |
|---|---|---|
| `explosions_hit_player` | Reckless Blast | ExplodingEffect, ExplodeOnKillEffect |
| `kindling` | Kindling | Entity (`kindling_mod` on Burn add/remove) |
| `elite_chill_aura` | Permafrost | Entity.HandleChillAura |
| `slick_dash` | Slick Floor | Player.EndDash / HandleMoveState |
| `sanctuary_heal_halved` | Cold Hearth | RestRoom |
| `deep_cold` (count) | Deep Cold | Entity.GetFreezeThreshold |
| `extra_shards` (count) | Ice Shards | ShatterEffect (+3 each) |
| `inferno` | Inferno (Ember II) | ExplodingEffect, ExplodeOnKillEffect |
| `fork`, `long_arc` (count), `overload`, `tempest`, `plasma`, `superconductor`, `stormcaller` | Storm glyphs / tiers / duos | ChainArc.Discharge |
| `static_field` (count) | Static Field | ApplyStatusOnHitEffect `every_nth_flag` |
| `blood_price` | Blood Price | Player.CastSpell, HUD heavy slot |
| `blink_dash` | Blink Step | Player.UseMobility |
| `short_fuse` (count) | Short Fuse | Player.UseMobility (+30% cooldown each) |
| `overcharge` | Overcharge | Player.CastSpell (every 10th primary fizzles) |
| `hunted` | Hunted | Player.TakeDamage |
| `cold_blood` | Cold Blood duo | Player.TakeDamage |
| `sanguine` | Sanguine (Blood II) | Player `_on_overhealed` |
| `thermal_shock` | Thermal Shock duo | Entity.CheckThermalShock |
| `clotting` (count) | Clotting | ManaOrb (+3 heal each) |
| `no_sanctuary` | Silent Halls omen | DungeonGenerator |
| `restless_dead` | Restless Dead omen | Entity.Die → RiseAgain |

### 2.4 RunState (run bookkeeping, `Scripts/Global/run_state.gd`)
- `slots` (AltarPact.Slot → pact), `GetSlotPact`, `ReplacePact` (removes old blessing, rank II blessing and curse with `RemoveHalf`; emits `pact_replaced`).
- `GetSchoolPoints(school)` = slot pacts x2 + glyph stacks x1. `GetPactSchoolPoints` = slot pacts only ("owning" a school).
- `ATTUNEMENTS` (list of `Attunement` .tres) + `CheckAttunements()` after every pact/glyph change → `attunement_reached` / `attunement_lost`.
- `glyphs`, `AddGlyph`, `CanTakeGlyph`, `glyph_pity`.
- `duos`, `evolution`, `deepened_pacts`, `AddDuo`, `SetEvolution`, `DeepenPact`.
- `AFFIXES`, `OMENS`, `omens`, `RollOmens()` (GameFlow.NextFloor), `GetEnemyCountMultiplier`, `GetEliteGlyphBonus`, `GetOmenWardGroup`, `GetTopSchoolWardGroup`.
- `GetStatusExtraStacks` / `GetStatusDurationMultiplier` / `GetStatusExtraApplication` (StatusTweak sums).
- All of it is reset in `Begin()`.

---

## 3. Statuses (`Data/Statuses/`, `Scripts/Combat/StatusEffects/`)

| Status | Numbers | Notes |
|---|---|---|
| **Burn** | 2 dmg per 0.5s tick **per stack** (4/s), 3s, max 5 | refresh + add stack on reapply; embers per stack |
| **Chill** | -8% `movement_speed` per stack, 3s, max 5 | animation slows 10%/stack; at max → Freeze |
| **Freeze** | 1.5s, then 3s freeze immunity (`Entity.FREEZE_IMMUNITY`) | own `freeze_timer` (not hitstun, so Chargers mid-dash freeze); no move/shoot/contact damage; ice look + stopped anim |
| **Brittle** | `damage_taken` x1.25, 3s | bosses get it instead of Freeze |
| **Shock** | 1 stack, 4s | next real hit discharges (§3.2) |
| **Bleed** | 1.5 per 0.5s tick per stack (3/s), 4s, max 10 | x(1 + player's missing HP share); icon bar shows a number |
| **Empowered** | 3s player buff | Lifeblood's +20% damage window |
| Poison | 2/tick, refresh only | AreaCaster clouds (unchanged) |

### 3.1 Stacking (`StatusEffectHolder.Apply`)
Same effect again = refresh duration + add stacks up to `GetMaxStacks` (StatusEffect `max_stacks` + Fuel-style tweaks on enemies). Stat modifiers are rebuilt as **new** `StatModifier`s scaled by stacks (flat × stacks, multiplier 1 + (m-1) × stacks); the shared `.tres` is never touched. Tick damage × stacks. `ward_group` (`ember`/`frost`/`storm`/`blood`) is refused by a Warded enemy. Helpers for effects: `StatusEffectHolder.TargetHas(target, effect)` / `TargetStacks`.

### 3.2 Shock discharge (`Entity.TakeDamage` → `ChainArc.Discharge`)
Any non-tick, non-arc hit on a Shocked enemy removes Shock and arcs 50% of that hit to the 2 nearest enemies within 120px. Fork +1 target each, Long Arc +30% range each, Tempest +1 target, Overload = arcs roll the primary's crit, Superconductor = always crit on Chilled/Frozen, Plasma = arcs apply 1 Burn, Stormcaller = arcs apply Shock (chains). Arcs set `DamageInfo.is_arc`, so they never discharge again or trigger on-hit effects.

### 3.3 Readability (§9 of the design)
- `StatusIconBar` (above the head, counter-scaled so elites/bosses match): 7x7 icons, stack pips (≤5) or a number (Bleed), fades under 0.5s, moves up while the "!" telegraph shows; affixes gold-framed on the left, a ward = the school's status icon crossed out.
- `StatusVisuals`: outline from `Shaders/status_outline.gdshader` in the highest-`priority` status's `outline_color` (Freeze 50 > Brittle 45 > Shock 40 > Burn 30 > Chill 20 > Bleed 10); frozen tint; Chill/Freeze animation speed; Burn embers (one emitter per stack), Bleed drips, Shock crackle.
- Ticks never flash the sprite; enemies show a small number in the status color (none under 1). A white/red flash = a real hit.

---

## 4. Slots and pacts (`Data/Altars/`, blessings `Data/Blessings/`, curses `Data/Curses/`)

**Slot rules:** one pact per slot (`AltarPact.slot`). Taking a pact for a filled slot removes the old one completely; the card shows "Replaces X" in red. **Every slot pact has its own curse `.tres`** (RemoveHalf removes every copy of a half, so a shared curse would be stripped from the other pact too). Rank II = `rank2_blessing` (Deepen at the boss shrine, same curse).

Altar: 3 offers (`AltarRoom.BASE_OFFER_COUNT`), rarity roll first (70/20/10), then weight. Pacts of a school you have points in ×2 (`OWNED_SCHOOL_WEIGHT`), the wand's `school_affinity` ×1.5 on the first altar (`AFFINITY_WEIGHT`). Pool = `pact_pool` export in `Scenes/World/RoomScenes/AltarRoom.tscn`. Old v0.12 pacts live in `Data/Altars/Retired/` (outside the pool and F7). Careful if you bring one back: `Retired/VampiricPact.tres` points at `BloodthirstBlessing.tres`, which is now the Blood pact Bloodthirst's blessing, and Exploding Shots / Lifeblood (old) shared curses that new pacts now own (Reckless Blast, Drained Font). Give a revived pact its own halves.

| Pact | Slot | Rank I | Rank II | Curse |
|---|---|---|---|---|
| **Kindle** | Primary | hits 1 Burn | 2 Burn | Smolder: hit → you gain 1 Burn (half strength) |
| **Fireburst** | Heavy | fireball 30 dmg, 70 mana, explodes x2 dmg r64 + 3 Burn | 45 dmg, r80, 4 Burn | Reckless Blast: your explosions hurt you |
| **Trail of Cinders** | Dash | fire trail (r14 every 14px, 2s) | r22 every 12px | Scorched Earth: deaths leave a patch that burns you |
| **Volatile Dead** | Kill | Burning always explode, others 20%; 30 dmg r48 | 40%, 45 dmg r56 | Kindling: Burning enemies +15% speed |
| **Ember Motes** | Orb | homing orbs apply 1 Burn (r12) | 2 Burn, r20 | Drained Font: -30% mana |
| **Rime Bolt** | Primary | hits 1 Chill | 2 Chill | Frostbitten: -10% move speed |
| **Glacial Nova** | Heavy | nova r90: 20 dmg, 3 Chill, knockback, 60 mana | r120, 30 dmg, 4 Chill | Numb Hands: primary cooldown +15% |
| **Cold Snap** | Dash | dashed-through 2 Chill, ice patch r28 at the end | 3 Chill, r40 | Slick Floor: slide 0.45s after dashing |
| **Shatter** | Kill | an enemy that **freezes** bursts into 6 shards (10 dmg, 1 Chill) | 9 shards, 15 dmg | Permafrost: elites Chill you within 70px (up to 2 stacks) |
| **Hoarfrost** | Orb | every 30 mana → 1 shield (blocks a hit, attacker 2 Chill) | every 20, 3 Chill | Cold Hearth: Sanctuary heals half |
| **Static** | Primary | every 3rd primary hit Shocks | every 2nd | Overcharge: every 10th primary misfires |
| **Ball Lightning** | Heavy | slow orb (60 speed, 3.5s), pulse every 0.4s r55: 5 dmg + Shock, 60 mana | 0.3s, r70, 8 dmg | Barrage: enemy projectiles +20% speed |
| **Blink Step** | Dash | 60px teleport, Shock pulse r50 at the start | r80 | Short Fuse: dash cooldown +30% |
| **Conductor** | Kill | kills Shock the 2 nearest (r160) | 3 nearest, r200 | Awakening: elites x1.3 |
| **Capacitor** | Orb | above 50 mana: +20% fire rate | +35% | Leak: above 50 mana lose 2/s |
| **Hemorrhage** | Primary | hits 1 Bleed | 2 Bleed | Thin Blood: healing -30% |
| **Blood Price** | Heavy | blood saw 30 dmg, 4 Bleed, pierce 2, 60 mana; without mana costs 15% current HP | 40 dmg, 6 Bleed, pierce 3 | Anemia: -25% max HP |
| **Crimson Step** | Dash | dashed-through 2 Bleed, heal 1 each | 3 Bleed, heal 2 | Open Wounds: dashing costs 2 HP (never lethal) |
| **Bloodthirst** | Kill | Bleeding enemies drop a mote (heal 3) | heal 6 | Hunted: below 50% HP take +15% |
| **Lifeblood** | Orb | +10% healing orbs; a healing orb gives Empowered (+20% dmg, 3s) | +15%, +30% | Withered Font: -20% mana |

Form pacts (no slot, no points): **Multishot** (Epic, stacks 3), **Homing** (Legendary).

### 4.1 Attunements (`Data/Attunements/`, listed in `RunState.ATTUNEMENTS`)
| School | Tier I (4 pts) | Tier II (8 pts) |
|---|---|---|
| Ember | **Pyromancer**: Burning enemies explode on death (30 dmg r48; one explosion per corpse even with Volatile Dead) | **Inferno**: your explosions apply 2 Burn |
| Frost | **Glacier**: the first hit on a Frozen enemy (per freeze) deals x2 | **Absolute Zero**: a freeze gives 2 Chill to enemies within 80px |
| Storm | **Tempest**: +1 arc target, every 10th hit is a crit | **Stormcaller**: arcs apply Shock |
| Blood | **Hemomancer**: below 50% HP +30% spell damage | **Sanguine**: overheal becomes a barrier (max 20, red ring) |

Reaching one shows a HUD popup + sound; losing the points (slot replaced) removes it.

---

## 5. Glyphs (`Data/Glyphs/`, `Scripts/Altars/GlyphData.gd`)

**Drop** (`EnemyRoom.RollGlyph`, on clearing a combat room, not boss rooms or empty rooms): `min(glyph_chance + glyph_chance_per_elite × elites, glyph_chance_cap) + RunState.glyph_pity` = 0.30 + 0.15/elite (cap 0.75) + 0.10 per dry room before (reset on a drop). Seeded by floor + room position. Spawns `Scenes/World/GlyphShrine.tscn` where the last enemy died; E = pick 1 of 3.

**Offers** (`GlyphShrine.RollOffers`): Form glyphs + glyphs of schools you **own a pact of**; before the first pact, Form only. The first card is always Form; your top-points school ×2 (`TOP_SCHOOL_WEIGHT`). Pool = `glyph_pool` export on the shrine scene. 1 school point per stack.

| School | Glyph (max stacks) |
|---|---|
| Form | Pierce +1 pierce (3) · Rebound +1 bounce (3) · Swift Feet +10% move (3) · Keen Eye +8% crit (3) · Velocity +15% projectile speed (3) · Quick Hands -8% cooldown (3) |
| Ember | Fuel +1 Burn max stacks (3) · Wildfire: a Burning death passes its Burn to the nearest enemy within 120px (1) · Searing +20% damage to Burning (3) · Long Fuse Burn +50% duration (3) |
| Frost | Deep Cold: freeze at 1 less Chill, min 2 (2) · Fracture +30% damage to Frozen (3) · Lingering Chill +50% duration (3) · Ice Shards: Shatter +3 shards (3) |
| Storm | Fork +1 arc target (2) · Long Arc +30% arc range (3) · Overload: arcs can crit (1) · Static Field: Static every 2nd hit (1) |
| Blood | Deep Cuts +1 Bleed per application (3) · Transfusion: Bleed damage heals 5% (3) · Frenzy +1% damage per 2% missing HP (2) · Clotting: healing orbs +3 (3) |

Searing / Fracture / Frenzy / Hemomancer / Glacier are projectile `ModifyDamage` effects: they boost spell hits, not explosions, novas, arcs or ticks.

---

## 6. Sanctuary (`Scripts/Worldgen/RestRoom.gd`, `Scenes/World/RoomData/SanctuaryData.tres`)
Guaranteed every floor (`min_per_floor = 1`, `min_depth = 1`), a 2nd can appear from floor 3 (`RoomData.extra_from_floor = 3`). Stepping on it once: `SanctuaryBlessing` (+10 max HP, stacks for the run) then heal `heal_share` = 40% (works at full HP). Silent Halls removes it for a floor.

---

## 7. Boss Upgrade Shrine (`Scripts/Worldgen/UpgradeShrine.gd`)
`BuildOffers()`: the 3 `upgrades` (Vigor +40 max HP, Power +20% damage, Quick Cast -18% cooldown), then one random card is replaced by the first eligible special: **Duo** (random eligible) > **Evolution** > **Deepen** (random slot pact with a rank II not yet deepened). Every reward implements `ItemData.Claim()`. Flawless = 2 picks; a special can only be taken once.

**Duos** (`Data/Duos/`, `duo_pool` export; need a slot pact of both schools):
| Duo | Effect |
|---|---|
| Thermal Shock (Ember+Frost) | Burning + Chilled at once → burst of 40 + 10 per stack of both, both clear (`Entity.CheckThermalShock`) |
| Plasma (Ember+Storm) | arcs apply 1 Burn |
| Boiling Blood (Ember+Blood) | Burn damage heals you 3% |
| Superconductor (Frost+Storm) | arcs on Chilled/Frozen always crit |
| Cold Blood (Frost+Blood) | once per floor a lethal hit leaves you at 1 HP + 2s invulnerable |
| Galvanic Pulse (Storm+Blood) | every kill Shocks the nearest enemy and heals 1 |

**Wand evolutions** (`Data/Evolutions/`, `evolution_pool` export; need the wand + Tier I of its `school_affinity`; one per run; primary only, the heavy belongs to heavy pacts; kept as a run half so it survives floors):
| Evolution | Wand (affinity) | Effect |
|---|---|---|
| Inferno Wheel | Flame Shuriken (Ember) | +3 shurikens, +60 spread, hits 1 Burn |
| Glacier Lance | Blue Blinker (Frost) | primary pierces everything, first enemy per bolt gets 2 Chill |
| Forked Lightning | Purple Bolt (Storm) | every hit arcs (ArcOnHitEffect, 60% of the hit into ChainArc) |
| Hemoclast | Purple Saw Staff (Blood) | saws x1.5 size, 1 Bleed, a saw kill heals 1 |

The character screen shows the evolved name.

---

## 8. Enemy scaling

**Per floor** (`Data/Floors/DefaultFloorModifier.tres`): +10% HP, +12% damage, +3% elite chance (on top of the room's `elite_chance` 0.08).

**Elites** (all): `DefaultElite.tres` stats (Shooter/AreaCaster have their own), ×2 `mana_drop`, +15% glyph chance each. **Behaviors** (brains read `is_elite`):
- Jumper: landing (`Entity.landed`) fires a ring of 6 slow projectiles (`elite_ring_count`, `elite_ring_speed` 0.45, 50% contact damage).
- Swarmer: summons twice as often, its copies +30% speed.
- Charger: a second dash right after the first (`elite_chain_windup` 0.25s).
- Shooter / AreaCaster: more shots / circles (their EliteData, unchanged).

**Affixes** (`Data/Affixes/`, `RunState.AFFIXES`, rolled in `EnemyRoom.RollAffixes`): elites get 1 from floor 3 (`affix_floor`), 2 from floor 6 (`second_affix_floor`).
| Affix | Effect |
|---|---|
| Volatile | death → telegraphed explosion (25 × floor damage scale, r44) that only hurts the player |
| Hasted | +40% speed |
| Warded | immune to the statuses of your top owned school (max 1 per room, only if you own a school) |
| Regenerating | 3% max HP/s after 2s without damage |

**Rooms** (`Scripts/Worldgen/EnemyRoom.gd` exports): second wave from floor 3, 40% (`second_wave_floor`, `second_wave_chance`): the doors stay shut and the markers spawn again. Champion packs from floor 5, 25% (`champion_floor`, `champion_chance`): the first spawn becomes an elite with an affix + `champion_minions` (3) copies sharing it. `EnemyPoolEntry.min_floor` gates enemies by depth (only the AreaCaster in `Mixed` is gated, to floor 2).

**Floor omens** (`Data/Omens/`, `RunState.OMENS`, `FloorOmen` = a PactHalf added for one floor in `GameFlow.NextFloor`; one from floor 2, two from floor 8; shown under the HUD floor label with a tooltip):
| Omen | Rule |
|---|---|
| Swarm | 50% chance of a 2nd enemy per marker, enemies -35% HP |
| Champions | elite chance x2, +15% glyph chance per elite (so 30% each) |
| Kindled Halls | every enemy Warded against Burn, takes +20% damage |
| Silent Halls | no Sanctuary |
| Blood Moon | enemies +20% damage, every kill heals you 1 |
| Restless Dead | non-boss enemies rise once as a weak Swarmer (40% HP), the room waits for them |

---

## 9. Tuning cheat sheet

| What | Where |
|---|---|
| Status numbers, stacks, outline color, priority | `Data/Statuses/*.tres` |
| Freeze immunity, Kindling speed, chill aura, regen, Volatile blast, risen HP | constants at the top of `Scripts/Entities/EntityMisc/EntityBase.gd` |
| Arc share / targets / range | `Scripts/Combat/ChainArc.gd` constants |
| Pact numbers (rank I / II) | the pact's `Data/Blessings/<Name>Blessing.tres` / `<Name>IIBlessing.tres` (inline sub-resources) |
| Curse numbers | `Data/Curses/*.tres`; Blood Price share, Overcharge, Blink distance, barrier max in `Player.gd` constants |
| Altar weights | `AltarRoom.OWNED_SCHOOL_WEIGHT`, `AFFINITY_WEIGHT` |
| Glyph drop chance | `EnemyRoom` exports `glyph_chance`, `glyph_chance_per_elite`, `glyph_chance_cap`, `glyph_pity_per_room` |
| Glyph numbers / max stacks | `Data/Glyphs/*.tres` |
| Tier thresholds / effects | `Data/Attunements/*.tres` (+ their blessing) |
| Sanctuary | `RestRoom.heal_share`, `Data/Blessings/SanctuaryBlessing.tres`, `SanctuaryData.tres` |
| Shrine specials | `UpgradeShrine.tscn` (`duo_pool`, `evolution_pool`), `Data/Duos/`, `Data/Evolutions/` |
| Floor scaling | `Data/Floors/DefaultFloorModifier.tres` |
| Affix / wave / champion floors and chances | `EnemyRoom` exports; affix data in `Data/Affixes/` |
| Elite behaviors | brain exports (`JumperAI.elite_ring_*`, `ChargerAI.elite_chain_windup`), `SwarmerAI` (x0.5 cooldown, x1.3 copy speed) |
| Omens | `Data/Omens/*.tres`; double omens floor `RunState.DOUBLE_OMEN_FLOOR` |

---

## 10. How to add things

- **A slot pact:** a Blessing (`school`, `type`, the fields from §2.1) + its **own** Curse + an AltarPact (`slot`, `rarity`, optional `rank2_blessing`) in `Data/Altars/`, then add it to `pact_pool` in `AltarRoom.tscn`. New behavior = a new `Effect`/`RunEffect` subclass, or a flag checked where it matters.
- **A glyph:** a GlyphData in `Data/Glyphs/` (inline blessing, `school`, `max_stacks`), add it to `glyph_pool` in `GlyphShrine.tscn`.
- **A status:** a StatusEffect `.tres` (set `max_stacks`, `priority`, `outline_color`, `ward_group`, a 7x7 `icon`). Body effects go in `StatusVisuals`.
- **An attunement:** an Attunement `.tres` (school, threshold, tier, blessing), add it to `RunState.ATTUNEMENTS`.
- **A duo / evolution:** a DuoData / WandEvolution `.tres`, add it to the pools on `UpgradeShrine.tscn`.
- **An affix / omen:** an Affix / FloorOmen `.tres`, add it to `RunState.AFFIXES` / `OMENS`. New affix behavior = a new `Affix.Kind` handled in `Entity`.
- **A new event hook:** emit a signal from `Signals`, connect it **once in `RunState._ready()`**, add the virtual to `RunEffect`.

---

## 11. Gotchas learned the hard way

- **Connect signals only in `_ready()`.** A `connect()` inside a per-frame function adds a connection every frame; that caused the floor-2 lag (thousands of ice patches per dash). There's no check against it, so keep connects out of hot paths.
- **Every slot pact needs its own curse resource** (replace flow removes every copy).
- **Never mutate shared `.tres` resources** (statuses, effects, pacts). Build new StatModifiers (`ActiveStatusEffect.BuildModifiers`) or store state in `effect_state` / `run_effect_state` / meta.
- **Preload cycles:** `Explosion.gd` refers to `Entity`, so `EntityBase.gd` must `load()` the explosion scene, not `preload()` it. Same for anything an Entity-referencing script would preload back.
- **Typed arrays:** `return [x] if c else []` gives a plain Array; build a typed var and return that.
- **Don't name an enum like its class** (`School.Kind`, not `School.School`).
- **Spawning from physics callbacks:** Area2Ds (explosions, areas, shards, glyph shrines) are added with `call_deferred`; `Entity.Die` adds its corpse and risen Swarmer deferred too. A deferred call *on the dying entity* is dropped, call it on the parent.
- **Headless test scripts** (`--script`) can't use autoload names or project class names at compile time; use `root.get_node("RunState")` and `load()`.

---

## 12. Dev tools (F6)
"Shots apply Burn/Chill" toggles, "Burn x1/x5" and "Chill x1/x4 all enemies" buttons, plus the existing invincible / x10 damage / all elites / altar offer (F7, loads every pact in `Data/Altars/`) / cleanse / teleport to boss.

## 13. Known gaps / ideas left
- Burn pips cap at 5, so Fuel's extra stacks don't show (they still tick).
- Kindling only updates when Burn is added/removed (taking the curse mid-fight doesn't speed up enemies already burning).
- Hoarfrost shield charges reset each floor (stored mana carries over).
- Inferno Wheel has no "orbit first" motion (needs a ProjectileMotion).
- No cap on max-HP loss from stacked curses (design §13 suggests -50%).
- Only 5 enemy types, so depth-gated pools barely exist yet; check enemies (frontal shield, armored) from design §8.5 aren't built.
- Status tick damage numbers are the biggest per-frame cost in huge status fights; batch them per second if needed.
- Not playtested yet: altar/glyph frequency (design §13), curse load by floor 6, Brittle vs bosses.
