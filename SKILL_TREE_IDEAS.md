# Skill Tree Ideas (draft)

**Main problem:** the tree must not take away from building inside the run, but still let the player express a playstyle.
A branch makes a playstyle *possible and likely*, it doesn't *grant* it.

## Node rules
A node earns its place if it does at least one of these:
- **(a) Adds content** - new pacts / glyphs / runes go into the pools.
- **(b) Changes a rule with a trade-off** - keystone-style, changes how you play, has a real drawback.
- **(c) Connects two systems** - a new interaction that wasn't there (e.g. freeze -> mana).

Avoid plain "your school is stronger" nodes: they compete with in-run glyphs that do the same.
Keystones should be exclusive (keystone slots in PreRunScreen, or an exclusive group), since refunds are free.

---

## General (trunk)
- **Altar Reroll** (utility) - +1 reroll per run at an altar.
- **Glyph Reroll** (utility) - +1 reroll per run at a glyph shrine.
- **Banish** (b) - remove a pact from the pool for the rest of the run, but that altar shows one fewer card.
- **Curse Trials** (c) - some curses come with a goal ("kill 40 enemies"); completing it cleanses the curse.
- **Wider Forms** (a) - unlocks new verbless Form pacts (cap Form pacts, e.g. 3, or use `max_stacks`).

## Precision (crit)
- **Crits Apply Your Status** (a)(c) - pact unlock: crits apply the status of your **primary slot pact's school** (no primary pact = nothing).
- **Glass Edge** (b, keystone) - crits deal x2.5, non-crits deal -40%.
- **First Strike** (b, keystone) - the first hit on each enemy always crits, after that you can't crit it. Rewards spreading hits (pierce, ricochet, multishot).
- **Crit Ricochet** (a) - rune for the non-Purple-Bolt wands: critting projectiles ricochet once for 50% damage.
- Decide after a playtest whether Glass Edge + First Strike are exclusive or a fun "assassin" combo.

## Ember (AoE + DoT, slow spreading)
- **Wildfire** (c) - every ~1s a Burning enemy passes 1 Burn stack to the nearest enemy within ~60px (tick-based, not collision).
- **Afterblast** (b, keystone) - every explosion goes off again after ~0.5s at 60% size (with its own telegraph), but your explosions can hit you (`explosions_hit_player`).
- **Ember pact unlocks** (a) - a second pact per verb for Ember.

## Frost (debuffs + crowd control)
- **Cold Harvest** (c) - freezing an enemy drops a mana orb (`ManaOrb.SpawnBurst`, so mana still only comes from orbs).
- **Deep Chill** (b) - Chill slows more per stack, but freezing needs +2 stacks. (Needs a `modifier_multiplier` on `StatusTweak`.)
- **Frost pact unlocks** (a) - a second pact per verb for Frost.

## Storm (instant chain reactions)
Naming: **Shock** = the status, **Arc** = the damage that jumps after a hit on a Shocked enemy.
- **Feedback** (c) - critical arcs apply Shock again (links the Precision branch; loop-safe since arcs never discharge). Check that arcs can crit.
- **Capacitor** (b) - Shock holds 2 charges and discharges twice, but each arc deals 35% instead of 50%.
- **Static Snap** (b) - arcs micro-stun for ~0.2s (through hitstun, so `hitstun_cooldown` stops stunlocks), but arcs deal -20%. Keep it short, so it doesn't steal Frost's role.
- **Storm pact unlocks** (a) - a second pact per verb for Storm.

## Blood (tentative, role being rethought)
Current lean: HP as a resource.
- **Last Stand** (b, keystone) - below 30% HP: damage x1.6 and kills heal 2 HP, but Sanctuary heals are halved.
- **Sanguine Harvest** (c) - Bleeding enemies drop a heal mote on death (`ManaOrb.SpawnMote`).
- **Blood pact unlocks** (a) - a second pact per verb for Blood.

---

## Other notes
- **Heavy rework:** every wand starts with the same basic heavy (e.g. +50% fire rate for 3s, costs mana), so a pact replacing it feels like an upgrade. Give each wand a small **passive trait** to keep wands distinct.
- **Poison-trail enemy:** leaves small poison `StatusArea`s behind it (like `FireTrailArea`). Slow and tanky. Name it by its archetype (e.g. `Seeper`).
- **Loadout schools:** pick ~3 unlocked schools per run; only those + Form pacts get offered. Needs a minimum count.
- **Dropped:** "arcs hit more enemies" (the `fork` / `long_arc` flags already do it in-run), "Shock lasts longer" (barely noticeable, replaced by Capacitor).
