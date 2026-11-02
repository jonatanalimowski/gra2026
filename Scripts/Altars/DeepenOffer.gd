extends ItemData
class_name DeepenOffer

# built at runtime by UpgradeShrine: rank II of a slot pact you hold (stronger blessing, same curse)
var pact: AltarPact

static func For(slot_pact: AltarPact) -> DeepenOffer:
	var offer = DeepenOffer.new()
	offer.pact = slot_pact
	offer.display_name = "%s II" % slot_pact.display_name
	offer.description = slot_pact.rank2_blessing.description
	return offer

func Claim() -> void:
	RunState.DeepenPact(pact)

func GetSubtitle() -> String:
	return "Deepen - %s" % AltarPact.GetSlotName(pact.slot)

func GetSubtitleColor() -> Color:
	return School.GetColor(pact.GetSchool())

func GetTagIcons() -> Array[Texture2D]:
	return pact.GetTagIcons()
