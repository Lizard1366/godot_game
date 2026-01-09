extends Node2D
class_name MapNode

signal node_clicked(node: MapNode)

@export_group("Gameplay")
@export var encounter_id: String = "enemy"

@export_group("Visual States")
@export var color_current: Color = Color.GREEN
@export var color_visited: Color = Color.GRAY
@export var color_default: Color = Color.WHITE
@export var color_available: Color = Color.ALICE_BLUE

@export_group("Animation")
@export var scale_active: Vector2 = Vector2(2.2, 2.2)
@export var scale_normal: Vector2 = Vector2(2.0, 2.0)
@export var tween_duration: float = 0.5

var is_current_location: bool = false
var is_visited: bool = false
var is_available_node: bool = false
var neighbors: Array[MapNode] = []
var node_index: int = 0

@onready var sprite = $Sprite2D
@onready var button = $Button

func _ready() -> void:
	# Ensure the sprite starts at the correct 'normal' scale
	sprite.scale = scale_normal
	update_visuals()

func _on_map_node_pressed() -> void:
	emit_signal("node_clicked", self)

func confirm_visited():
	is_visited = true
	is_current_location = true
	GameData.register_visit(node_index)
	update_visuals()

func confirm_valid():
	is_available_node = true
	is_current_location = false
	print('valid')
	GameData.register_valid(node_index)
	update_visuals()

func highlight(active: bool):
	var tween = create_tween()
	var target_scale = scale_active if active else scale_normal
	tween.tween_property(sprite, "scale", target_scale, tween_duration)

func update_visuals() -> void:
	if is_current_location:
		button.modulate = color_current
	elif is_visited:
		button.modulate = color_visited
	elif is_available_node and not is_visited:
		button.modulate = color_available
	else:
		button.modulate = color_default
	#print("update Visuals " + str(neighbors))
