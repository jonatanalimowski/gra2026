extends Node

const wands: Dictionary[String, WandData] = {
	"PurpleBolt": preload("res://Data/Wands/PurpleBoltWand.tres"),
	"Gamba": preload("res://Data/Wands/FlameShurikenWand.tres"),
	"Blue": preload("res://Data/Wands/BlueBlinkerWand.tres")
}

func _ready() -> void:
	pass

func GetWands() -> Array[WandData]:
	return wands.values()

func ApplyRune(wand_name: String, rune: RuneData) -> void:
	var wand: WandData = wands.get(wand_name, null)
	if wand == null:
		return
	
	wand.runes.append(rune)
	return

func RemoveRune(wand_name: String, rune: RuneData) -> void:
	var wand: WandData = wands.get(wand_name, null)
	if wand == null:
		return
	
	wand.runes.erase(rune)
