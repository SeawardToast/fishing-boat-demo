class_name FishingBoat
extends BuoyantBody3D

const WATTS_PER_HORSEPOWER: float = 745.7

@export_group("Engine")
@export var engine_horsepower: float = 135.0
@export var engine_torque: float = 360.0
@export var torque_to_thrust: float = 58.0
@export var min_power_speed: float = 1.7
@export var reverse_efficiency: float = 0.55
@export var throttle_response: float = 2.2
@export var throttle_return_response: float = 3.0

@export_group("Prop")
@export var prop_efficiency: float = 0.72
@export var prop_pitch: float = 1.0

@export_group("Hull")
@export var hull_forward_drag: float = 28.0
@export var hull_lateral_drag: float = 62.0
@export var linear_water_damping: float = 0.05
@export var angular_water_damping: float = 0.08

@export_group("Steering")
@export var rudder_force: float = 7600.0
@export var rudder_local_position: Vector3 = Vector3(0.0, -0.25, 2.15)
@export var rudder_response: float = 1.25
@export var rudder_return_response: float = 0.85

@export_group("Camera")
@export var camera_distance: float = 8.0
@export var camera_base_height: float = 1.2
@export var camera_mouse_sensitivity: float = 0.006
@export var camera_min_pitch: float = -0.18
@export var camera_max_pitch: float = 0.62

@onready var chase_camera: Camera3D = $ChaseCamera
@onready var look_target: Marker3D = $LookTarget

var camera_yaw: float = 0.0
var camera_pitch: float = 0.24
var current_throttle: float = 0.0
var current_rudder: float = 0.0

func _ready() -> void:
	super._ready()
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, -0.45, 0.1)
	chase_camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_motion: InputEventMouseMotion = event
		camera_yaw -= mouse_motion.relative.x * camera_mouse_sensitivity
		camera_pitch = clampf(camera_pitch + mouse_motion.relative.y * camera_mouse_sensitivity, camera_min_pitch, camera_max_pitch)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_apply_controls(delta)
	_apply_soft_damping(delta)
	_update_camera()

func _apply_controls(delta: float) -> void:
	var throttle: float = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var steering: float = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	var throttle_rate: float = throttle_response if not is_zero_approx(throttle) else throttle_return_response
	var rudder_rate: float = rudder_response if not is_zero_approx(steering) else rudder_return_response
	current_throttle = move_toward(current_throttle, throttle, throttle_rate * delta)
	current_rudder = move_toward(current_rudder, steering, rudder_rate * delta)

	var forward: Vector3 = -global_transform.basis.z
	var right: Vector3 = global_transform.basis.x
	var forward_speed: float = linear_velocity.dot(forward)
	var propulsion_force: float = _calculate_propulsion_force(current_throttle, forward_speed)
	apply_central_force(forward * propulsion_force)
	_apply_hull_resistance(forward, right)

	var speed_factor: float = clampf(linear_velocity.length() / 9.0, 0.08, 1.0)
	var rudder_world_offset: Vector3 = global_transform.basis * rudder_local_position
	apply_force(right * current_rudder * rudder_force * speed_factor, rudder_world_offset)

func _calculate_propulsion_force(throttle: float, forward_speed: float) -> float:
	if is_zero_approx(throttle):
		return 0.0

	var throttle_sign: float = 1.0 if throttle > 0.0 else -1.0
	var throttle_amount: float = absf(throttle)
	var pitch: float = maxf(prop_pitch, 0.25)
	var directional_speed: float = maxf(forward_speed * throttle_sign, 0.0)
	var speed_for_power: float = maxf(directional_speed, min_power_speed)
	var power_limited_force: float = engine_horsepower * WATTS_PER_HORSEPOWER * pitch / speed_for_power
	var torque_limited_force: float = engine_torque * torque_to_thrust / pitch
	var direction_efficiency: float = 1.0 if throttle_sign > 0.0 else reverse_efficiency
	var available_force: float = minf(power_limited_force, torque_limited_force)

	return available_force * prop_efficiency * direction_efficiency * throttle_amount * throttle_sign

func _apply_hull_resistance(forward: Vector3, right: Vector3) -> void:
	if not submerged:
		return

	var forward_speed: float = linear_velocity.dot(forward)
	var lateral_speed: float = linear_velocity.dot(right)
	var forward_drag_force: Vector3 = -forward * forward_speed * absf(forward_speed) * hull_forward_drag
	var lateral_drag_force: Vector3 = -right * lateral_speed * absf(lateral_speed) * hull_lateral_drag
	apply_central_force(forward_drag_force + lateral_drag_force)

func _apply_soft_damping(delta: float) -> void:
	if not submerged:
		return
	linear_velocity = linear_velocity.lerp(Vector3.ZERO, linear_water_damping * delta)
	angular_velocity = angular_velocity.lerp(Vector3.ZERO, angular_water_damping * delta)

func _update_camera() -> void:
	if chase_camera == null or look_target == null:
		return
	var horizontal_distance: float = cos(camera_pitch) * camera_distance
	var local_camera_position: Vector3 = Vector3(
		sin(camera_yaw) * horizontal_distance,
		camera_base_height + sin(camera_pitch) * camera_distance,
		cos(camera_yaw) * horizontal_distance
	)
	chase_camera.position = local_camera_position
	chase_camera.look_at(look_target.global_position, Vector3.UP)
