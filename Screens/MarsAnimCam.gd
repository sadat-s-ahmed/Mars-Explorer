extends Spatial

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		$AnimationPlayer.play("Camera Pan");
	pass