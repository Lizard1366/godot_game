extends Node2D

@export var map_scene_packed: PackedScene
@export var battle_scene_packed: PackedScene

var map_instance: Node2D
var current_battle_instance: Node = null
var battle_ui_layer: CanvasLayer = null

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
	battle_ui_layer = CanvasLayer.new()
	battle_ui_layer.layer = 10
	add_child(battle_ui_layer)
	
	current_battle_instance = battle_scene_packed.instantiate()
	battle_ui_layer.add_child(current_battle_instance)
	
	if current_battle_instance is Control:
		current_battle_instance.set_anchors_preset(Control.PRESET_CENTER)
		current_battle_instance.grow_horizontal = Control.GROW_DIRECTION_BOTH
		current_battle_instance.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	if current_battle_instance.has_signal("battle_completed"):
		current_battle_instance.battle_completed.connect(_on_battle_completed)
	else:
		var manager =current_battle_instance.find_child("BattleManager", true, false)
		if manager and manager.has_signal("battle_completed"):
			manager.battle_completed.connect(_on_battle_completed)
		else:
			push_error("Could not find BattleManager signal! Is the script attached?")

func _on_battle_completed(victory: bool):
	print("Controller: Battle finished: Victory: ", victory)
	
	if current_battle_instance:
		current_battle_instance.queue_free()
	if battle_ui_layer:
		battle_ui_layer.queue_free()
		battle_ui_layer = null
	
	map_instance.camera.position = map_instance.current_node.position
	map_instance.visible = true
	map_instance.process_mode = Node.PROCESS_MODE_INHERIT
	GameData.do_save()
	if victory:
		map_instance.mark_available_nodes(map_instance.current_node, true)
		map_instance.queue_redraw()
	else:
		print("end")
		
