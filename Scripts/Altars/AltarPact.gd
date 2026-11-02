extends ItemData
class_name AltarPact

# a blessing + curse offered together at an altar. name/icon come from ItemData (display_name, icon).
# the halves are separate resources (Data/Blessings, Data/Curses), see PactHalf.
# every slot pact needs its OWN curse resource: replacing a pact removes its halves with
# RunState.RemoveHalf, which would also take a shared curse away from another pact
@export var blessing: Blessing
@export var curse: Curse
@export var is_stacking: bool = false
@export var max_stacks: int = 3 # most times a stacking pact can be taken in a run
@export var rarity: PactRarity.Rarity = PactRarity.Rarity.RARE

# verb slot (BUILD_DESIGN.md §4): one pact per slot, a new one replaces the old one. NONE = Form pact, no slot
enum Slot { NONE, PRIMARY, HEAVY, DASH, KILL, ORB }
const SLOT_NAMES := {
		Slot.NONE: "",
		Slot.PRIMARY: "Primary",
		Slot.HEAVY: "Heavy",
		Slot.DASH: "Dash",
		Slot.KILL: "Kill",
		Slot.ORB: "Orb",
}
@export var slot: Slot = Slot.NONE
# Deepen (boss shrine): replaces the blessing with a stronger one, same curse
@export var rank2_blessing: Blessing

#pool settings
@export var weight: float = 1.0
@export var min_floor: int = 1

func GetMaxStacks() -> int:
	return max_stacks if is_stacking else 1

func IsDeepened() -> bool:
	return self in RunState.deepened_pacts

# rank II once deepened
func GetActiveBlessing() -> Blessing:
	return rank2_blessing if IsDeepened() and rank2_blessing else blessing

func GetSchool() -> School.Kind:
	return blessing.school if blessing else School.Kind.NONE

static func GetSlotName(slot_value: Slot) -> String:
	return SLOT_NAMES.get(slot_value, "")

# the pact this one would push out of its slot, null if the slot is free (or holds this pact)
func GetReplacedPact() -> AltarPact:
	if slot == Slot.NONE:
		return null
	var current = RunState.GetSlotPact(slot)
	return current if current != self else null

func GetDescription() -> String:
	var text = "%s\n\nCURSE: %s" % [_Text(GetActiveBlessing()), _Text(curse)]
	var replaced = GetReplacedPact()
	if replaced:
		text = "Replaces %s\n\n%s" % [replaced.display_name, text]
	return text

const BUFF_COLOR = Color(0.7, 1.0, 0.7)
const CURSE_COLOR = Color(1.0, 0.7, 0.7)
const REPLACE_COLOR = Color(1.0, 0.35, 0.35)

func GetRichDescription() -> String:
	var text = "[color=#%s]%s[/color]\n\n[color=#%s]CURSE: %s[/color]" % [
		BUFF_COLOR.to_html(false), _Text(GetActiveBlessing()), CURSE_COLOR.to_html(false), _Text(curse)]
	var replaced = GetReplacedPact()
	if replaced:
		text = "[color=#%s]Replaces %s[/color]\n\n%s" % [REPLACE_COLOR.to_html(false), replaced.display_name, text]
	return text

# "Rare - Ember - Heavy"
func GetSubtitle() -> String:
	var parts: Array[String] = [PactRarity.GetName(rarity)]
	if GetSchool() != School.Kind.NONE:
		parts.append(School.GetName(GetSchool()))
	if slot != Slot.NONE:
		parts.append(GetSlotName(slot))
	return " - ".join(parts)

func GetSubtitleColor() -> Color:
	return PactRarity.GetColor(rarity)

# school icon for school pacts, buff type icon for the rest
func GetTagIcons() -> Array[Texture2D]:
	if blessing == null:
		return []
	if blessing.school != School.Kind.NONE:
		return [School.GetIcon(blessing.school)]
	return [PactType.GetIcon(blessing.type)]

func _Text(half: PactHalf) -> String:
	return half.description if half else "-"
