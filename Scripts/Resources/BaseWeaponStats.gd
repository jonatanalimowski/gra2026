extends Resource
class_name WeaponStats

@export var has_magazine: bool = false
@export var fire_rate: float = 0.5
@export var shots_in_chamber: int = 1
@export var reload_time: int = 2
@export var shot_count: int = 1
@export var firing_inaccuracy: float = 10 #inaccuracy in angles
@export var damage = 25

var shots_left: int = 1
var current_slot: int = 1
const STAT_IGNORE_IN_DISPLAY = ["has_magazine", "shots_in_chamber", "current_slot", "shots_left"]
const STAT_DETAILED = ["reload_time", "firing_inaccuracy"]

func GetStatsAsDict() -> Dictionary[String, float]:
	var stats_dict = {}
	var properties = get_property_list()
	
	for prop in properties:
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			if prop.name in STAT_IGNORE_IN_DISPLAY:
				continue
			
			stats_dict[prop.name] = get(prop.name)
	return stats_dict

func update_stat(stat_name: String, value: float) -> void:
	if stat_name in self:
		set(stat_name, value)
		Signals.weapon_stat_changed.emit(stat_name, value, current_slot)
	else:
		print("NO STAT CALLED: " + stat_name)
