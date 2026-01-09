# BattleManager.gd
extends VBoxContainer

signal battle_completed(victory: bool)

# --- Preloads ---
var draggable_item_scene = preload("res://scenes/DraggableItem.tscn")

# --- Node References ---
@onready var player_board = $Player_Board
@onready var enemy_board = $Enemy_Board

@export var start_button = Button
#get_node("/root/Main/CanvasLayer/StartButton")

# --- Drag & Drop State ---
var is_dragging: bool = false
var dragged_item_data = null
var source_board = null
var dragged_item_visual = null

# --- Battle State ---
var battle_over: bool = false

func _ready() -> void:
	_setup_start_button()
	
	player_board.defeated.connect(_on_player_defeated)
	enemy_board.defeated.connect(_on_enemy_defeated)
	
	player_board.inventory_grid.item_drag_started.connect(_on_item_drag_started)
	enemy_board.inventory_grid.item_drag_started.connect(_on_item_drag_started)

func _setup_start_button() -> void:
	if not start_button:
		if has_node("%StartButton%"):
			start_button = get_node("%StartButton%")
		elif has_node("../CanvasLayer/StartButton"):
			start_button = get_node("../CanvasLayer/StartButton")
		elif get_parent().has_node("CanvasLayer/StartButton"):
			start_button = get_parent().get_node("CanvasLater/StartButton")
	if start_button:
		var button_signal = Signal(start_button, "pressed")
		
		if not button_signal.is_connected(_on_start_button_pressed):
			button_signal.connect(_on_start_button_pressed)
	else:
		push_warning("BattleManager: StartButton not found! Please assign it in the Inspector.")

func _unhandled_input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		_on_item_dropped(event.global_position)

func _on_item_drag_started(item_data: Dictionary, grid_node) -> void:
	if player_board.is_battling: return
	
	is_dragging = true
	dragged_item_data = item_data
	
	if grid_node == player_board.inventory_grid:
		source_board = player_board
	else:
		source_board = enemy_board
	
	source_board.remove_item(item_data)
	
	dragged_item_visual = draggable_item_scene.instantiate()
	dragged_item_visual.texture = dragged_item_data.get("item").texture
	dragged_item_visual.size = dragged_item_data.get("item").size * source_board.inventory_grid.cell_size
	get_tree().root.add_child(dragged_item_visual)

func _on_item_dropped(global_mouse_pos: Vector2) -> void:
	var target_board = null
	
	if player_board.inventory_grid.get_global_rect().has_point(global_mouse_pos):
		target_board = player_board
	elif enemy_board.inventory_grid.get_global_rect().has_point(global_mouse_pos):
		target_board = enemy_board
	
	if target_board:
		var new_grid_pos = target_board.inventory_grid.get_grid_coords_from_global_pos(global_mouse_pos)
		target_board.add_item(dragged_item_data.get("item"), new_grid_pos)
	else:
		source_board.add_item(dragged_item_data.get("item"), dragged_item_data.get("position"))
	
	# Clean up.
	is_dragging = false
	dragged_item_visual.queue_free()
	dragged_item_visual = null
	dragged_item_data = null
	source_board = null

func _on_start_button_pressed() -> void:
	print("Start button pressed! Battle begins.")
	if start_button:
		start_button.hide()
	player_board.start_battle(enemy_board)
	enemy_board.start_battle(player_board)

func _on_player_defeated() -> void:
	if battle_over: return
	battle_over = true
	print("DEFEAT! The player has been defeated.")
	player_board.stop_battle()
	enemy_board.stop_battle()
	update_node_status(false)

func _on_enemy_defeated() -> void:
	if battle_over: return
	battle_over = true
	print("VICTORY! The player has won.")
	player_board.stop_battle()
	enemy_board.stop_battle()
	update_node_status(true)

func update_node_status(complete: bool):
	print(GameData.map_seed)
	
	if(complete):
		GameData.completed_node_indicies.append(GameData.combat_node)
	emit_signal("battle_completed", complete)
	#get_tree().change_scene_to_file("res://scenes/world_map.tscn")
