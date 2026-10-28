extends Control
class_name StatsCard

@onready var name_label: Label = %Name
@onready var description_label: RichTextLabel = %Description

const SECTION_COLOR = Color("c8a96e")

var content: ItemData # anything with GetDisplayStats(), items without stats only show their description

func _ready() -> void:
	if content:
		SetName(content.display_name)
		SetDescription(BuildStatsText(content))
	else:
		SetName("Missing Name")
		SetDescription("Missing description")

# description, then one block per stat section:
#   [Primary]
#   Damage: 20
static func BuildStatsText(item: ItemData) -> String:
	var lines: Array[String] = []
	var description = item.GetRichDescription()
	if description != "":
		lines.append(description)

	var sections = item.GetDisplayStats()
	for section_title in sections:
		if not lines.is_empty():
			lines.append("")
		lines.append("[color=#%s]%s[/color]" % [SECTION_COLOR.to_html(false), section_title])
		var stats: Dictionary = sections[section_title]
		for stat_name in stats:
			lines.append(StatBlock.FormatStat(stat_name, stats[stat_name]))
	return "\n".join(lines)

func SetName(text: String) -> void:
	name_label.text = text

func SetDescription(text: String) -> void:
	description_label.text = text
