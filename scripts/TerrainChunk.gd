class TerrainChunk:
	
	var heights : PoolRealArray
	var vertices : PoolVector3Array
	var UVs : PoolVector2Array
	var normals : PoolVector3Array
	var tangents : PoolRealArray
	var indices : PoolIntArray

	var chunk_node : StaticBody
	var terrain_node : MeshInstance
	var collision_node : CollisionShape
	var noise : OpenSimplexNoise

	var terrain_lod : int
	var view_distance : int
	var height : int
	var parent_pos : Vector3
	var terrain_material : Material
	
	var origin_point
	
	func initialize(noise, terrain_lod, view_distance, height, parent_pos, terrain_material):
		print("Initializing")
		self.noise = noise
		self.terrain_lod = terrain_lod
		self.view_distance = view_distance
		self.height = height
		self.parent_pos = parent_pos
		self.terrain_material = terrain_material
		
		return _generate()
		
		
	func _generate():
		chunk_node = StaticBody.new()
		terrain_node = MeshInstance.new()
		collision_node = CollisionShape.new()
		
		chunk_node.add_child(terrain_node)
		chunk_node.add_child(collision_node)
		
		return _generate_mesh()


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
		origin_point = Vector3(-centre_offset, 0, -centre_offset);
		for y in range(0, view_distance/terrain_lod+1):
			for x in range(0, view_distance/terrain_lod+1):
				var pos = Vector3((x*terrain_lod)-centre_offset, 0, (y*terrain_lod)-centre_offset)
				var h = get_height(Vector2(x, y)+Vector2(parent_pos.x, parent_pos.z))
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
				
				var left = get_height(Vector2(x_o-1, y_o)+Vector2(parent_pos.x, parent_pos.z))
				var up = get_height(Vector2(x_o, y_o-1)+Vector2(parent_pos.x, parent_pos.z))
				
				var origin = get_height(Vector2(x_o, y_o)+Vector2(parent_pos.x, parent_pos.z))
				
				var right = get_height(Vector2(x_o+1, y_o)+Vector2(parent_pos.x, parent_pos.z))
				var down = get_height(Vector2(x_o, y_o+1)+Vector2(parent_pos.x, parent_pos.z))
				
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
		if terrain_material != null:
			terrain_node.material_override = terrain_material
		if collision_node == null:
			return
			
		var hmShape = HeightMapShape.new()
		hmShape.map_width = view_distance+1
		hmShape.map_depth = view_distance+1
		hmShape.map_data = heights
		collision_node.shape = hmShape
		
		return chunk_node

	func update():
		terrain_node = null
		collision_node = null
		chunk_node = null
		
		return _generate()
