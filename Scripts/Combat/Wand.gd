extends Node
class_name Wand

# runtime version of a WandData, lives as a child of the player
var data: WandData
var primary: SpellCaster # left click
var heavy: SpellCaster # right click, null if the wand has no heavy spell
var runes: Array[RuneData] = []

func Setup(wand_data: WandData) -> void:
	data = wand_data
	runes = []
	for i in min(data.runes.size(), data.rune_slots):
		runes.append(data.runes[i])
	if data.runes.size() > data.rune_slots:
		push_warning(data.display_name + " has more runes than rune slots, extra runes are ignored")

	if data.primary_spell:
		primary = SpellCaster.new(data.primary_spell, runes)
	SetHeavy(data.heavy_spell)

# Heavy slot pacts swap the heavy spell. a fresh caster: the caller re-adds pact modifiers (Player.UpdateHeavy)
func SetHeavy(spell: SpellData) -> void:
	heavy = SpellCaster.new(spell, runes) if spell else null

func GetCasters() -> Array[SpellCaster]:
	var casters: Array[SpellCaster] = []
	if primary:
		casters.append(primary)
	if heavy:
		casters.append(heavy)
	return casters

func _process(delta: float) -> void:
	if primary:
		primary.Tick(delta)
	if heavy:
		heavy.Tick(delta)
