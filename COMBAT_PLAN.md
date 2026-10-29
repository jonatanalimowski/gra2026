# Making combat fun: plan

> Problem: killing enemies is boring. Ordered from easiest (with the current code) to hardest.
> Written 2026-10-29. See `ROADMAP.md` for the bigger picture.

## Why kills feel flat
- No feedback on a kill: corpse spawns, nothing else (no hitstop, particles). ~~No sound at all~~ (done: `Sfx` autoload)
- Kills don't feed anything (no pickups, mana, score). ExplodeOnKill is the exception, and it feels good
- Most enemies just walk at you (contact damage), so every fight asks the same thing: back off and shoot
- Enemies die in 1-2 hits (slime 15 HP, turnip 10 vs 10-20 wand damage), nothing between "pops" and "boss"

## What others do
- **Nuclear Throne (Vlambeer):** stack feedback (shake + hitstop + particles + loud sound), low enemy HP, many enemies. Big shakes only on kills/crits
- **Enter the Gungeon:** enemy variety is the fun, each enemy is a pattern to learn. Handmade rooms with cover, stitched by the generator
- **Hades:** each enemy asks a different response, enemies come in waves, rooms grow with the encounter, knockback into walls deals damage
- **Isaac / Gungeon:** kills and room clears charge your active item (= our mana plan)

## Steps

### 1. Juice (hours)
- [x] Sounds: cast, hit, hurt, dash, explosions, UI (+ volume settings)
- [ ] Hitstop on kill (40-80 ms, longer on crits/multikills), in `GlobalMethods`
- [x] Screen shake on explosions: `Signals.screen_shake.emit(trauma)` (0-1), camera (`game_camera.gd`) adds it up, decays it and shakes `offset` by noise * trauma². `Explosion.shake_trauma` = 0.5. Only explosions shake for now (kill/shot shakes skipped on purpose)
- [ ] Death burst: particles or a sprite from `assets/packs/vfx/FreeGameAssets_Magic`, corpse gets a small launch
- [ ] White hit flash instead of red, bigger damage number on the killing blow

### 2. Kills give something (small)
- [ ] Pickups that fly to the player (mana pips later, coins/materials)
- [ ] More `OnEnemyKilled` pacts: kills shoot shards, heal 1, crit kills reset cooldown. Chain reactions = build fun
- [ ] Room-clear bonus (e.g. no-hit clear) via `OnRoomCleared`
- [x] Boss reward: `UpgradeShrine` spawns where the boss was, pick +10 max HP / +10% damage / +10% fire rate (stacks for the run), then the next floor starts

### 3. Encounter tuning (small, mostly data)
- [ ] Spawn rooms in 2-3 waves with a spawn telegraph (`EnemyRoom`)
- [ ] Mix roles in every pool: swarm + one shooter behind it
- [ ] One mid-HP "anchor" enemy per room (5-10 hits)

### 4. Deliberate room design (medium)
- [ ] Pillars / cover: block shots, make Bounce/Ricochet pacts shine
- [ ] Explosive barrels (reuse `Explosion`, it already hits both teams)
- [ ] Hazards (spikes, pits, poison) that hurt enemies too, not only the player
- [ ] Wall slam: knocked-back enemy hitting a wall/hazard takes damage
- [ ] Small rooms early in a floor, big arenas near the boss

### 5. Hazard enemy (medium)
- [ ] Puddles hurt enemies too, or the player can ignite/detonate them
- [ ] Clear telegraph (puddle spreads before it hurts), cap on active puddles
- [ ] Pairs with a mortar/lobber using the `Explosion` telegraph

### 6. Heavy spells + mana (medium-large)
- [ ] Kill-charged pips, RMB spells (see ROADMAP "Mana"). Adds "save it or blow it" decisions and makes kills matter

### 7. Elites (medium)
- [ ] Tint + scale + HP + one effect (exploding shots, split on death, shield) via `EntityBase.effects`, better reward

### 8. Elements & status (large)
- [ ] Burn, freeze-shatter, oil + fire, lightning through water, using `DamageInfo.element`. Combines with hazards, runes, pacts

### 9. More bosses & biomes (largest)
- [ ] Needed long term, but steps 1-4 fix "killing is boring"

**Order:** 1 → 2 + 3 → 4 + 5 (with wall slam) → 6 → 7 → 8 → 9
