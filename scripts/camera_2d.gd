extends Camera2D
var dragging = false
var drag_start_position = Vector2.ZERO
@export var zoom_strength := 1.1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				dragging = true
				drag_start_position = get_global_mouse_position()
			else:
				dragging = false
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= zoom_strength
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom /= zoom_strength
	elif event is InputEventMouseMotion and dragging:
		var mouse_current_position = get_global_mouse_position()
		var delta = drag_start_position - mouse_current_position
		
		position += delta
		drag_start_position = get_global_mouse_position()
