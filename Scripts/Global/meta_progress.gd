extends Node

# permanent progress across runs, saved to disk. plain data only (numbers + ids):
# rules live in SkillManager, rewards are derived from unlocked_ids when a run starts
const SAVE_PATH = "user://meta_progress.cfg"
const BASE_LEVEL_THRESHOLD = 50

# extra pacts shown at every altar
var altar_offer_bonus: int = 0
var experience: int = 0
var player_level: int = 1
var level_threshold_growth: float = 1.5
var skill_points: int = 0
var unlocked_ids: Dictionary = {} # StringName skill id -> true
var runs_started: int = 0
var last_schools: Array[String] = [] # School ids picked in the last loadout
var last_wand: String = "" # WandData id picked in the last loadout
var last_keystones: Array[String] = [] # KeystoneData ids picked in the last loadout

signal player_leveled_up

func _ready() -> void:
	Load()

func GetLevelThreshold() -> int:
	return GetThresholdForLevel(player_level)

func GetThresholdForLevel(level: int) -> int:
	return int(BASE_LEVEL_THRESHOLD * pow(level_threshold_growth, level - 1))

func ResetSaved() -> void:
	altar_offer_bonus = 0
	experience = 0
	player_level = 1
	skill_points = 0
	runs_started = 0
	unlocked_ids.clear()
	last_schools.clear()
	last_wand = ""
	last_keystones.clear()
	Save()
	player_leveled_up.emit()
	Signals.meta_progress_changed.emit()

func AddXP(amount: int) -> bool:
	var leveled_up = false
	experience += amount
	while experience >= GetLevelThreshold():
		leveled_up = true
		LevelUp()
	Save()
	return leveled_up

func LevelUp() -> void:
	experience -= GetLevelThreshold()
	player_level += 1
	skill_points += 1
	player_leveled_up.emit()

func Save() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("upgrades", "altar_offer_bonus", altar_offer_bonus)
	cfg.set_value("player_data", "experience", experience)
	cfg.set_value("player_data", "level", player_level)
	cfg.set_value("player_data", "skill_points", skill_points)
	cfg.set_value("player_data", "runs", runs_started)
	var ids: Array[String] = []
	for id in unlocked_ids:
		ids.append(String(id))
	cfg.set_value("skills", "unlocked", ids)
	cfg.set_value("loadout", "schools", last_schools)
	cfg.set_value("loadout", "wand", last_wand)
	cfg.set_value("loadout", "keystones", last_keystones)
	cfg.save(SAVE_PATH)

func Load() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return # no save yet, keep defaults
	altar_offer_bonus = cfg.get_value("upgrades", "altar_offer_bonus", 0)
	experience = cfg.get_value("player_data", "experience", experience)
	player_level = cfg.get_value("player_data", "level", player_level)
	skill_points = cfg.get_value("player_data", "skill_points", skill_points)
	runs_started = cfg.get_value("player_data", "runs", runs_started)
	last_schools.assign(cfg.get_value("loadout", "schools", []))
	last_wand = cfg.get_value("loadout", "wand", "")
	last_keystones.assign(cfg.get_value("loadout", "keystones", []))

	unlocked_ids.clear()
	for id in cfg.get_value("skills", "unlocked", []):
		unlocked_ids[StringName(id)] = true

	if cfg.has_section_key("skills", "unlocked_skills"):
		for path in cfg.get_value("skills", "unlocked_skills", []):
			var skill = load(path) as SkillData if ResourceLoader.exists(path) else null
			if skill and skill.id != &"":
				unlocked_ids[skill.id] = true
		Save()

func AddAltarOfferBonus(amount: int = 1) -> void:
	altar_offer_bonus += amount
	Save()

# called on every loadout pick, so leaving the screen still remembers it
func SetLastLoadout(wand_id: String, school_ids: Array, keystone_ids: Array = []) -> void:
	last_wand = wand_id
	last_schools.assign(school_ids)
	last_keystones.assign(keystone_ids)
	Save()
