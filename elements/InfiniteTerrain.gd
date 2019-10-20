tool
extends Spatial

export (int) var view_distance = 12 setget set_view_distance
func set_view_distance(val):
	view_distance = val
	_update_mesh()
	
export (int, 1, 16) var terrain_lod = 1 setget set_terrain_lod
func set_terrain_lod(val):
	terrain_lod = val
	_update_mesh()
	
export (int) var height = 4 setget set_height
func set_height(val):
	height = val
	_update_mesh()
	
export (Material) var terrain_material = SpatialMaterial.new() setget set_terrain_material
func set_terrain_material(val):
	terrain_material = val

export (int) var seed_val = 20 setget set_seed_val
func set_seed_val(val):
	seed_val = val
	_clear_noise()
	
export (int) var octaves = 2 setget set_octaves
func set_octaves(val):
	octaves = val
	_clear_noise()
	
export (float) var period = 20.0 setget set_period
func set_period(val):
	period = val
	_clear_noise()
	
export (float) var lacunarity = 2 setget set_lacunarity
func set_lacunarity(val):
	lacunarity = val
	_clear_noise()
	
export (float) var persistence = 0.5 setget set_persistence
func set_persistence(val):
	persistence = val
	_clear_noise()

var terrain = preload("res://scripts/TerrainChunk.gd")
var curr_instance

var noise : OpenSimplexNoise
var is_initialized : bool = false

func _generate_noise():
	var noise = OpenSimplexNoise.new()
	noise.seed = seed_val
	noise.octaves = octaves
	noise.period = period
	noise.lacunarity = lacunarity
	noise.persistence = persistence
	
	return noise

func _initialize():
	if is_initialized:
		return
		
	noise = _generate_noise()
	curr_instance = terrain.TerrainChunk.new()
	add_child(curr_instance.initialize(noise, terrain_lod, view_distance, height, translation, terrain_material))
	is_initialized = true
	
	
func _clear_noise():
	if noise != null:
		noise = _generate_noise()
		_update_mesh()

func _update_mesh():
	if curr_instance != null and is_initialized:
		remove_child(curr_instance.chunk_node)
		add_child(curr_instance.initialize(noise, terrain_lod, view_distance, height, translation, terrain_material))
		
func _clear():
	is_initialized = false
	_clear_noise()
	_initialize()
	
func _ready():
	set_physics_process(true)
	_initialize()
		