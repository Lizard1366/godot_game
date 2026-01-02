# InventoryGrid.gd
# Attach this script to your InventoryGrid Control node scene.
@tool
extends Control

signal item_drag_started(item_data, grid_node)

# --- Grid Properties ---
@export var grid_size: Vector2i = Vector2i(5, 5)
@export var cell_size: Vector2i = Vector2i(64, 64)
@export var grid_color: Color = Color(0.3, 0.3, 0.3)

# --- State Variables ---
var inventory_data: Array = [] 

func _ready() -> void:
	custom_minimum_size = grid_size * cell_size

func _draw() -> void:
	var width = grid_size.x * cell_size.x
	var height = grid_size.y * cell_size.y
	for i in range(grid_size.x + 1):
		var x = i * cell_size.x
		draw_line(Vector2(x, 0), Vector2(x, height), grid_color)
	for i in range(grid_size.y + 1):
		var y = i * cell_size.y
		draw_line(Vector2(0, y), Vector2(width, y), grid_color)

func get_grid_coords_from_global_pos(global_pos: Vector2) -> Vector2i:
	var local_pos = get_global_transform().affine_inverse() * global_pos
	return (local_pos / Vector2(cell_size)).floor()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var grid_pos = (get_local_mouse_position() / Vector2(cell_size)).floor()
		
		# Find which item was clicked on.
		for entry in inventory_data:
			var item = entry.get("item")
			var pos = entry.get("position")
			var item_rect = Rect2(pos, item.size)
			
			if item_rect.has_point(grid_pos):
				# Found the item, tell the manager.
				emit_signal("item_drag_started", entry, self)
				break # Stop searching

# --- Public Functions ---

func load_inventory_data(data: Array) -> void:
	inventory_data = data
	_redraw_inventory()

# --- Internal Functions ---

func _redraw_inventory() -> void:
	# The children are now the Control node containers, so we check for that.
	for child in get_children():
		if child is Control:
			child.queue_free()
	
	for entry in inventory_data:
		var item = entry.get("item")
		var position = entry.get("position")
		_place_item_visual(item, position)

func _place_item_visual(item: Item, position: Vector2i) -> void:
	if not item or not item.texture: return
	
	var item_container = Control.new()
	item_container.size = item.size * cell_size
	item_container.position = position * cell_size
	
	var item_visual = TextureRect.new()
	item_visual.texture = item.texture
	
	item_visual.layout_mode = 1
	
	item_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	item_container.add_child(item_visual)
	add_child(item_container)
