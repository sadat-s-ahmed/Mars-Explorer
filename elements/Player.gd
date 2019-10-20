extends KinematicBody

const GRAVITY = -19.0
const MAX_SPEED = 25
const JUMP_SPEED = 25
const ACCELERATION = 4.5

const DECELERATION= 16
const MAX_SLOPE_ANGLE = 35

var MOUSE_SENSITIVITY = 0.05

var velocity = Vector3()
var direction = Vector3()

onready var camera = $RotationHelper/Camera
onready var rotation_helper = $RotationHelper

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	
func process_input(delta):

	# ----------------------------------
	# Walking
	direction = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("ui_up"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("ui_down"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("ui_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_movement_vector.x += 1

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	direction += -cam_xform.basis.z * input_movement_vector.y
	direction += cam_xform.basis.x * input_movement_vector.x
	# ----------------------------------

	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("ui_select"):
			velocity.y = JUMP_SPEED
	# ----------------------------------

	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------

func process_movement(delta):
	direction.y = 0
	direction = direction.normalized()

	if not is_on_floor():
		velocity.y += delta * GRAVITY
		
	var hvel = velocity
	hvel.y = 0

	var target = direction
	target *= MAX_SPEED

	var accel
	if direction.dot(hvel) > 0:
		accel = ACCELERATION
	else:
		accel = DECELERATION

	hvel = hvel.linear_interpolate(target, accel * delta)
	velocity.x = hvel.x
	velocity.z = hvel.z
	velocity = move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot