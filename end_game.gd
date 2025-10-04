extends Node3D

@onready var end_state: Label = $CanvasLayer/Endstate
@onready var score_state: RichTextLabel = $CanvasLayer/Scorestate

var pending_state: String
var pending_harvested: Dictionary
var pending_score: int
var data_ready: bool = false

func set_data(state: String, harvested: Dictionary, score: int) -> void:
	pending_state = state
	pending_harvested = harvested.duplicate()
	pending_score = score
	data_ready = true
	
	# ถ้า node พร้อมแล้วก็อัปเดตเลย
	if is_inside_tree():
		_update_ui()

func _ready() -> void:
	if data_ready:
		_update_ui()

func _update_ui() -> void:
	if not end_state or not score_state:
		push_error("Endstate หรือ Scorestate หาไม่เจอใน scene")
		return
	
	end_state.text = pending_state
	var result_text = "Money: %d\n" % pending_score
	result_text += "Harvested:\n"
	for plant in pending_harvested.keys():
		if pending_harvested[plant] > 0:
			result_text += "- %s : %d\n" % [plant, pending_harvested[plant]]
	score_state.text = result_text
