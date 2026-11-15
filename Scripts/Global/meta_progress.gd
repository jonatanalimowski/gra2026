extends Node

# permanent progress across runs, saved to disk. RunState asks here for meta bonuses
# (skill tree, unlocks) and adds them on top of base values
const SAVE_PATH = "user://meta_progress.cfg"

# extra pacts shown at every altar
var altar_offer_bonus: int = 0
var experience: int = 0
var player_level: int = 1
var level_threshold: int = 100
var level_threshold_growth: float = 1.5
var skill_points: int = 0
var unlocked_skills: Array[SkillData]
var runs_started: int = 0

signal player_leveled_up

func _ready() -> void:
	Load()

func ResetSaved() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	
	cfg.clear()
	SetDefaults()
	player_leveled_up.emit()

func SetDefaults() -> void:
	altar_offer_bonus = 0
	experience = 0
	player_level = 1
	level_threshold = 100
	skill_points = 0
	runs_started = 0
	Save()

func AddXP(amount: int) -> bool:
	var leveled_up = false
	experience += amount
	while experience > level_threshold:
		leveled_up = true
		LevelUp()
	Save()
	return leveled_up

func LevelUp() -> void:
	experience = experience - level_threshold
	@warning_ignore("narrowing_conversion")
	level_threshold *= level_threshold_growth
	player_level += 1
	skill_points += 1
	print("Player leveled up!! skillpoints: ", skill_points)
	player_leveled_up.emit()

func Save() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("upgrades", "altar_offer_bonus", altar_offer_bonus)
	cfg.set_value("player_data", "experience", experience)
	cfg.set_value("player_data", "level", player_level)
	cfg.set_value("player_data", "skill_points", skill_points)
	cfg.set_value("player_data", "level_threshold", level_threshold)
	cfg.set_value("player_data", "runs", runs_started)
	cfg.save(SAVE_PATH)

func Load() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return # no save yet, keep defaults
	altar_offer_bonus = cfg.get_value("upgrades", "altar_offer_bonus", 0)
	experience = cfg.get_value("player_data", "experience", experience)
	player_level = cfg.get_value("player_data", "level", player_level)
	skill_points = cfg.get_value("player_data", "skill_points", skill_points)
	level_threshold = cfg.get_value("player_data", "level_threshold", level_threshold)
	runs_started = cfg.get_value("player_data", "runs", runs_started)

func AddAltarOfferBonus(amount: int = 1) -> void:
	altar_offer_bonus += amount
	Save()
