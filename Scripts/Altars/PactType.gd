class_name PactType

enum Type { SELF, SPELL, ENEMY }

const ICONS := {
		Type.SELF: preload("res://assets/icons/pact_self.png"),
		Type.SPELL: preload("res://assets/icons/pact_spell.png"),
		Type.ENEMY: preload("res://assets/icons/pact_enemy.png"),
}

static func GetIcon(type: Type) -> Texture2D:
		return ICONS.get(type)
