extends Node

var map_seed: int = 0
var map_generated: bool = false

var visited_node_indicies: Array[int] = []
var valid_node_indicies: Array[int] = []
var completed_node_indicies: Array[int] = []

var combat_node: int = 0
var encounter_type: String
var combat_success: bool = false

var save_data: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	map_seed = randi()

func reset_game() -> void:
	map_seed = 0
	map_generated = false
	visited_node_indicies = []
	valid_node_indicies= []
	completed_node_indicies = []
	combat_node = 0
	encounter_type=""
	combat_success = false
	save_data = {}

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
	

func build_save():
	save_data = {
		"map_seed": map_seed,
		"visited_node_indicies": visited_node_indicies,
		"completed_node_indicies": completed_node_indicies,
		"valid_node_indicies": valid_node_indicies
	}

func do_save():
	print('saving game')
	build_save()
	print(save_data)
	var file = FileAccess.open("res://saved_game/game.json",FileAccess.WRITE)
	file.store_line(JSON.stringify(save_data))
	file.close()

func load_game():
	if not FileAccess.file_exists("res://saved_game/game.json"):
		return
	var save_file = FileAccess.open("res://saved_game/game.json", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
		var load_data = json.data
		for i in load_data.keys():
			GameData.set(i, load_data[i])
