extends Node

var map_seed: int = 0
var map_generated: bool = false

var visited_node_indicies: Array[int] = []
var valid_node_indicies: Array[int] = []
var completed_node_indicies: Array[int] = []

var combat_node: int = 0
var encounter_type: String
var combat_success: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	map_seed = randi()

func register_visit(node_index: int):
	if not node_index in visited_node_indicies:
		visited_node_indicies.append(node_index)

func register_valid(node_index: int):
	if not node_index in valid_node_indicies:
		valid_node_indicies.append(node_index)
	elif node_index in completed_node_indicies:
		valid_node_indicies.erase(node_index)
		
func register_completed_node():
	if not combat_node in completed_node_indicies and combat_success:
		completed_node_indicies.append(combat_node)

func reset_run():
	randomize()
	map_seed = randi()
	visited_node_indicies.clear()
	map_generated = false
