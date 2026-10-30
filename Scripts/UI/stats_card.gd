extends MarginContainer
class_name StatsCard

# item name, description, then its stat sections. the card sizes itself to the text;
# when it would be taller than the screen, the sections are spread over more columns side by side
@onready var name_label: Label = %Name
@onready var description_label: RichTextLabel = %Description
@onready var columns: HBoxContainer = %Columns

const SECTION_COLOR = Color("c8a96e")
const GROUP_COLOR = Color("8f8a7e")

# space kept free for the overlay's title + leave button
@export var screen_margin: float = 50.0

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

	# hidden while it tries layouts, containers need a frame to resize
	modulate.a = 0.0
	var max_height = get_viewport_rect().size.y - screen_margin
	for column_count in range(1, max(blocks.size(), 1) + 1):
		FillColumns(blocks, column_count)
		await get_tree().process_frame
		await get_tree().process_frame
		if get_combined_minimum_size().y <= max_height:
			break
	modulate.a = 1.0

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

# same look as the description, but no wrapping so the column is as wide as its longest line
func MakeColumn(text: String) -> RichTextLabel:
	var column: RichTextLabel = description_label.duplicate()
	column.unique_name_in_owner = false
	column.visible = true
	column.autowrap_mode = TextServer.AUTOWRAP_OFF
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
