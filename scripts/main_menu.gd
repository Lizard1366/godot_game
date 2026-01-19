extends Control

@onready var load_button: Button = $VBoxContainer/load_game

func _ready() -> void:
	load_game()

func load_game():
	if not FileAccess.file_exists("res://saved_game/game.json"):
		return
	else:
		var save_file = FileAccess.open("res://saved_game/game.json", FileAccess.READ)
		var parsed = JSON.parse_string(save_file.get_line())
		if parsed and parsed.size() > 0:
			load_button.visible = true
			print(parsed)
			

func _on_button_start_pressed() -> void:
	SaveManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/game_controller.tscn")

func _on_button_quit_pressed() -> void:
	get_tree().quit()


func _on_load_game_pressed() -> void:
	SaveManager.load_game()
	
	get_tree().change_scene_to_file("res://scenes/game_controller.tscn")
