tool
extends StaticBody

export (int) var view_distance = 12 setget set_view_distance
func set_view_distance(val):
	_clear()
	view_distance = val
	_initialize()
	
export (int, 1, 4) var terrain_lod = 1 setget set_terrain_lod
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
	_clear()
	seed_val = val
	_initialize()
	
export (int) var octaves = 2 setget set_octaves
func set_octaves(val):
	_clear()
	octaves = val
	_initialize()
	
export (float) var period = 20.0 setget set_period
func set_period(val):
	_clear()
	period = val
	_initialize()
	
export (float) var lacunarity = 2 setget set_lacunarity
func set_lacunarity(val):
	_clear()
	lacunarity = val
	_initialize()
	
export (float) var persistence = 0.5 setget set_persistence
func set_persistence(val):
	_clear()
	persistence = val
	_initialize()

export (Material) var terrain_material = SpatialMaterial.new() setget set_terrain_material
func set_terrain_material(val):
	terrain_material = val
	if terrain_node == null:
		return
	terrain_node.material_override = terrain_material

var terrain_node : MeshInstance = null
var collision_node : CollisionShape = null
var noise : OpenSimplexNoise = null

var heights : PoolRealArray
var vertices : PoolVector3Array
var UVs : PoolVector2Array
var normals : PoolVector3Array
var tangents : PoolRealArray
var indices : PoolIntArray

var is_initialized = false

func get_height(pos):
	var h = noise.get_noise_2d(pos.x/terrain_lod, pos.y/terrain_lod) * 0.5 + 0.5
	h = smoothstep(sqrt(abs(h)), h*h, h)
	h = h * 2.0 - 1.0
	h *= height
	return h

func _generate_vertices():
	vertices = PoolVector3Array()
	heights = PoolRealArray()
	var centre_offset = view_distance / 2.0
	for y in range(0, view_distance+1):
		for x in range(0, view_distance+1):
			var pos = Vector3((x*terrain_lod)-centre_offset, 0, (y*terrain_lod)-centre_offset)
			var h = get_height(Vector2(pos.x, pos.z))
			pos.y = h
			heights.append(h)
			vertices.append(pos)

func _generate_UVs():
	UVs = PoolVector2Array()
	var offset = 1.0 / (view_distance)
	for y in range(view_distance+1):
		for x in range(view_distance+1):
			UVs.append(Vector2(offset*x, offset*y))
			
func add_quad(y):
	var limit = pow(view_distance+1, 2)
	var step = y;
	while (step < limit):
		indices.append(step)
		indices.append(step+1)
		step += view_distance+1
	return step-(view_distance)

func add_degenerate(last_val, y):
	indices.append(last_val)
	indices.append(y)

func _generate_indices():
	indices = PoolIntArray()
	for y in range(view_distance):
		var last_val = add_quad(y)
		if y != (view_distance-1):
			add_degenerate(last_val, y+1)
#	print(indices)


func _define_tangent(ind, val, basis=1, do_add=true):
	if do_add:
		tangents[ind] += val.x
		tangents[ind+1] += val.y
		tangents[ind+2] += val.z
	else:
		tangents[ind] = val.x
		tangents[ind+1] = val.y
		tangents[ind+2] = val.z
	tangents[ind+3] = basis
	
func _get_tangent(ind):
	return Vector3(tangents[ind], tangents[ind+1], tangents[ind+2])
	
func _generate_normals():
	normals = PoolVector3Array()
	normals.resize(vertices.size())
	tangents = PoolRealArray()
	tangents.resize(vertices.size()*4)
	for f in range(normals.size()):
		normals[f] = Vector3(0,1,0)
		_define_tangent(f, Vector3(1,0,0), 1, false)
	
	for i in range(indices.size()-2):
		var vert_a = vertices[indices[i]]
		var vert_b = vertices[indices[i+1]]
		var vert_c = vertices[indices[i+2]]
	
		var tangent_a = vert_c - vert_a
		var bitangent_a = vert_b - vert_a
		tangent_a = tangent_a.normalized()
		bitangent_a = bitangent_a.normalized()
		
		normals[indices[i]] += tangent_a.cross(bitangent_a)
		normals[indices[i+1]] += tangent_a.cross(bitangent_a)
		normals[indices[i+2]] += tangent_a.cross(bitangent_a)
	
		_define_tangent(indices[i], bitangent_a)
		_define_tangent(indices[i+1], bitangent_a)
		_define_tangent(indices[i+2], bitangent_a)
	
#		print (indices[i], indices[i+1], indices[i+2])
	
	_normalize_normals()
	
func _normalize_normals():
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
		_define_tangent(i, _get_tangent(i).normalized(), 1, false)
				

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
	return mesh
				
func _generate_noise():
	noise = OpenSimplexNoise.new()
	noise.seed = seed_val
	noise.octaves = octaves
	noise.period = period
	noise.lacunarity = lacunarity
	noise.persistence = persistence

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
	terrain_node.mesh = _generate_mesh()
	if terrain_material != null:
		terrain_node.material_override = terrain_material
	if collision_node == null:
		return
		
	var hmShape = HeightMapShape.new()
	hmShape.map_width = view_distance+1
	hmShape.map_depth = view_distance+1
	hmShape.map_data = heights
	collision_node.shape = hmShape
			
	is_initialized = true

func _clear():
	for child in get_children():
		child.queue_free()
	is_initialized = false
	
func _ready():
	_initialize()
	set_physics_process(true)
