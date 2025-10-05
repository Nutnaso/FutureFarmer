extends Node3D

func _ready() -> void:
	var menu_music = $menu
	if menu_music and menu_music.stream:
		menu_music.stream.loop = true   # ✅ ตั้งให้ loop
		menu_music.play()               # ✅ สั่งเล่น
	else:
		print("⚠️ Menu music node or stream not found!")

func _on_button_pressed() -> void:
	var new_scene = preload("res://Main.tscn")  # โหลด scene เป็น PackedScene
	get_tree().change_scene_to_packed(new_scene)
