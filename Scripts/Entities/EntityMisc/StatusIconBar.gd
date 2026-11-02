extends Node2D
class_name StatusIconBar

# layer 1 of status readability (BUILD_DESIGN.md §9): small icons above the head, stack pips under each.
# drawn like TelegraphMark, created by Entity._ready. same size on elites/bosses (counter-scaled)
const ICON_SIZE: int = 7
const GAP: int = 1
const MAX_ICONS: int = 4 # the oldest statuses hide first
const MAX_PIPS: int = 5
const MARGIN: float = 3.0 # above the sprite top
const TELEGRAPH_OFFSET: float = 14.0 # the "!" stays the most visible thing, the bar moves above it
const FADE_TIME: float = 0.5 # icon fades when this little time is left
const FADED_ALPHA: float = 0.3
const PIP_COLOR: Color = Color(1, 1, 1)
const OUTLINE_COLOR: Color = Color(0, 0, 0, 0.8)

var entity: Entity
var holder: StatusEffectHolder

func Setup(owner_entity: Entity) -> void:
	entity = owner_entity
	holder = entity.status_holder
	z_index = 10

const AFFIX_FRAME: Color = Color(1.0, 0.8, 0.25)
const WARD_ICONS := {
	&"ember": preload("res://assets/icons/status_burn.png"),
	&"frost": preload("res://assets/icons/status_chill.png"),
	&"storm": preload("res://assets/icons/status_shock.png"),
	&"blood": preload("res://assets/icons/status_bleed.png"),
}

func _process(_delta: float) -> void:
	visible = not holder.active.is_empty() or not entity.affixes.is_empty() or entity.ward_group != &""
	if not visible:
		return
	scale = Vector2.ONE / entity.scale
	var y = entity.GetSpriteTop() - MARGIN
	if is_instance_valid(entity.telegraph_mark):
		y -= TELEGRAPH_OFFSET / entity.scale.y
	position = Vector2(0, y)
	queue_redraw()

func _draw() -> void:
	var shown := holder.active.slice(maxi(holder.active.size() - MAX_ICONS, 0))
	# affixes (and a ward) first, always visible, so an elite reads at a glance
	var affix_icons: Array = []
	for affix in entity.affixes:
		if affix.kind == Affix.Kind.WARDED:
			continue # drawn as the warded status icon, crossed out
		affix_icons.append(affix.icon)
	var ward_icon = WARD_ICONS.get(entity.ward_group)
	var total: int = shown.size() + affix_icons.size() + (1 if ward_icon else 0)
	var width := total * ICON_SIZE + (total - 1) * GAP
	var x := -width / 2.0
	for icon in affix_icons:
		var rect := Rect2(x, -ICON_SIZE - 2, ICON_SIZE, ICON_SIZE)
		draw_rect(rect.grow(1), AFFIX_FRAME, false, 1.0)
		if icon:
			draw_texture_rect(icon, rect, false)
		x += ICON_SIZE + GAP
	if ward_icon:
		var rect := Rect2(x, -ICON_SIZE - 2, ICON_SIZE, ICON_SIZE)
		draw_rect(rect.grow(1), AFFIX_FRAME, false, 1.0)
		draw_texture_rect(ward_icon, rect, false, Color(1, 1, 1, 0.6))
		draw_line(rect.position, rect.end, Color(1, 0.2, 0.2), 1.0)
		draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.position.y), Color(1, 0.2, 0.2), 1.0)
		x += ICON_SIZE + GAP
	# icons sit above the origin, pips in the 2px row under them
	for status in shown:
		var alpha := FADED_ALPHA if status.time_left < FADE_TIME else 1.0
		var rect := Rect2(x, -ICON_SIZE - 2, ICON_SIZE, ICON_SIZE)
		if status.effect.icon:
			draw_texture_rect(status.effect.icon, rect, false, Color(1, 1, 1, alpha))
		else:
			draw_rect(rect.grow(1), Color(OUTLINE_COLOR, OUTLINE_COLOR.a * alpha))
			draw_rect(rect, Color(status.effect.color, alpha))
		if status.effect.max_stacks > MAX_PIPS:
			DrawCount(x, status.stacks, alpha)
		elif status.effect.max_stacks > 1:
			DrawPips(x, status.stacks, alpha)
		x += ICON_SIZE + GAP

# Bleed (10 stacks) shows a number in the icon's corner instead of pips
func DrawCount(icon_x: float, stacks: int, alpha: float) -> void:
	var font = ThemeDB.fallback_font
	var text = str(stacks)
	var pos = Vector2(icon_x + ICON_SIZE - 2, 0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, 2, Color(OUTLINE_COLOR, alpha))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(PIP_COLOR, alpha))

# one 1px dot per stack, centered under the icon, with a dark backing so it reads on any floor
func DrawPips(icon_x: float, stacks: int, alpha: float) -> void:
	var count := mini(stacks, MAX_PIPS)
	var pips_width := count * 2 - 1
	var start := icon_x + floorf((ICON_SIZE - pips_width) / 2.0)
	draw_rect(Rect2(start - 1, -2, pips_width + 2, 3), Color(OUTLINE_COLOR, OUTLINE_COLOR.a * alpha))
	for i in count:
		draw_rect(Rect2(start + i * 2, -1, 1, 1), Color(PIP_COLOR, alpha))
