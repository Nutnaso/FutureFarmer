extends Node3D

@onready var camera := $CameraPosition/Camera3D
@onready var animeton := $AnimationPlayer


@onready var option_button := $Menu/FarmMenu/OptionButton
@onready var plant_pod := $"Map/Floor/Root Scene"
@onready var score_label := $"Menu/Score"
@onready var time_label := $"Menu/Time"

@onready var escape := $"Menu/Escape"
# Farm menu
@onready var farm_menu := $"Menu/FarmMenu"
@onready var current_seed := $"Menu/CurrentSeed"
@onready var Harvested  := $"Menu/Harvested"

# Shop menu
@onready var shop_menu := $"Menu/ShopMenu"
@onready var shop_option_button := $"Menu/ShopMenu/ShopOptionButton"
@onready var buy_button := $"Menu/ShopMenu/BuyButton"

# Station menu
@onready var station_menu := $"Menu/StationMenu"
@onready var quest_label := $"Menu/StationMenu/QuestLabel"


# event
@onready var intro_sceen := $"Menu/IntroBlacksceen" 

@onready var jet := $"Jet"
@onready var jet_sound := $"SFX/Jet"

@onready var monster := $"kaijyu"
@onready var monster_sound := $"SFX/Kaiju"


@onready var slow_clock := $"SFX/SlowClock"
@onready var fast_clock := $SFX/FastClock




# preload plants
var banana := preload("res://Joor/banana.tscn")
var asparagus := preload("res://Joor/asparagus.tscn")
var aubergine := preload("res://Joor/aubergine.tscn")
var avocado := preload("res://Joor/avocado.tscn")
var beetroot := preload("res://Joor/beetroot.tscn")
var cabbage := preload("res://Joor/cabbage.tscn")
var corn := preload("res://Joor/corn.tscn")
var mango := preload("res://Joor/mango.tscn")

# preload NPC
var NPC1 := preload("res://Jamie/back_2.tscn")
var NPC2 := preload("res://Jamie/back_3.tscn")
var NPC3 := preload("res://Jamie/farmer.tscn")
var NPC4 := preload("res://Jamie/lazyboy.tscn")
var NPC5 := preload("res://Jamie/richman.tscn")



# preload Voice

@onready var intro_300 := $"Voice/Intro300"
@onready var news_265 := $"Voice/News265"
@onready var news_254 := $"Voice/News254"
@onready var news_200 := $"Voice/News200"
@onready var news_180 := $"Voice/News180"
@onready var news_160 := $"Voice/News160"
@onready var end_game_120 := $"Voice/Endgame120"
@onready var end_game_60 := $"Voice/Endgame60"


# ---------------- Plant / Farm ----------------
var current_tween: Tween = null
var selected_plant_scene: PackedScene = null
var current_plant: Node3D = null
var grow_count: int = 0
var selected_plant_name: String = ""
var is_growing: bool = false
var is_harvesting: bool = false

var plant_dict := {
	"Banana": banana,
	"Asparagus": asparagus,
	"Aubergine": aubergine,
	"Avocado": avocado,
	"Beetroot": beetroot,
	"Cabbage": cabbage,
	"Corn": corn,
	"Mango": mango
}

var seed_inventory := {
	"Banana": 3,
	"Asparagus": 3,
	"Aubergine": 3,
	"Avocado": 3,
	"Beetroot": 3,
	"Cabbage": 3,
	"Corn": 3,
	"Mango": 3
}

var harvested_dict := {}
var score: int = 50
# ---------------- Voice Event -----------------


var played_voices := []  # เก็บรายการเสียงที่เล่นแล้ว



# ---------------- Time -----------------
var time_left: float = 300.0# ใช้ float จะได้คำนวณ delta ถูกต้อง
var timer_running: bool = true

# ---------------- NPC -----------------
var npc_scenes := [NPC1, NPC2, NPC3, NPC4, NPC5]
var available_npcs := []
var current_npc: Node3D = null
var npc_timer: float = 0.0
var npc_interval: float = 10.0 # เปลี่ยน NPC ทุก 10 วินาที

var voice_schedule = {}
var camera_origin: Vector3
# ---------------- Ready -----------------
func _ready() -> void:
	var camera_origin = camera.position
	print(camera_origin)
	# Farm option button
	for name in plant_dict.keys():
		option_button.add_item(name)
	# Shop option button
	for name in plant_dict.keys():
		shop_option_button.add_item(name)
	_refresh_option_buttons()
	_update_labels()
	
	# NPC
	available_npcs = npc_scenes.duplicate()

	# 🎬 เริ่มเกมทันที (แทนกดปุ่ม Start)
	voice_schedule = {
		300: intro_300,
		255: news_265,
		244: news_254,
		198: news_200,
		191: news_180,
		174: news_160,
		120: end_game_120,
		60: end_game_60,
	}
	
	_start_game()
	


func _start_game() -> void:
	# Intro
	intro_sceen.visible = true
	
	var fade_tween = create_tween()
	fade_tween.tween_property(intro_sceen, "modulate:a", 0.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_tween.finished

	intro_sceen.visible = false
	farm_menu.visible = true
	shop_menu.visible = false
	station_menu.visible = false

	timer_running = true

	_spawn_random_npc()
	_start_monster()
# Clock sound
var clock_timer: float = 0.0
var clock_interval: float = 1.0  # ทุก 1 วินาที


# ---------------- Process -----------------
func _process(delta: float) -> void:
	
	if shake_timer > 0:
		shake_timer -= delta
		camera.position = Vector3(0.0, 0.585548, 0.0) + Vector3(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
	else:
		camera.position = Vector3(0.0, 0.585548, 0.0)
	# เวลาเกม
	if timer_running and time_left > 0:
		time_left -= delta
		if time_left < 0:
			time_left = 0
			timer_running = false
			print("⏰ เวลาเกมหมด!")

			animeton.play("Endgame")
			await animeton.animation_finished  # ✅ รอจน Animation เล่นจบ
			_game_over("YOU DIE")

			
		_update_time_label()
		_check_voice_triggers()
		
		# Jet Event
		if time_left <= jet_start_time:
			jet_timer += delta
			if jet_timer >= jet_interval:
				jet_timer = 0
				_trigger_jet()
				_shake_camera(8, 0.1)
	# ---------------- Clock Event -----------------
		clock_timer += delta
		if clock_timer >= clock_interval:
			clock_timer = 0
			# ช่วง 5 - 3 นาที
			if time_left <= 300 and time_left > 180:
				if slow_clock:
					slow_clock.play()
			# ช่วงน้อยกว่า 3 นาที
			elif time_left <= 180:
				if fast_clock:
					fast_clock.play()
					
					
	# ---------------- Monster Event -----------------
# ---------------- Monster Event -----------------
	if monster_active:
		monster_timer += delta

		var trigger_times = [270, 210, 150, 90, 30]  # วินาทีที่เหลือ (4:30, 3:30, 2:30, 1:30, 0:30)

		for trigger_time in trigger_times:
			if time_left <= trigger_time and time_left > trigger_time - 0.2 and not played_voices.has(trigger_time):
				print("🐲 Monster roar at:", trigger_time)
				if monster_sound:
					monster_sound.play()
					_shake_camera(4, 0.15)
					played_voices.append(trigger_time)
				else:
					print("❌ Monster sound node is NULL")

# ---------------- Voice Trigger -----------------
	#if time_left >= 259+.01 and time_left <= 300+0.1 :
		#intro_300.play()

	
	# Escape event
	if time_left <= 60 and not escape.visible:
		escape.visible = true
	
	# NPC
	npc_timer += delta
	if npc_timer >= npc_interval:
		npc_timer = 0
		_spawn_random_npc()

var previous_time_left: float = 300.0

func _check_voice_triggers():
	for trigger_time in voice_schedule.keys():
		var voice_node = voice_schedule[trigger_time]
		if voice_node and not played_voices.has(trigger_time):
			if time_left >= trigger_time - 0.5 and time_left < trigger_time:
				print("🎤 Playing voice for time:", trigger_time)
				voice_node.play()
				played_voices.append(trigger_time)
				
				
# ---------------- Update Labels -----------------
func _update_labels() -> void:
	# เรียงตามชื่อพืชทั้งหมด
	var all_names := plant_dict.keys()
	all_names.sort()

	# Seeds
	var seed_text := "Seeds:\n"
	for key in all_names:
		if seed_inventory.has(key):
			seed_text += "%s: %d\n" % [key, seed_inventory[key]]
	current_seed.text = seed_text.strip_edges()

	# Harvested (เฉพาะที่มีแล้ว)
	var harvested_text := "Harvested:\n"
	for key in all_names:
		if harvested_dict.has(key) and harvested_dict[key] > 0:
			harvested_text += "%s: %d\n" % [key, harvested_dict[key]]
	Harvested.text = harvested_text.strip_edges()

	# Score
	score_label.text = "Money: %d" % score



# ---------------- Update Time Label -----------------
func _update_time_label() -> void:
	var total_seconds = int(floor(time_left))
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	var milliseconds = int((time_left - total_seconds) * 100)

	time_label.text = "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

	if time_left > 180:
		time_label.modulate = Color.GREEN
	elif time_left > 120:
		time_label.modulate = Color(1, 0.5, 0)
	elif time_left > 60:
		time_label.modulate = Color.RED
	else:
		time_label.modulate = Color(0.8, 0, 0)

# ---------------- Camera -----------------
func _rotate_camera(target_rotation: Vector3) -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(camera, "rotation_degrees", target_rotation, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_farm_pressed() -> void:
	_rotate_camera(Vector3(0, -178, 0))
	farm_menu.visible = true
	shop_menu.visible = false
	station_menu.visible = false
	$Menu/RealEscape.visible = false
	
func _on_shop_pressed() -> void:
	_rotate_camera(Vector3(0, -90, 0))
	farm_menu.visible = false
	shop_menu.visible = true
	station_menu.visible = false
	$Menu/RealEscape.visible = false
	
func _on_station_pressed() -> void:
	_rotate_camera(Vector3(0, -268, 0))
	_update_sell_button_state()
	_update_quest_label()
	farm_menu.visible = false
	shop_menu.visible = false
	station_menu.visible = true
	$Menu/RealEscape.visible = false
	
func _on_escape_pressed() -> void:
	$Menu/RealEscape.visible = true
	farm_menu.visible = false
	shop_menu.visible = false
	station_menu.visible = false
	_rotate_camera(Vector3(0, 0, 0))

# ---------------- Plant Selection -----------------
func _on_option_button_item_selected(index: int) -> void:
	var plant_name = option_button.get_item_text(index)

	if plant_name == "select your plants":
		selected_plant_scene = null
		selected_plant_name = ""
		if current_plant and current_plant.is_inside_tree():
			current_plant.queue_free()
		_update_labels()
		return

	if is_growing:
		print("⚠️ กำลังปลูกอยู่ เลือกพืชใหม่ไม่ได้")
		return
	
	if plant_dict.has(plant_name):
		if seed_inventory[plant_name] <= 0:
			print("❌ ไม่มีเมล็ด %s แล้ว" % plant_name)
			return

		selected_plant_scene = plant_dict[plant_name]
		selected_plant_name = plant_name
		print("เลือก:", plant_name)

		if current_plant and current_plant.is_inside_tree():
			current_plant.queue_free()
		
		current_plant = selected_plant_scene.instantiate()
		plant_pod.add_child(current_plant)
		current_plant.transform.origin = Vector3(0, 0, 0)
		current_plant.scale = Vector3(1, 1, 1)
		grow_count = 0
	
	_update_labels()


# ---------------- Grow Plant -----------------
func _on_grow_plant_pressed() -> void:
	if not current_plant or is_harvesting:
		return

	grow_count += 1

	if not is_growing:
		is_growing = true
		option_button.disabled = true
		seed_inventory[selected_plant_name] -= 1
		if seed_inventory[selected_plant_name] <= 0:
			for i in range(option_button.item_count):
				if option_button.get_item_text(i) == selected_plant_name:
					option_button.remove_item(i)
					break
	_update_labels()

	var new_scale = current_plant.scale * 2
	var tween = create_tween()
	tween.tween_property(current_plant, "scale", new_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if grow_count >= 5 and current_plant:
		is_harvesting = true
		var fade_tween = create_tween()
		fade_tween.tween_property(current_plant, "scale", Vector3.ZERO, 0.1)
		await fade_tween.finished
		
		if current_plant and current_plant.is_inside_tree():
			current_plant.queue_free()
			current_plant = null

			if not harvested_dict.has(selected_plant_name):
				harvested_dict[selected_plant_name] = 0
			harvested_dict[selected_plant_name] += 1

			grow_count = 0
			is_growing = false
			is_harvesting = false
			option_button.disabled = false

			if seed_inventory[selected_plant_name] > 0:
				current_plant = plant_dict[selected_plant_name].instantiate()
				plant_pod.add_child(current_plant)
				current_plant.transform.origin = Vector3(0, 0, 0)
				current_plant.scale = Vector3(1, 1, 1)
			else:
				# เมล็ดหมด -> reset เป็น select your plants
		
				selected_plant_scene = null
				selected_plant_name = ""
				option_button.select(0) # เลือก select your plants
		


	_update_labels()

# ---------------- Shop -----------------
var shop_selected_plant: String = ""

func _on_shop_option_button_item_selected(index: int) -> void:
	shop_selected_plant = shop_option_button.get_item_text(index)
	print("🛒 เลือกพืชจากร้าน:", shop_selected_plant)
	_update_buy_button_state()


func _on_buy_button_pressed() -> void:
	if shop_selected_plant == "" or shop_selected_plant == "select plant to buy":
		print("⚠️ ยังไม่ได้เลือกพืช")
		return
	if score < 5:
		print("❌ เงินไม่พอ")
		return
	
	score -= 5
	seed_inventory[shop_selected_plant] += 1
	print("✅ ซื้อ %s +1 เมล็ด (เหลือเงิน %d)" % [shop_selected_plant, score])

	# รีเฟรชเฉพาะฟาร์ม ไม่แตะร้านค้า
	_refresh_farm_option_button()
	_update_labels()

	# --- คงค่าเลือกปัจจุบันของร้านค้า ---
	for i in range(shop_option_button.item_count):
		if shop_option_button.get_item_text(i) == shop_selected_plant:
			shop_option_button.select(i)
			break

	_update_buy_button_state()


func _refresh_farm_option_button() -> void:
	var farm_plants := []
	for name in seed_inventory.keys():
		if seed_inventory[name] > 0:
			farm_plants.append(name)
	farm_plants.sort()
	
	option_button.clear()
	option_button.add_item("select your plants")
	for name in farm_plants:
		option_button.add_item(name)

func _refresh_option_buttons() -> void:
	_refresh_farm_option_button()
	
	# --- Shop menu ---
	var shop_plants := plant_dict.keys()
	shop_plants.sort()
	shop_option_button.clear()
	shop_option_button.add_item("select plant to buy")
	for name in shop_plants:
		shop_option_button.add_item(name)

	# reset ตอนเข้าเกม
	shop_option_button.select(0)
	shop_selected_plant = ""
	_update_buy_button_state()


# ---------------- Quest / Sell -----------------
var current_quest := {} # {"Banana": 2, "Corn": 1}
@onready var sell_button := $"Menu/StationMenu/SellButton"

# ---------------- Spawn NPC -----------------
func _spawn_random_npc() -> void:
	# ลบ NPC เก่า
	if current_npc and current_npc.is_inside_tree():
		current_npc.queue_free()
		current_npc = null

	if available_npcs.size() == 0:
		available_npcs = npc_scenes.duplicate()

	var index = randi() % available_npcs.size()
	var npc_scene = available_npcs[index]
	current_npc = npc_scene.instantiate()
	current_npc.transform.origin = Vector3(-2, 0, 0)
	current_npc.rotate_y(deg_to_rad(90))
	add_child(current_npc)
	available_npcs.remove_at(index)

	# สุ่ม Quest ใหม่
	_generate_random_quest()

	# ตั้งเวลา NPC รอบถัดไป = จำนวนพืชที่ต้องการ * 5
	var total_items = 0
	for amount in current_quest.values():
		total_items += amount
	npc_interval = total_items * 10
	npc_timer = 0 # รีเซ็ต timer เพื่อเริ่มนับใหม่

# ---------------- Generate Quest -----------------
func _generate_random_quest() -> void:
	current_quest.clear()
	
	var num_items = randi_range(2, 4) # 2-4 ชนิด
	var plant_names = plant_dict.keys()
	plant_names.shuffle()

	for i in range(num_items):
		var plant_name = plant_names[i]
		current_quest[plant_name] = randi_range(1, 2)

	_update_quest_label()
	_update_sell_button_state()

# ---------------- Update Quest Label -----------------
func _update_quest_label() -> void:
	var text = "[b]I Want :[/b]\n"
	for plant_name in current_quest.keys():
		var amount = current_quest[plant_name]
		
		# เช็คว่ามีพืชพอไหม
		var have = 0
		if harvested_dict.has(plant_name):
			have = harvested_dict[plant_name]
		
		if have >= amount:
			# พอ → เขียว
			text += "[color=green]%s: %d (มี %d)[/color]\n" % [plant_name, amount, have]
		else:
			# ไม่พอ → แดง
			text += "[color=red]%s: %d (มี %d)[/color]\n" % [plant_name, amount, have]
	
	quest_label.bbcode_enabled = true  # เปิดใช้ BBCode
	quest_label.text = text.strip_edges()


# ---------------- Update Sell Button -----------------
func _update_sell_button_state() -> void:
	var can_sell = true
	for plant_name in current_quest.keys():
		if not harvested_dict.has(plant_name) or harvested_dict[plant_name] < current_quest[plant_name]:
			can_sell = false
			break
	
	sell_button.disabled = not can_sell
	sell_button.modulate = Color(1,1,1) if can_sell else Color(1,1,1,0.3)

# ---------------- Update Buy Button -----------------
func _update_buy_button_state() -> void:
	if shop_selected_plant == "":
		buy_button.disabled = true
		buy_button.modulate = Color(1,1,1,0.3)
	elif score >= 5:
		buy_button.disabled = false
		buy_button.modulate = Color(0,1,0) # สีเขียว
	else:
		buy_button.disabled = true
		buy_button.modulate = Color(0,1,0,0.3) # สีเขียวจาง

# ---------------- Sell -----------------
func _on_sell_button_pressed() -> void:
	var total = 0
	for plant_name in current_quest.keys():
		var amount = current_quest[plant_name]
		if harvested_dict.has(plant_name):
			var available = harvested_dict[plant_name]
			var to_sell = min(amount, available)
			harvested_dict[plant_name] -= to_sell
			if harvested_dict[plant_name] <= 0:
				harvested_dict.erase(plant_name)
			total += to_sell * 10 # กำหนดราคา 10 ต่อหน่วย
	
	score += total
	_update_labels() # อัปเดต Harvested / Score

	# spawn NPC ใหม่ทันทีหลังขายเสร็จ (สร้าง quest ใหม่ด้วย)
	_spawn_random_npc()

	# อัปเดตปุ่มขายหลัง spawn quest ใหม่
	_update_sell_button_state()
	_update_quest_label()
# ---------------- Jet Event -----------------
var jet_timer: float = 0.0
var jet_interval: float = 60 # ทุก 30 วินาที
var jet_start_time: float = 300 # 4:30 นาที (270 วินาที)
var jet_active: bool = false

# ---------------- Trigger Jet -----------------
# ---------------- Trigger Jet -----------------
func _trigger_jet() -> void:
	if not jet:
		return
	
	# กำหนดตำแหน่งเริ่มต้น
	jet.position = Vector3(1.168, 8.39, -20.212)
	jet.visible = true
	
	# เล่นเสียง
	if jet_sound:
		jet_sound.play()
	
	# tween เคลื่อน Jet ไปยังจุดหมาย
	var tween = create_tween()
	tween.tween_property(jet, "position", Vector3(1.168, 8.39, 72.522), 5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)



	
# ---------------- Monster Event -----------------
var monster_start_pos := Vector3(-0.035, 6.03, 180.98)
var monster_end_pos   := Vector3(-0.035, 6.03, 29.086)
var monster_duration: float = 240.0 # 4 นาที
var monster_timer: float = 0.0
var monster_sound_interval: float = 30.0 # <<< ครึ่งนาที
var monster_sound_timer: float = 0.0
var monster_active: bool = false



func _start_monster() -> void:
	monster.visible = true
	if not monster:
		return
	
	monster.position = monster_start_pos
	monster.visible = true
	monster_active = true
	monster_timer = 0.0
	monster_sound_timer = 0.0
	
	# Tween เคลื่อนที่ 4 นาที
	var tween = create_tween()
	tween.tween_property(monster, "position", monster_end_pos, monster_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

func _game_over(state: String) -> void:
	# โหลด scene Endgame
	var end_scene = preload("res://end_game.tscn").instantiate()
	
	# ส่งค่าไป Endgame
	end_scene.set_data(state, harvested_dict, score)
	
	get_tree().root.add_child(end_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = end_scene

func _on_real_escape_pressed() -> void:
	_game_over("YOU SURVIVE")


var shake_amount := 0.0
var shake_timer := 0.0

func _shake_camera(duration: float = 0.5, intensity: float = 0.1) -> void:
	shake_amount = intensity
	shake_timer = duration
