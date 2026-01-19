extends Node

var save_data: Dictionary

func reset_game() -> void:
	GameData.map_seed = 0
	GameData.map_generated = false
	GameData.visited_node_indicies = []
	GameData.valid_node_indicies= []
	GameData.completed_node_indicies = []
	GameData.combat_node = 0
	GameData.encounter_type=""
	GameData.combat_success = false
	save_data = {}

func build_save():
	save_data = {
		"map_seed": GameData.map_seed,
		"visited_node_indicies": GameData.visited_node_indicies,
		"completed_node_indicies": GameData.completed_node_indicies,
		"valid_node_indicies": GameData.valid_node_indicies
	}
	
func do_save():
	build_save()
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
		for key in load_data.keys():
			if key in GameData:
				var value_to_load = load_data[key]
				if typeof(GameData.get(key)) == TYPE_ARRAY:
					GameData.get(key).clear()
					for item in value_to_load:
						GameData.get(key).append(int(item))
				else:
					GameData.set(key, value_to_load)
