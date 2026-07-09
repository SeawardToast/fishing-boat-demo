class_name BuoyantBody3D extends RigidBody3D

@export_group("Buoyancy")
@export var buoyancy_multiplier: float = 150.0
@export_range(0.5, 10.0, 0.001) var buoyancy_power: float = 1.5
@export var buoyancy_damping: float = 0.0

@export_group("Generic Submerged Damping")
@export var apply_generic_submerged_damping: bool = true
@export var submerged_drag_linear: float = 0.05
@export var submerged_drag_angular: float = 0.1

@export_group("Upright Stability")
@export var upright_strength: float = 2.0
@export var upright_damping: float = 1.0

var submerged: bool = false
var submerged_probes: int = 0
var _buoyancy_sensors: Array[WaterBuoyancySensor] = []

func _ready() -> void:
	_buoyancy_sensors.clear()
	for child in get_children(true):
		if child is WaterBuoyancySensor:
			_buoyancy_sensors.append(child)

func _physics_process(delta: float) -> void:
	var gravity_direction: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector") as Vector3
	var gravity_strength: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	submerged_probes = 0
	submerged = false
	
	for sensor in _buoyancy_sensors:
		var depth: float = sensor.get_water_depth();
		
		if depth < 0.0:
			submerged = true
			submerged_probes += 1
			var submerged_depth: float = clampf(-depth, 0.0, sensor.height)
			var submerged_ratio: float = submerged_depth / sensor.height
			var buoyancy: float = pow(submerged_depth, buoyancy_power)
			var force: Vector3 = -gravity_direction * gravity_strength * buoyancy * buoyancy_multiplier * sensor.buoyancy_multiplier
			
			apply_force(force, sensor.global_position - global_position)

			if buoyancy_damping > 0.0:
				var point_offset: Vector3 = sensor.global_position - global_position
				var point_velocity: Vector3 = linear_velocity + angular_velocity.cross(point_offset)
				var vertical_speed: float = point_velocity.dot(-gravity_direction)
				var damping_force: Vector3 = gravity_direction * vertical_speed * buoyancy_damping * submerged_ratio * sensor.buoyancy_multiplier
				apply_force(damping_force, point_offset)

	if submerged and upright_strength > 0.0:
		_apply_upright_stability()

func _apply_upright_stability() -> void:
	var current_up: Vector3 = global_transform.basis.y.normalized()
	var correction_axis: Vector3 = current_up.cross(Vector3.UP)
	apply_torque(correction_axis * upright_strength)

	if upright_damping > 0.0:
		var yaw_spin: Vector3 = Vector3.UP * angular_velocity.dot(Vector3.UP)
		var roll_pitch_spin: Vector3 = angular_velocity - yaw_spin
		apply_torque(-roll_pitch_spin * upright_damping)

func _integrate_forces(_state:PhysicsDirectBodyState3D) -> void:
	if submerged and apply_generic_submerged_damping:
		_apply_generic_submerged_damping()

func _apply_generic_submerged_damping() -> void:
	var linear_scale: float = clampf(1.0 - submerged_drag_linear, 0.0, 1.0)
	var angular_scale: float = clampf(1.0 - submerged_drag_angular, 0.0, 1.0)
	linear_velocity *= linear_scale
	angular_velocity *= angular_scale
