extends Spatial

onready var viewport = $HUD
onready var HUD_area = $Camera/Area

var prev_pos = null
var last_click_pos = null

func _input(event):
	var is_mouse_event = false
	var mouse_events =  [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]
	for mouse_event in mouse_events:
		if event is mouse_event:
			is_mouse_event = true
			break
			
	if not is_mouse_event:
		viewport.input(event)

func _on_Area_input_event(camera, event, click_position, click_normal, shape_idx):
	var raw_pos = HUD_area.to_local(click_position)
	var pos = raw_pos.project(Vector3.LEFT)
	pos.y = raw_pos.project(Vector3.FORWARD).z
#	pos += (click_normal*Vector3(2.0, 2.0, 2.0)-Vector3(1.0, 1.0, 1.0)).normalized()
	if click_position.x != 0 or click_position.y != 0 or click_position.z != 0:
		last_click_pos = click_position
	else:
		pos *= last_click_pos
		if event is InputEventMouseMotion or event is InputEventScreenDrag:
#			pos.x += event.relative.x / viewport.size.x
#			pos.z += event.relative.y / viewport.size.y
			last_click_pos = pos

	pos = Vector2(pos.x, pos.y)
#	pos.y *= -1
	pos += Vector2(1, 1)
	pos = pos / 2
	
	pos.x *= viewport.size.x
	pos.y *= viewport.size.y
	
	event.position = pos
	event.global_position = pos
	if not prev_pos:
		prev_pos = pos
	if event is InputEventMouseMotion:
		event.relative = pos - prev_pos
	prev_pos = pos
	
	viewport.input(event)
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	set_process_input(true)