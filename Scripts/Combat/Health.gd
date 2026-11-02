extends RefCounted
class_name Health

# shared health logic for the player and enemies
signal changed(current: float, maximum: float)
signal died
# healing past the maximum (Sanguine turns it into a barrier)
signal overhealed(amount: float)
# Thin Blood etc., set by the owner
var heal_multiplier: float = 1.0

var current: float
var maximum: float

func _init(max_value: float) -> void:
	maximum = max_value
	current = max_value

func Damage(amount: float) -> void:
	if IsDead():
		return

	current = max(current - amount, 0.0)
	changed.emit(current, maximum)
	if current <= 0:
		died.emit()

func Heal(amount: float, is_percentage: bool) -> void:
	if IsDead():
		return
	
	var new = amount
	if is_percentage:
		new = maximum*(amount/100)
	new *= heal_multiplier

	var overflow = current + new - maximum
	current = min(current + new, maximum)
	changed.emit(current, maximum)
	if overflow > 0.0:
		overhealed.emit(overflow)

# keeps the same health percentage when max health changes (e.g. armor equipped mid-run)
func SetMaximum(value: float) -> void:
	var ratio = current / maximum if maximum > 0 else 1.0
	maximum = value
	current = maximum * ratio
	changed.emit(current, maximum)

func IsDead() -> bool:
	return current <= 0
