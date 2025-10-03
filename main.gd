extends Node3D

@onready var camera := $CameraPosition/Camera3D

func _rotate_camera(target_rotation: Vector3) -> void:
	var tween = create_tween()
	# ใช้ rotation_degrees เพื่อกำหนดทิศทางเป้าหมาย
	tween.tween_property(camera, "rotation_degrees", target_rotation, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_farm_pressed() -> void:
	_rotate_camera(Vector3(0, -178, 0))

func _on_shop_pressed() -> void:
	_rotate_camera(Vector3(0, -90, 0))

func _on_station_pressed() -> void:
	_rotate_camera(Vector3(0, 90, 0))
