# Map Node GD Script

extends Node2D
class_name MapNode

signal node_clicked(node: MapNode)

var is_current_location: bool = false
var is_visited: bool = false
var neighbors: Array[MapNode] = []
var encounter_id: String = "enemy"

@onready var sprite = $Sprite2D
@onready var button = $Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_visuals()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_map_node_pressed() -> void:
	emit_signal("node_clicked", self)

func highlight(active: bool):
	var tween = create_tween()
	var target_scale = Vector2(2.2, 2.2) if active else Vector2(2.0, 2.0)
	tween.tween_property(sprite, "scale", target_scale, 0.5)

func update_visuals() -> void:
	if is_current_location:
		sprite.modulate = Color.GREEN
	elif is_visited:
		sprite.modulate = Color.GRAY
	else:
		sprite.modulate = Color.WHITE
