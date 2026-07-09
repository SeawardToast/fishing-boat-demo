extends Node3D

@onready var ocean: Ocean = $Ocean
@onready var boat: FishingBoat = $FishingBoat
@onready var editor_water_preview: MeshInstance3D = $EditorWaterPreview

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if editor_water_preview != null:
		editor_water_preview.visible = false

func _process(_delta: float) -> void:
	if ocean != null and boat != null:
		ocean.set_player_position(boat.global_position)
