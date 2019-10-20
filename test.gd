tool
extends Spatial

var thread = Thread.new()
var mutex = Mutex.new()

var terrain = "res://elements/InfiniteTerrain.tscn"

func _enter_tree():
	_ready()

func _ready():
	if thread.is_active():
		return
	thread.start(self, "_load_terrain", terrain, Thread.PRIORITY_LOW)
	pass
	
func _load_terrain(terrain):
	mutex.lock()
	var terr = load(terrain).instance()
	call_deferred("_loading_complete")
	print("loaded")
	mutex.unlock()
	return terr
	
func _loading_complete():
	var nodes = thread.wait_to_finish()
	add_child(nodes)