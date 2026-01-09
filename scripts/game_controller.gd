extends Node2D

@export var map_scene_packed: PackedScene
@export var battle_scene_packed: PackedScene

var map_instance: Node2D
var current_battle_instance: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_map()

func load_map() -> void:
	if map_instance == null:
		map_instance = map_scene_packed.instantiate()
		add_child(map_instance)
		map_instance.encounter_started.connect(_on_map_encounter_started)
		
	map_instance.visible = true
	map_instance.process_mode = Node.PROCESS_MODE_INHERIT

func _on_map_encounter_started(encounter_id: String, node_index: int) -> void:
	print("Controller: Map requested encounter ", encounter_id)
	
	GameData.encounter_type = encounter_id
	GameData.combat_node = node_index
	
	map_instance.visible = false
	map_instance.process_mode = Node.PROCESS_MODE_DISABLED
	
	start_battle()

func start_battle():
	current_battle_instance = battle_scene_packed.instantiate()
	add_child(current_battle_instance)
	
	if current_battle_instance.has_signal("battle_completed"):
		current_battle_instance.battle_completed.connect(_on_battle_completed)
	else:
		var manager =current_battle_instance.find_child("Battle_Board", true, false)
		if manager and manager.has_signal("battle_completed"):
			manager.battle_completed.connect(_on_battle_completed)
		else:
			push_error("Could not find BattleManager signal! Is the script attached?")

func _on_battle_completed(victory: bool):
	print("Controller: Battle finished: Victory: ", victory)
	current_battle_instance.queue_free()
	current_battle_instance = null
	
	map_instance.visible = true
	map_instance.process_mode = Node.PROCESS_MODE_INHERIT
	
	if victory:
		map_instance.mark_available_nodes(map_instance.current_node)
		map_instance.queue_redraw()
	else:
		print("end")
