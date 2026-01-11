extends Node2D

signal encounter_started(encounter_id: String, node_index: int)

@export_category("Visuals")
@export var node_scene: PackedScene
@export var line_width: float = 4.0
@export var branch_color: Color = Color.DIM_GRAY
@export var boss_node_color: Color = Color.WEB_MAROON

@export_category("Generation Settings")
@export var max_depth: int = 10
@export var min_node_dist: float = 80.0 # Minimum space between any two nodes
@export var path_length: float = 120.0 # Distance from parent to child
@export var direction_jitter: float = 0.8 # How much the path creates curves (in radians)
@export var neighbor_connect_range: float = 160.0 # Distance to look for cross-connections (loops)

@export_category("Branching Logic")
@export var split_chance: float = 0.3 # Chance to spawn 2 children instead of 1
@export var termination_chance: float = 0.1 # Chance a path stops early

@export_category("Encounter Rates")
@export var encounter_types: Array[String] = ["enemy", "enemy", "enemy", "elite", "treasure", "event"]
@export var boss_encounter_id: String = "boss"

var current_node: MapNode
var all_nodes: Array[MapNode] = []

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	if GameData.map_seed == 0 or GameData.map_seed == null:
		randomize()
		GameData.map_seed = randi()
		
	seed(GameData.map_seed)
	if node_scene:
		generate_map_nodes()
	generate_map()

func generate_map_nodes() -> void:
	for n in all_nodes:
		n.queue_free()
	all_nodes.clear()
	
	#center node
	var center_node = create_node(Vector2.ZERO)
	
	var initial_branches = randi_range(3, 5)
	for i in range(initial_branches):
		var angle = (TAU / initial_branches) * i
		var start_dir = Vector2.RIGHT.rotated(angle)
		grow_organic_branch(center_node, start_dir, 0)

func generate_map() ->void:
	var is_fresh_run = GameData.visited_node_indicies.is_empty()
	
	for i in range(all_nodes.size()):
		var node = all_nodes[i]
		node.node_index = i
		
		node.is_visited = false
		node.is_current_location = false
		node.is_available_node = false
		
		if not is_fresh_run:
			if i in GameData.visited_node_indicies:
				node.is_visited = true
				
			if i == GameData.visited_node_indicies.back():
				current_node = node 
				node.is_current_location = true

				mark_available_nodes(node)
		elif i == 0:
			current_node = node
			node.is_current_location = true
			node.is_visited = true
			
			if 0 not in GameData.visited_node_indicies:
				GameData.visited_node_indicies.append(0)
			if 0 not in GameData.completed_node_indicies:
				GameData.completed_node_indicies.append(0)
		node.button.text = str(node.node_index)
		node.update_visuals()
		
	if current_node:
		mark_available_nodes(current_node)
	queue_redraw()
	print("Restored" + str(GameData.completed_node_indicies))

# Recursively walk paths outward
func grow_organic_branch(parent: MapNode, direction: Vector2, current_depth: int) -> void:
	if current_depth >= max_depth:
		return

	var child_count = 2
	
	if randf() < split_chance:
		child_count = 2
	
	if current_depth > 2 and randf() < termination_chance:
		child_count = 0
		
	for i in range(child_count):
		var angle_offset = randf_range(-direction_jitter, direction_jitter)
		
		if child_count == 2:
			angle_offset += 0.5 if i == 0 else -0.5
			
		var new_dir = direction.rotated(angle_offset).normalized()
		var candidate_pos = parent.position + (new_dir * path_length)
		
		var valid_pos = find_valid_position(candidate_pos, parent.position)
		
		if valid_pos != Vector2.INF:
			var child = create_node(valid_pos)

			connect_nodes(parent, child)
			
			link_nearby_neighbors(child, parent)
			
			grow_organic_branch(child, new_dir, current_depth + 1)

func find_valid_position(target: Vector2, origin: Vector2) -> Vector2:
	if is_position_free(target):
		return target

	var base_vec = target - origin
	var attempts = 8
	var angle_step = PI / 4.0 # 45 degrees
	
	for i in range(1, attempts):
		var check_angle = angle_step * ceil(float(i)/2.0)
		if i % 2 != 0: check_angle *= -1 # Flip side
		
		var rotated_vec = base_vec.rotated(check_angle)
		var new_target = origin + rotated_vec
		
		if is_position_free(new_target):
			return new_target
			
	return Vector2.INF

func is_position_free(pos: Vector2) -> bool:
	for node in all_nodes:
		if pos.distance_to(node.position) < min_node_dist:
			return false
	return true

func link_nearby_neighbors(node: MapNode, parent_exception: MapNode) -> void:
	var connections_made = 0
	
	for other in all_nodes:
		if other == node or other == parent_exception:
			continue
			
		var dist = node.position.distance_to(other.position)

		if dist < neighbor_connect_range:

			connect_nodes(node, other)
			connections_made += 1

			if connections_made >= 2:
				break

func create_node(pos: Vector2, is_boss: bool = false ) -> MapNode:
	var node_instance = node_scene.instantiate()
	node_instance.position = pos
	
	if is_boss:
		node_instance.encounter_id = boss_encounter_id
		node_instance.scale_normal = Vector2(3.0, 3.0)
		node_instance.scale_active = Vector2(3.2, 3.2)
		node_instance.color_default = boss_node_color
	else:
		node_instance.encounter_id = encounter_types.pick_random()
			
	add_child(node_instance)
	node_instance.node_clicked.connect(_on_node_clicked)
	
	all_nodes.append(node_instance)
	node_instance.node_index = all_nodes.size()
	node_instance.button.text = str(all_nodes.size())
	
	node_instance.node_title.text = node_instance.encounter_id
	return node_instance
	
func connect_nodes(node_a: MapNode, node_b: MapNode) -> void:
	if not node_a.neighbors.has(node_b):
		node_a.neighbors.append(node_b)
	if not node_b.neighbors.has(node_a):
		node_b.neighbors.append(node_a)

func _draw():
	var drawn_pairs = {} 
	
	for node in all_nodes:
		for neighbor in node.neighbors:
			var id1 = node.get_instance_id()
			var id2 = neighbor.get_instance_id()
			var pair_key = str(min(id1, id2)) + "-" + str(max(id1, id2))
			
			if not drawn_pairs.has(pair_key):
				draw_line(node.position, neighbor.position, branch_color, line_width)
				drawn_pairs[pair_key] = true

func _on_node_clicked(target_node: MapNode) -> void:
	if target_node == current_node:
		return
	
	var can_travel = false
	
	if target_node in current_node.neighbors:
		can_travel = true
	else:
		for neighbor in target_node.neighbors:
			if neighbor.node_index in GameData.visited_node_indicies:
				can_travel = true
				break
	if not can_travel:
		#TODO Display message to user?
		return
		
	#target_node.node_info.visible = true
	
	#current_node.is_current_location = false
	#current_node.update_visuals()
	
	#current_node = target_node
	#current_node.confirm_visited()
	
	
	#if target_node.node_index not in GameData.visited_node_indicies:
	#	GameData.visited_node_indicies.append(target_node.node_index)
	
	#if current_node.node_index in GameData.completed_node_indicies:
	#	print("node already cleared.")
	#	mark_available_nodes(current_node)
	#else:
	#	print('trigger encounter')
		#trigger_encounter(current_node)
		
	#queue_redraw()

func trigger_encounter(node: MapNode):
	emit_signal("encounter_started", node.encounter_id, node.node_index)

func mark_available_nodes(center: MapNode):
	for neighbor in center.neighbors:
		if neighbor.node_index not in GameData.visited_node_indicies:
			neighbor.is_available_node = true
			neighbor.update_visuals()
			neighbor.confirm_valid()
	queue_redraw()
	print(GameData.valid_node_indicies)
