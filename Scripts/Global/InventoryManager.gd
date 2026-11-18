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
