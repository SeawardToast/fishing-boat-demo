extends RigidBody

func _physics_process(delta):
	if global_transform.origin.y <= 0:
		add_central_force(Vector3.UP*-global_transform.origin.y*rand_range(10,20))

func _ready():
	add_central_force(Vector3(rand_range(-200,200),rand_range(-200,200),rand_range(-200,200)))
	add_torque(Vector3(rand_range(-200,200),rand_range(-200,200),rand_range(-200,200)))
