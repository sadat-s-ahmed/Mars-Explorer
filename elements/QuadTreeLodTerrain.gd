tool
extends Spatial

class QuadRegion:
	var depth : int
	var parent : QuadRegion
	var region : Rect2
	
func _process(delta):
	var dir = $Camera/RayCast.cast_to.normalized()
	var camera_matrix = $Camera.get_camera_transform()
	dir = camera_matrix.xform(dir)
	print(dir)
	for i in range(4):
		var meshNode = MeshInstance.new()
		var mesh = PlaneMesh.new()
		mesh.size = Vector2(i+1, i+1)
		meshNode.mesh = mesh
		dir.y = 0
		dir = dir.normalized()
		meshNode.translate((i+1)/2.0*(i) * dir)
		add_child(meshNode)
	pass