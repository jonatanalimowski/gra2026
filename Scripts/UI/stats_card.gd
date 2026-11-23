extends MarginContainer
class_name StatsCard

# item name, description, then its stat sections. the card has a fixed size (set in the scene),
# the name stays on top and everything under it scrolls
@onready var name_label: Label = %Name
@onready var description_label: RichTextLabel = %Description
@onready var columns: HBoxContainer = %Columns

const SECTION_COLOR = Color("c8a96e")
const GROUP_COLOR = Color("8f8a7e")

# stat sections are split over this many columns side by side
@export var column_count: int = 1

var content: ItemData # anything with GetDisplayStats(), items without stats only show their description

func _ready() -> void:
	if content == null:
		SetName("Missing Name")
		description_label.text = "Missing description"
		return

	SetName(content.display_name)
	var description = content.GetRichDescription()
	description_label.text = description
	description_label.visible = description != ""

	var sections = content.GetDisplayStats()
	var blocks: Array[String] = []
	for section_title in sections:
		blocks.append(BuildSectionText(section_title, sections[section_title]))

	FillColumns(blocks, column_count)

# greedy split: blocks stay in order, a column takes blocks until it has ~1/column_count of all lines
func FillColumns(blocks: Array[String], column_count: int) -> void:
	for child in columns.get_children():
		columns.remove_child(child)
		child.queue_free()
	columns.visible = not blocks.is_empty()

	var total_lines = 0
	for block in blocks:
		total_lines += block.count("\n") + 1
	var target = ceili(float(total_lines) / column_count)

	var texts: Array[String] = []
	var current: Array[String] = []
	var current_lines = 0
	for block in blocks:
		var lines = block.count("\n") + 1
		if not current.is_empty() and current_lines + lines > target and texts.size() < column_count - 1:
			texts.append("\n\n".join(current))
			current = []
			current_lines = 0
		current.append(block)
		current_lines += lines
	if not current.is_empty():
		texts.append("\n\n".join(current))

	for text in texts:
		columns.add_child(MakeColumn(text))

# same look as the description, columns share the card width (long lines wrap)
func MakeColumn(text: String) -> RichTextLabel:
	var column: RichTextLabel = description_label.duplicate()
	column.unique_name_in_owner = false
	column.visible = true
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	column.text = text
	return column

#   Primary
#     Offense         <- optional group (SpellData.STAT_GROUPS)
#       Damage: 20
static func BuildSectionText(section_title: String, stats: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("[color=#%s]%s[/color]" % [SECTION_COLOR.to_html(false), section_title])
	AppendStats(lines, stats, "")
	return "\n".join(lines)

# values are numbers (one stat line) or dictionaries (a group header + its stats, indented)
static func AppendStats(lines: Array[String], stats: Dictionary, indent: String) -> void:
	for key in stats:
		var value = stats[key]
		if value is Dictionary:
			lines.append("%s[color=#%s]%s[/color]" % [indent, GROUP_COLOR.to_html(false), key])
			AppendStats(lines, value, indent + "  ")
		else:
			lines.append(indent + StatBlock.FormatStat(key, value))

func SetName(text: String) -> void:
	name_label.text = text
