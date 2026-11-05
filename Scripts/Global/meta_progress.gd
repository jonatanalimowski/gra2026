extends Node

# permanent progress across runs, saved to disk. RunState asks here for meta bonuses
# (skill tree, unlocks) and adds them on top of base values
const SAVE_PATH = "user://meta_progress.cfg"

# extra pacts shown at every altar
var altar_offer_bonus: int = 0
var experience: int = 0

func _ready() -> void:
	Load()

func Save() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("upgrades", "altar_offer_bonus", altar_offer_bonus)
	cfg.set_value("player_data", "experience", experience)
	cfg.save(SAVE_PATH)

func Load() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return # no save yet, keep defaults
	altar_offer_bonus = cfg.get_value("upgrades", "altar_offer_bonus", 0)
	experience = cfg.get_value("player_data", "experience", experience)

func AddAltarOfferBonus(amount: int = 1) -> void:
	altar_offer_bonus += amount
	Save()
