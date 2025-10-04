extends Node3D

func _ready() -> void:
	var anim_player = $"Pivot/Root Scene/AnimationPlayer"
	
	# เล่นแอนิเมชัน
	anim_player.play("HumanArmature|Man_Idle")
	
	# ตั้งให้วนซ้ำตลอด
	anim_player.get_animation("HumanArmature|Man_Idle").loop = true
