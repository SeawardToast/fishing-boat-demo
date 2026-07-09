class_name WaterBuoyancySensor extends Marker3D

@export var height: float = 1.0
@export var buoyancy_multiplier: float = 1.0
@export var debug_water_gap: bool = false
@export var debug_print_interval: float = 0.5

var ocean_node: Ocean
var _debug_timer: float = 0.0

func _ready() -> void:
	if !ocean_node:
		ocean_node = get_tree().get_first_node_in_group("ocean") as Ocean

var water_height: float = 0.0
var water_normal: Vector3 = Vector3.UP
var water_force: Vector3 = Vector3.ZERO


func is_in_water() -> bool:
	return water_height >= global_position.y    

func is_under_water() -> bool:
	return water_height >= global_position.y + height

func is_on_water() -> bool:
	return is_in_water() and not is_under_water()


func get_water_height() -> float:
	return water_height
	
func get_water_depth() -> float:
	return global_position.y - water_height 

func _physics_process(delta: float) -> void:
	if ocean_node != null and ocean_node.ocean != null and ocean_node.ocean.initialized:
		water_height = ocean_node.get_wave_height(global_position, 3, 5)
	else:
		water_height = 0.0
		
	if debug_water_gap:
		_debug_timer += delta
		if _debug_timer >= debug_print_interval:
			_debug_timer = 0.0
			print(name, " sensor_y=", global_position.y, " water_y=", water_height, " depth=", get_water_depth())
		
func compute_normal() -> Vector3:
	if ocean_node:
		var offset: float = 0.1
		var dx: float = (ocean_node.get_wave_height(global_position + Vector3(offset,0,0), 3, 5) - water_height) / offset;
		var dz: float = (ocean_node.get_wave_height(global_position + Vector3(0,0,offset), 3, 5) - water_height) / offset;
		return Vector3(-dx, 1.0, -dz).normalized();
		
	else: 
		return Vector3(0, 1, 0)
