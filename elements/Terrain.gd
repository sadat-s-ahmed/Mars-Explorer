tool
extends StaticBody

export (int) var view_distance = 12 setget set_view_distance
func set_view_distance(val):
	_clear()
	view_distance = val
	_initialize()
	
#export (int) var terrain_scale = 1 setget set_scale
#func set_scale(val):
#	_clear()
#	terrain_scale = val
#	_initialize()
	
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
#var tangents : PoolRealArray
#var bitangent : PoolVector3Array
var indices : PoolIntArray

var is_initialized = false

func _generate_vertices():
	vertices = PoolVector3Array()
	heights = PoolRealArray()
	var temp_heights = []
	
	var centre_offset = view_distance / 2
	for x in range(view_distance+1):
		temp_heights.append([])
		for y in range(view_distance+1):
			var h = noise.get_noise_2d(x, y)
			var intensity = abs(h)
			var is_neg = sign(h)
			h *= is_neg
#			if intensity > 0.75:
#				h = sqrt(h)
#			elif intensity < 0.25:
#				h *= h
			h *= h
			h *= is_neg
			h *= height
#			h = clamp(h, -height/4.0, height)
			temp_heights[x].append(h)
			vertices.append(Vector3(x-centre_offset,h,y-centre_offset))
	
	
	# Need to transpose the heightmap values for working correctly in godot
	for x in range(view_distance+1):
		for y in range(view_distance+1):
			heights.append(temp_heights[y][x])

func _generate_UVs():
	UVs = PoolVector2Array()
	var offset = 1.0 / (view_distance)
	for x in range(view_distance+1):
		for y in range(view_distance+1):
			UVs.append(Vector2(offset*x, offset*y))
			
func _generate_indices():
	indices = PoolIntArray()
	for index in range((view_distance+1)*view_distance):
		indices.append(index)
		indices.append(index+(view_distance+1))
		if index != 0 and (index+1) % (view_distance+1) == 0:
			indices.append(index+(view_distance+1))
			indices.append(index+1)

#func _define_tangent(ind, val):
#	tangents[ind] = val.x
#	tangents[ind+1] = val.y
#	tangents[ind+2] = val.z
#	tangents[ind+3] = 1
	
func _generate_normals():
	normals = PoolVector3Array()
	normals.resize(vertices.size())
#	tangents = PoolRealArray()
#	tangents.resize(vertices.size()*4)
	for f in range(normals.size()):
		normals[f] = Vector3(0,1,0)
		
#func _get_tangent(ind):
#	return Vector3(tangents[ind], tangents[ind+1], tangents[ind+2])
	
	for i in range(0, indices.size()-2, 2):
		var ia = indices[i]
		var ib = indices[i+1]
		var ic = indices[i+2]
		
		if ia==ib or ib==ic or ia==ic:
			continue
		
		var a :Vector3 = vertices[ia]
		var	b :Vector3 = vertices[ib]
		var	c :Vector3 = vertices[ic]
		
		var tangent = c-a
		var bitangent = b-a
		var normal_a = tangent.cross(bitangent)
		
		normals[ia] +=  normal_a
		normals[ib] +=  normal_a
		normals[ic] +=  normal_a
#		_define_tangent(i, Vector3(1, 0, 0))
	_normalize_normals()
	
func _normalize_normals():
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
#		_define_tangent(i, _get_tangent(i).normalized())
				

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
#	data[ArrayMesh.ARRAY_TANGENT] = tangents
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, data)
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
#	collision_node.scale = Vector3(terrain_scale, 1, terrain_scale)
	collision_node.shape = hmShape
#	var centre_offset = view_distance / 2.0
#	collision_node.translate(Vector3(-centre_offset, 0, -centre_offset))
			
	is_initialized = true

func _clear():
	for child in get_children():
		child.queue_free()
	is_initialized = false
	
func _ready():
	_initialize()
	set_physics_process(true)
