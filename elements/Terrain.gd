tool
extends StaticBody

export (int) var terrain_scale = 1 setget set_terrain_scale
func set_terrain_scale(val):
	_clear()
	terrain_scale = val
	_initialize()

export (int) var view_distance = 12 setget set_view_distance
func set_view_distance(val):
	_clear()
	view_distance = val
	_initialize()
	
export (int, 1, 16) var terrain_lod = 1 setget set_terrain_lod
func set_terrain_lod(val):
	_clear()
	terrain_lod = val
	_initialize()
	
export (int) var height = 4 setget set_height
func set_height(val):
	_clear()
	height = val
	_initialize()

export (int) var seed_val = 20 setget set_seed_val
func set_seed_val(val):
	_clear(true)
	seed_val = val
	_initialize()
	
export (int) var octaves = 2 setget set_octaves
func set_octaves(val):
	_clear(true)
	octaves = val
	_initialize()
	
export (float) var period = 20.0 setget set_period
func set_period(val):
	_clear(true)
	period = val
	_initialize()
	
export (float) var lacunarity = 2 setget set_lacunarity
func set_lacunarity(val):
	_clear(true)
	lacunarity = val
	_initialize()
	
export (float) var persistence = 0.5 setget set_persistence
func set_persistence(val):
	_clear(true)
	persistence = val
	_initialize()

export (Material) var terrain_material = SpatialMaterial.new() setget set_terrain_material
func set_terrain_material(val):
	terrain_material = val
	if terrain_node == null:
		return
	terrain_node.material_override = terrain_material


var heights : PoolRealArray
var vertices : PoolVector3Array
var UVs : PoolVector2Array
var normals : PoolVector3Array
var tangents : PoolRealArray
var indices : PoolIntArray

var terrain_node : MeshInstance = null
var collision_node : CollisionShape = null
var noise : OpenSimplexNoise = null

var is_initialized = false
var is_noise_initialized = false

func get_height(pos):
	var h = noise.get_noise_2d(pos.x/terrain_lod, pos.y/terrain_lod) * 0.5 + 0.5
	h = smoothstep(sqrt(abs(h)), h*h, h)
	h = h * 2.0 - 1.0
	h *= height
	return h

func _generate_vertices():
	vertices = PoolVector3Array()
	heights = PoolRealArray()
	var centre_offset = (view_distance/terrain_lod * terrain_lod) / 2.0
	for y in range(0, view_distance/terrain_lod+1):
		for x in range(0, view_distance/terrain_lod+1):
			var pos = Vector3((x*terrain_lod)-centre_offset, 0, (y*terrain_lod)-centre_offset)
			var h = get_height(Vector2(pos.x, pos.z)+Vector2(translation.x, translation.z))
			pos.y = h
			heights.append(h)
			vertices.append(pos)

func _generate_UVs():
	UVs = PoolVector2Array()
	var offset = 1.0 / (view_distance/terrain_lod)
	for y in range(view_distance/terrain_lod+1):
		for x in range(view_distance/terrain_lod+1):
			UVs.append(Vector2(offset*x, offset*y))
			
func add_quad(y):
	var limit = pow(view_distance/terrain_lod+1, 2)
	var step = y;
	while (step < limit):
		indices.append(step)
		indices.append(step+1)
		step += view_distance/terrain_lod+1
	return step-(view_distance/terrain_lod)

func add_degenerate(last_val, y):
	indices.append(last_val)
	indices.append(y)

func _generate_indices():
	indices = PoolIntArray()
	for y in range(view_distance/terrain_lod):
		var last_val = add_quad(y)
		add_degenerate(last_val, y+1)

func _add_tangent(val, basis = 1.0):
	tangents.append(val.x)
	tangents.append(val.y)
	tangents.append(val.z)
	tangents.append(basis)

func _generate_normals():
	normals = PoolVector3Array()
	tangents = PoolRealArray()
	var centre_offset = (view_distance/terrain_lod * terrain_lod) / 2.0
	for y in range(view_distance/terrain_lod+1):
		for x in range(view_distance/terrain_lod+1):
			var x_o = x*terrain_lod-centre_offset;
			var y_o = y*terrain_lod-centre_offset;
			
			var left = get_height(Vector2(x_o-1, y_o)+Vector2(translation.x, translation.z))
			var up = get_height(Vector2(x_o, y_o-1)+Vector2(translation.x, translation.z))
			
			var origin = get_height(Vector2(x_o, y_o)+Vector2(translation.x, translation.z))
			
			var right = get_height(Vector2(x_o+1, y_o)+Vector2(translation.x, translation.z))
			var down = get_height(Vector2(x_o, y_o+1)+Vector2(translation.x, translation.z))
			
			left = Vector3(x_o-1, left, y_o)
			up = Vector3(x_o, up, y_o-1)
			origin = Vector3(x_o, origin, y_o)
			right = Vector3(x_o+1, right, y_o)
			down = Vector3(x_o, down, y_o+1)
			
			var t_o = origin-left
			var b_o = origin-up
			var n_o = b_o.cross(t_o)
			t_o = origin-right
			b_o = origin-down
			n_o += b_o.cross(t_o)
#			print (n_o)
			normals.append(n_o.normalized())
			_add_tangent(t_o.normalized())
	return [normals, tangents]

func _generate_mesh():
	_generate_vertices()
	_generate_UVs()
	_generate_indices()
	_generate_normals()
	var mesh = ArrayMesh.new()
	var data = []
	data.resize(ArrayMesh.ARRAY_MAX)
	data[ArrayMesh.ARRAY_VERTEX] = vertices
	data[ArrayMesh.ARRAY_TEX_UV] = UVs
	data[ArrayMesh.ARRAY_INDEX] = indices
	data[ArrayMesh.ARRAY_NORMAL] = normals
	data[ArrayMesh.ARRAY_TANGENT] = tangents
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, data)
	mesh.regen_normalmaps()
	
	terrain_node.mesh = mesh
	terrain_node.scale_object_local(Vector3(terrain_scale,terrain_scale,terrain_scale))
	if terrain_material != null:
		terrain_node.material_override = terrain_material
	if collision_node == null:
		return
		
	var hmShape = HeightMapShape.new()
	hmShape.map_width = view_distance+1
	hmShape.map_depth = view_distance+1
	hmShape.map_data = heights
	collision_node.shape = hmShape
	collision_node.scale_object_local(Vector3(terrain_scale,terrain_scale,terrain_scale))
	is_initialized = true
	
	
func _generate_noise():
	if is_noise_initialized:
		return
		
	noise = OpenSimplexNoise.new()
	noise.seed = seed_val
	noise.octaves = octaves
	noise.period = period
	noise.lacunarity = lacunarity
	noise.persistence = persistence
	
	is_noise_initialized = true

func _initialize():
	if is_initialized:
		return
	
	terrain_node = MeshInstance.new()
	collision_node = CollisionShape.new()
	
	add_child(terrain_node)
	add_child(collision_node)
	if terrain_node == null or collision_node == null:
		return
		
	_generate_noise()
	
	_generate_mesh()
	
	
func _clear(should_update_noise=false):
	for child in get_children():
		child.queue_free()
	is_initialized = false
	if should_update_noise:
		is_noise_initialized = false
	
func _ready():
	_initialize()
	set_physics_process(true)
