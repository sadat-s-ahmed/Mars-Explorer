extends Spatial

onready var gate = $GateFrame/Gate

onready var anim = $AnimationPlayer

func _ready():
	pass


func _on_ActivationArea_body_entered(body):
	anim.play("gate_open")

func _on_ActivationArea_body_exited(body):
	anim.play("gate_close")