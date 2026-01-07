extends Node2D

@export var node_scene: PackedScene
@export var line_width: float = 4.0
@export var branch_color: Color = Color.DIM_GRAY
@export var node_randomness: float = 0.3
@export var node_travel_distance: float = 150.0
@export var pie_slice_size: float = 2.0
@export var layers: int = 6

var starting_node_layer = 0
var current_node: MapNode
var all_nodes: Array[MapNode] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	generate_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()

func generate_map() -> void:
	for n in all_nodes:
		n.queue_free()
	all_nodes.clear()
	
	var center_node = create_node(Vector2.ZERO)
	center_node.is_current_location = true
	center_node.is_visited = true
	center_node.update_visuals()
	current_node = center_node
	
	spawn_branches(center_node, starting_node_layer, layers, -PI, PI)
	
	queue_redraw()

func spawn_branches(parent: MapNode, current_layer: int, max_layers: int, min_angle: float, max_angle: float) -> void:
	if current_layer >= max_layers:
		return
		
	var child_count = randi_range(1,3)
	
	var total_angle_space = max_angle - min_angle
	var angle_per_child = total_angle_space / child_count
	
	# node travel distance -> var radius_step = 150.0 magic number
	
	for i in range(child_count):
		var child_min = min_angle + (i * angle_per_child)
		var child_max = child_min + angle_per_child
		var center_of_slice = child_min + (angle_per_child / pie_slice_size)
		
		var max_jitter = (angle_per_child / pie_slice_size) * node_randomness
		var final_angle = center_of_slice + randf_range(-max_jitter, max_jitter)
		
		var direction = Vector2.RIGHT.rotated(final_angle)
		var spawn_pos = parent.position + (direction * node_travel_distance)
		
		var child = create_node(spawn_pos)
		connect_nodes(parent, child)
		
		spawn_branches(child, current_layer + 1, max_layers, child_min, child_max)
		
func create_node(pos: Vector2) -> MapNode:
	var node_instance = node_scene.instantiate()
	node_instance.position = pos
	add_child(node_instance)
	node_instance.node_clicked.connect(_on_node_clicked)
	all_nodes.append(node_instance)
	return node_instance
	
func connect_nodes(node_a: MapNode, node_b: MapNode) -> void:
	if not node_a.neighbors.has(node_b):
		node_a.neighbors.append(node_b)
	if not node_b.neighbors.has(node_a):
		node_b.neighbors.append(node_a)

func _draw():
	for node in all_nodes:
		for neighbor in node.neighbors:
			draw_line(node.position, neighbor.position, branch_color, line_width)

func _on_node_clicked(target_node: MapNode) -> void:
	print(target_node.neighbors)
	if target_node == current_node:
		print("you are already here.")
		return
	if target_node in current_node.neighbors:
		print("Traveling to node...")
		current_node.is_current_location = false
		current_node.update_visuals()
		
		current_node = target_node
		current_node.is_current_location = true
		current_node.is_visited = true
		current_node.update_visuals()
		
		start_encounter(current_node.encounter_id)
	else:
		print("Too Far Away!")

func start_encounter(id: String):
	print("start encounter: ", id)
