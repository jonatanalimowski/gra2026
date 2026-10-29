extends ItemData
class_name StatUpgrade

# small permanent buff for the rest of the run (boss reward). no curse, stacks every time it's taken.
# reuses Blessing so the player/HUD apply it like any other half (RunState.AddHalf)
@export var blessing: Blessing

func GetTagIcons() -> Array[Texture2D]:
	if blessing == null:
		return []
	return [PactType.GetIcon(blessing.type)]
