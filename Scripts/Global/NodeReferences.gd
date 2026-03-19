extends Node

enum PLAYER_CLASSES {
	MELEE,
	MAGE,
	ROGUE
}
var player: CharacterBody2D = null
var chosen_primary: PackedScene
var chosen_secondary: PackedScene
var chosen_class: PLAYER_CLASSES
var chosen_weapon: PackedScene
