extends Resource
class_name StatusTweak

# run-wide change to a status the player applies to enemies (glyphs: Fuel, Long Fuse, Lingering Chill).
# lives in PactHalf.status_tweaks, summed by RunState over every active half (stacks add up).
# never touches the shared StatusEffect .tres, StatusEffectHolder asks RunState when applying
@export var status: StatusEffect
@export var extra_max_stacks: int = 0
@export var extra_duration: float = 0.0 # 0.5 = lasts 50% longer
@export var extra_stacks_per_application: int = 0 # Deep Cuts: +1 Bleed every time it's applied
