extends Control

# cheat panel, shown/hidden by the DevTools autoload.
# every option is built here so the scene doesn't need editing for each new cheat
func _ready() -> void:
	var vbox = %ButtonList
	AddToggleButton(vbox, "Invincible", DevTools.invincible, _on_invincible_toggled)
	AddToggleButton(vbox, "10X Damage", DevTools.x10damage, _on_10x_damage_toggled)
	AddToggleButton(vbox, "All enemy elites", DevTools.more_elites, _on_more_elites_toggled)
	AddActionButton(vbox, "Altar offer (F7)", _on_altar_offer_pressed)
	AddActionButton(vbox, "Cleanse curses", _on_cleanse_curses_pressed)
	AddActionButton(vbox, "Teleport to boss", _on_teleport_to_boss_pressed)

# focus off everywhere so space/enter can't press a cheat while playing
func AddActionButton(parent: Node, text: String, callback: Callable) -> void:
	var button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)

func AddToggleButton(parent: Node, text: String, on: bool, callback: Callable) -> void:
	var button = CheckButton.new()
	button.text = text
	button.button_pressed = on
	button.focus_mode = Control.FOCUS_NONE
	button.toggled.connect(callback)
	parent.add_child(button)

func _on_invincible_toggled(on: bool) -> void:
	DevTools.invincible = on

func _on_10x_damage_toggled(on: bool) -> void:
	DevTools.x10damage = on

func _on_more_elites_toggled(on: bool) -> void:
	DevTools.more_elites = on

func _on_altar_offer_pressed() -> void:
	if NodeReferences.player and not get_tree().paused:
		DevTools.OpenPactChoice()

func _on_cleanse_curses_pressed() -> void:
	for curse in RunState.GetActiveCurses():
		RunState.CleanseCurse(curse)

# lands a bit below the boss spawn, inside the detection area, so the fight starts right away
func _on_teleport_to_boss_pressed() -> void:
	var player = NodeReferences.player
	var room = FindBossRoom(get_tree().current_scene)
	if not player or not room:
		return
	player.global_position = room.boss_spawn.global_position + Vector2(0, 100)

func FindBossRoom(node: Node) -> BossRoom:
	if node is BossRoom:
		return node
	for child in node.get_children():
		var found = FindBossRoom(child)
		if found:
			return found
	return null
