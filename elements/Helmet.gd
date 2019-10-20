extends MeshInstance

export (Material) var glass_mat;
export (Material) var helm_mat;

onready var glass = $Glass;
onready var body = $Body;

func _ready():
	if glass_mat != null:
		glass.material_override = glass_mat;
		
	if body != null:
		body.material_override = helm_mat;