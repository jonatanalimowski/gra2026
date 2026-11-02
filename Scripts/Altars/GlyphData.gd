extends ItemData
class_name GlyphData

# small free pick after a room clear (BUILD_DESIGN.md §6). no curse, stacks up to max_stacks.
# counts 1 school point per stack. only offered for schools you own a pact of, or FORM
@export var blessing: Blessing
@export var school: School.Kind = School.Kind.FORM
@export var max_stacks: int = 3
@export var weight: float = 1.0

func GetSubtitle() -> String:
	var stacks = RunState.GetGlyphStacks(self)
	var text = "Glyph - %s" % School.GetName(school)
	if stacks > 0:
		text += " (%d/%d)" % [stacks, max_stacks]
	return text

func GetSubtitleColor() -> Color:
	return School.GetColor(school)

func GetTagIcons() -> Array[Texture2D]:
	# typed var: a ternary of array literals gives a plain Array, which won't convert on return
	var icons: Array[Texture2D] = []
	var icon_texture = School.GetIcon(school)
	if icon_texture:
		icons.append(icon_texture)
	return icons
