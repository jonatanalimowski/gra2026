class_name School

# a build school (BUILD_DESIGN.md §3): each owns a status. FORM = neutral projectile-shape pacts/glyphs.
# used by pacts, glyphs, statuses, wand affinity and the HUD
enum Kind { NONE, EMBER, FROST, STORM, BLOOD, FORM }

const NAMES := {
		Kind.NONE: "",
		Kind.EMBER: "Ember",
		Kind.FROST: "Frost",
		Kind.STORM: "Storm",
		Kind.BLOOD: "Blood",
		Kind.FORM: "Form",
}

const COLORS := {
		Kind.EMBER: Color(1.0, 0.55, 0.15),
		Kind.FROST: Color(0.55, 0.8, 1.0),
		Kind.STORM: Color(1.0, 0.9, 0.3),
		Kind.BLOOD: Color(0.8, 0.1, 0.2),
		Kind.FORM: Color(0.7, 0.6, 1.0),
}

const ICONS := {
		Kind.EMBER: preload("res://assets/icons/school_ember.png"),
		Kind.FROST: preload("res://assets/icons/school_frost.png"),
		Kind.STORM: preload("res://assets/icons/school_storm.png"),
		Kind.BLOOD: preload("res://assets/icons/school_blood.png"),
		Kind.FORM: preload("res://assets/icons/school_form.png"),
}

static func GetName(school: Kind) -> String:
		return NAMES.get(school, "")

static func GetColor(school: Kind) -> Color:
		return COLORS.get(school, Color.WHITE)

static func GetIcon(school: Kind) -> Texture2D:
		return ICONS.get(school)
