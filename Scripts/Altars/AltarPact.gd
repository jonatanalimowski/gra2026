extends ItemData
class_name AltarPact

# a blessing + curse offered together at an altar. name/icon come from ItemData (display_name, icon).
# the halves are separate resources (Data/Blessings, Data/Curses), see PactHalf
@export var blessing: Blessing
@export var curse: Curse

#pool settings
@export var weight: float = 1.0
@export var min_floor: int = 1

func GetDescription() -> String:
	return "%s\n\nCURSE: %s" % [_Text(blessing), _Text(curse)]

const BUFF_COLOR = Color(0.7, 1.0, 0.7)
const CURSE_COLOR = Color(1.0, 0.7, 0.7)

func GetRichDescription() -> String:
	return "[color=#%s]%s[/color]\n\n[color=#%s]CURSE: %s[/color]" % [
		BUFF_COLOR.to_html(false), _Text(blessing), CURSE_COLOR.to_html(false), _Text(curse)]

func GetTagIcons() -> Array[Texture2D]:
	if blessing == null:
		return []
	return [PactType.GetIcon(blessing.type)]

func _Text(half: PactHalf) -> String:
	return half.description if half else "-"
