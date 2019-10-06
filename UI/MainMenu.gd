extends Control

func _process(delta):
	pass

func _input(event):
	if event is InputEventMouseButton:
		$Cursor.rect_position = event.position-$Cursor.rect_size/2.0
	elif event is InputEventMouseMotion:
		$Cursor.rect_position = event.position-$Cursor.rect_size/2.0


func load_scene():
	# Remove the current level
	var level = get_tree().root.get_children()
	for child in level:
		child.queue_free()

	# Add the next level
	var next_level_resource = load("res://Screens/Mars.tscn")
	var next_level = next_level_resource.instance()
	get_tree().root.add_child(next_level)

func _on_Button_pressed():
	load_scene()

func _on_settings_pressed():
	pass # Replace with function body.


func _on_Button3_pressed():
	get_tree().quit()
