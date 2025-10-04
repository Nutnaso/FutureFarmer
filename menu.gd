extends Node3D

func _on_button_pressed() -> void:
	var new_scene = preload("res://main.tscn")  # โหลด scene เป็น PackedScene
	get_tree().change_scene_to_packed(new_scene)
