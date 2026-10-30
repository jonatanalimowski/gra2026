class_name PactRarity

# how rare a pact is. AltarRoom.RollOffers rolls the rarity of each offer first (CHANCES),
# then picks a pact of that rarity by weight
enum Rarity { RARE, EPIC, LEGENDARY }

const CHANCES := {
		Rarity.RARE: 0.7,
		Rarity.EPIC: 0.2,
		Rarity.LEGENDARY: 0.1,
}

const NAMES := {
		Rarity.RARE: "Rare",
		Rarity.EPIC: "Epic",
		Rarity.LEGENDARY: "Legendary",
}

const COLORS := {
		Rarity.RARE: Color(0.4, 0.65, 1.0),
		Rarity.EPIC: Color(0.75, 0.4, 1.0),
		Rarity.LEGENDARY: Color(1.0, 0.7, 0.2),
}

static func Roll(rng: RandomNumberGenerator) -> Rarity:
		var roll = rng.randf()
		for rarity in CHANCES:
				roll -= CHANCES[rarity]
				if roll < 0.0:
						return rarity
		return Rarity.RARE

static func GetName(rarity: Rarity) -> String:
		return NAMES.get(rarity, "")

static func GetColor(rarity: Rarity) -> Color:
		return COLORS.get(rarity, Color.WHITE)
