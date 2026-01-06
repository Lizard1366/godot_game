extends Node2D

@export var node_scene: PackedScene
@export var line_width: float = 4.0
@export var branch_color: Color = Color.DIM_GRAY

var current_node: MapNode
var all_nodes: Array[MapNode] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func generate_map() -> void:
	var center_node = create_node(Vector2.ZERO)
	center_node.is_current_location = true
	center_node.is_visited = true
	center_node.update_visuals()
	current_node = center_node
	
	spawn_branches(center_node, 0, 4)
	
	queue_redraw()

func spawn_branches(parent: MapNode, current_layer: int, max_layers: int) -> void:
	if current_layer >= max_layers:
		return
	var child_count = randi_range(1,3)
	
	var radius_step = 150.0
	var current_radius = radius_step
	
	var base_angle = 0.0
	var angle_spread = PI * 2 
	
	if parent.position != Vector2.ZERO:
		base_angle = parent.position.angle()
		angle_spread = PI / 1.5
		
	for i in range(child_count):
		var angle_offset = lerp_angle(-angle_spread/2, angle_spread/2, float(i + 1) / (child_count + 1))
		var final_angle = base_angle + angle_offset + randf_range(-0.2, 0.2)
		
		var direction = Vector2.RIGHT.rotated(final_angle)
		var spawn_pos = parent.position + (direction * current_radius)
		
		var child = create_node(spawn_pos)
		
		connect_nodes(parent, child)
		
		spawn_branches(child, current_layer + 1, max_layers)
		
func create_node(pos: Vector2) -> MapNode:
	var node_instance = node_scene.instantiate()
	node_instance.position = pos
	add_child(node_instance)
	node_instance.node_clicked.connect(_on_node_clicked)
	all_nodes.append(node_instance)
	return node_instance
	
func connect_nodes(node_a: MapNode, node_b: MapNode) -> void:
	if not node_a.neighbors.has(node_b):
		node_a.neighbors.has(node_b)
	if not node_b.neighbors.has(node_a):
		node_b.neighbors.has(node_a)

func _draw():
	for node in all_nodes:
		for neighbor in node.neighbors:
			draw_line(node.position, neighbor.position, branch_color, line_width)

func _on_node_clicked(target_node: MapNode) -> void:
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
