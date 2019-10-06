tool
extends Spatial

export (Mesh) var mesh_model = SphereMesh.new() setget _set_mesh_model
func _set_mesh_model(val):
	_clear()
	mesh_model = val
	_initialize()
	
export (NodePath) var origin = null setget _set_origin
func _set_origin(val):
	_clear()
	origin = val
	_initialize()
	
export (float) var orbit_radius = 1.0 setget _set_orbit_radius
func _set_orbit_radius(val):
	orbit_radius = val
	initialized = false
	
export (float) var orbiting_speed = PI/16.0 setget _set_orbiting_speed
func _set_orbiting_speed(val):
	orbiting_speed = val
	initialized = false
	
export (Vector3) var orbiting_axis = Vector3.UP setget _set_orbiting_axis
func _set_orbiting_axis(val):
	orbiting_axis = val.normalized()
	if orbiting_axis.length() < 1.0 or orbiting_axis.length() > 1.0:
		orbiting_axis = Vector3.UP
	initialized = false


var initialized = false

var mesh_node = null
var origin_node = null

func _clear():
	return

func _initialize():
	if initialized:
		return true
		
	if mesh_model == null or origin == null:
		return false
	
	mesh_node = $OrbitCentre/Mesh
	origin_node = $OrbitCentre
	if mesh_node == null or origin_node == null:
		return false
		
	var orbit_target = get_node_or_null(origin)
	if orbit_target == null:
		return false
		
	mesh_node.mesh = mesh_model
	if orbit_target.has_method("get_mesh_translation"):
		var val =  orbit_target.get_mesh_translation()
		if val != null:
			origin_node.translation = val
		else:
			origin_node.translation = orbit_target.translation	
	else:
		origin_node.translation = orbit_target.translation	
		
	mesh_node.translation = origin_node.translation + (orbiting_axis * orbit_radius)
	

func get_mesh_translation():
	if not initialized:
		return null
	return mesh_node.translation

func _ready():
	pass
	
func _process(delta):
	if not initialized:
		initialized = _initialize()
		
	rotate(orbiting_axis, orbiting_speed*delta)