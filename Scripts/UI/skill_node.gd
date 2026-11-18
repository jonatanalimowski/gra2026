extends Control
class_name SkillNode

enum State { LOCKED, AVAILABLE, AFFORDABLE, UNLOCKED }

# one button in the skill tree. shows the state SkillManager reports, holds no rules itself
@onready var icon: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var button: Button = %Button
@onready var border: Panel = %Border
@onready var icon_mask: Panel = %IconMask # clip_children: the icon only shows inside its rounded panel

@export var skill_data: SkillData

# colors per state: border, background, icon tint, name tint
@export_group("Unlocked")
@export var unlocked_border: Color = Color(1.0, 0.78, 0.32)
@export var unlocked_bg: Color = Color(0.32, 0.22, 0.08)
@export var unlocked_icon: Color = Color.WHITE
@export var unlocked_text: Color = Color(1.0, 0.86, 0.5)
@export_group("Available")
@export var available_border: Color = Color(0.4, 0.85, 1.0)
@export var available_bg: Color = Color(0.08, 0.16, 0.22)
@export var available_icon: Color = Color(0.85, 0.85, 0.85)
@export var available_text: Color = Color(0.75, 0.92, 1.0)
@export_group("Locked")
@export var locked_border: Color = Color(0.28, 0.27, 0.32)
@export var locked_bg: Color = Color(0.07, 0.07, 0.09)
@export var locked_icon: Color = Color(0.3, 0.3, 0.33)
@export var locked_text: Color = Color(0.45, 0.45, 0.5)
@export_group("")
@export var selected_border: Color = Color.WHITE
@export var pulse_speed: float = 3.0 # affordable nodes breathe their glow
@export var corner_radius: int = 6 # border corners, icon + button use the inner radius so the shapes nest
@export var border_width: int = 2

signal node_picked(node: SkillNode)

var border_style: StyleBoxFlat
var state: State = State.LOCKED
var is_selected: bool = false
var is_hovered: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	set_process(false) # Refresh turns it on for affordable nodes
	if not skill_data:
		push_warning(name + " has no skill_data")
		return
	name_label.text = skill_data.display_name
	icon.texture = skill_data.icon
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_hover_changed.bind(true))
	button.mouse_exited.connect(_on_hover_changed.bind(false))
	border_style = StyleBoxFlat.new()
	border_style.set_border_width_all(border_width)
	border_style.set_corner_radius_all(corner_radius)
	border.add_theme_stylebox_override("panel", border_style)
	var inner_radius = maxi(corner_radius - border_width, 0)
	icon_mask.add_theme_stylebox_override("panel", MakeRoundedBox(Color.WHITE, inner_radius))
	SetupButtonStyles(inner_radius)
	Refresh()

func Refresh() -> void:
	if not skill_data or not border_style:
		return
	if SkillManager.IsUnlocked(skill_data):
		state = State.UNLOCKED
	elif SkillManager.CanUnlock(skill_data):
		state = State.AFFORDABLE
	elif SkillManager.PrerequisitesMet(skill_data):
		state = State.AVAILABLE
	else:
		state = State.LOCKED
	set_process(state == State.AFFORDABLE)
	ApplyLook()

func SetSelected(value: bool) -> void:
	is_selected = value
	ApplyLook()

func ApplyLook() -> void:
	var border_color: Color
	match state:
		State.UNLOCKED:
			border_color = unlocked_border
			border_style.bg_color = unlocked_bg
			icon.modulate = unlocked_icon
			name_label.modulate = unlocked_text
			SetGlow(unlocked_border, 0.45, 4)
		State.AVAILABLE, State.AFFORDABLE:
			border_color = available_border
			border_style.bg_color = available_bg
			icon.modulate = available_icon
			name_label.modulate = available_text
			if state == State.AVAILABLE:
				border_color = available_border.darkened(0.35) # reachable but can't pay yet
				SetGlow(available_border, 0.0, 0)
		State.LOCKED:
			border_color = locked_border
			border_style.bg_color = locked_bg
			icon.modulate = locked_icon
			name_label.modulate = locked_text
			SetGlow(Color.BLACK, 0.0, 0)
	if is_hovered and state != State.LOCKED:
		border_color = border_color.lightened(0.3)
	border_style.border_color = selected_border if is_selected else border_color
	if state == State.AFFORDABLE:
		_process(0.0)

func MakeRoundedBox(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box

# the Border panel is the look, the button only adds a rounded light overlay on hover/press
func SetupButtonStyles(radius: int) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("hover", MakeRoundedBox(Color(1, 1, 1, 0.08), radius))
	button.add_theme_stylebox_override("pressed", MakeRoundedBox(Color(1, 1, 1, 0.2), radius))
	button.add_theme_stylebox_override("hover_pressed", MakeRoundedBox(Color(1, 1, 1, 0.2), radius))

func SetGlow(color: Color, alpha: float, glow_size: int) -> void:
	border_style.shadow_color = Color(color, alpha)
	border_style.shadow_size = glow_size

func _process(delta: float) -> void:
	# only runs while affordable: soft breathing glow says "you can buy this"
	pulse_time += delta
	var t = 0.5 + 0.5 * sin(pulse_time * pulse_speed)
	SetGlow(available_border, lerpf(0.15, 0.55, t), roundi(lerpf(2, 5, t)))

func _on_hover_changed(hovered: bool) -> void:
	is_hovered = hovered
	ApplyLook()

func _on_button_pressed() -> void:
	node_picked.emit(self)

func GetMiddle() -> Vector2:
	return get_global_transform() * (size / 2)

# radius of the node in global space, so lines can stop at the border instead of the center
func GetRadius() -> float:
	return border.size.x * get_global_transform().get_scale().x / 2
