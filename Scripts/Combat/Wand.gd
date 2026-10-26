extends Node
class_name Wand

# runtime version of a WandData, lives as a child of the player
var data: WandData
var primary: SpellCaster # left click
var heavy: SpellCaster # right click, null if the wand has no heavy spell

func Setup(wand_data: WandData) -> void:
	data = wand_data
	var runes: Array[RuneData] = []
	for i in min(data.runes.size(), data.rune_slots):
		runes.append(data.runes[i])
	if data.runes.size() > data.rune_slots:
		push_warning(data.display_name + " has more runes than rune slots, extra runes are ignored")

	if data.primary_spell:
		primary = SpellCaster.new(data.primary_spell, runes)
	if data.heavy_spell:
		heavy = SpellCaster.new(data.heavy_spell, runes)

func _process(delta: float) -> void:
	if primary:
		primary.Tick(delta)
	if heavy:
		heavy.Tick(delta)

func CastPrimary(caster: Node2D, direction: Vector2, spawn_pos: Vector2, extra_effects: Array[Effect]) -> void:
	if primary:
		primary.TryCast(caster, direction, spawn_pos, extra_effects)

func CastHeavy(caster: Node2D, direction: Vector2, spawn_pos: Vector2, extra_effects: Array[Effect]) -> void:
	if heavy:
		heavy.TryCast(caster, direction, spawn_pos, extra_effects)
