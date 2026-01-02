# DraggableItem.gd

extends TextureRect

func _process(delta: float) -> void:
	global_position = get_global_mouse_position() - (size / 2)
