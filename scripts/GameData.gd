extends Node

var map_seed: int = 0
var map_generated: bool = false

var visited_node_indicies: Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	map_seed = randi()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func register_visit(node_index: int):
	if not node_index in visited_node_indicies:
		visited_node_indicies.append(node_index)

func reset_run():
	randomize()
	map_seed = randi()
	visited_node_indicies.clear()
	map_generated = false
