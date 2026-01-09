extends Node2D

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

func _ready() -> void:
	seed(GameData.map_seed)
	
	if node_scene:
		generate_map()
		
	restore_map_state()

#delta is the time that passes between frames 
func _process(_delta: float) -> void:
	pass

func generate_map() -> void:
	for n in all_nodes:
		n.queue_free()
	all_nodes.clear()
	
	#center node
	var center_node = create_node(Vector2.ZERO)
	center_node.is_current_location = true
	center_node.is_visited = true
	center_node.update_visuals()
	current_node = center_node
	
	var initial_branches = randi_range(3, 5)
	for i in range(initial_branches):
		var angle = (TAU / initial_branches) * i
		var start_dir = Vector2.RIGHT.rotated(angle)
		grow_organic_branch(center_node, start_dir, 0)
	
	for neighbor in center_node.neighbors:
		if neighbor.node_index not in GameData.visited_node_indicies:
			neighbor.is_available_node = true
			neighbor.update_visuals()
			neighbor.confirm_valid()
			
	queue_redraw()

func restore_map_state() ->void:
	for i in range(all_nodes.size()):
		var node = all_nodes[i]
		
		node.node_index = i
		if i in GameData.visited_node_indicies:
			node.is_visited = true
		
		if GameData.visited_node_indicies.size() > 0:
			if i == GameData.visited_node_indicies.back():
				current_node = node 
				node.is_current_location = true
			else:
				node.is_current_location = false
		elif i == 0:
			current_node = node
			node.is_current_location = true
		node.update_visuals()
		print('restore map')

# Recursively walk paths outward
func grow_organic_branch(parent: MapNode, direction: Vector2, current_depth: int) -> void:
	if current_depth >= max_depth:
		return
		
	# Determine how many children this node will have
	var child_count = 2
	
	# Random chance to split into a fork
	if randf() < split_chance:
		child_count = 2
	
	# Random chance to die early (unless we are very close to start)
	if current_depth > 2 and randf() < termination_chance:
		child_count = 0
		
	for i in range(child_count):
		# Calculate a new direction based on previous direction + randomness
		# If splitting (2 children), push them apart slightly
		var angle_offset = randf_range(-direction_jitter, direction_jitter)
		
		if child_count == 2:
			# Force forks to diverge visually
			angle_offset += 0.5 if i == 0 else -0.5
			
		var new_dir = direction.rotated(angle_offset).normalized()
		var candidate_pos = parent.position + (new_dir * path_length)
		
		# Collision Check: Try to find a valid spot
		# If the candidate spot is too crowded, we try to rotate it a bit to fit
		var valid_pos = find_valid_position(candidate_pos, parent.position)
		
		if valid_pos != Vector2.INF:
			var child = create_node(valid_pos)
			
			# Logic Link (Parent-Child)
			connect_nodes(parent, child)
			
			# Visual Logic: Add nearby links (The PoE Web Effect)
			# Look for existing nodes that are close but not our direct parent
			link_nearby_neighbors(child, parent)
			
			# Continue the path
			grow_organic_branch(child, new_dir, current_depth + 1)

# Tries to find a valid spot near the target. Returns Vector2.INF if failed.
func find_valid_position(target: Vector2, origin: Vector2) -> Vector2:
	# If the perfect spot works, take it
	if is_position_free(target):
		return target
		
	# If not, try rotating the vector around the origin slightly to find a gap
	var base_vec = target - origin
	var length = base_vec.length()
	var attempts = 8
	var angle_step = PI / 4.0 # 45 degrees
	
	# Alternate checking left and right
	for i in range(1, attempts):
		var check_angle = angle_step * ceil(float(i)/2.0)
		if i % 2 != 0: check_angle *= -1 # Flip side
		
		var rotated_vec = base_vec.rotated(check_angle)
		var new_target = origin + rotated_vec
		
		if is_position_free(new_target):
			return new_target
			
	return Vector2.INF

# Checks if a position is far enough away from ALL other existing nodes
func is_position_free(pos: Vector2) -> bool:
	for node in all_nodes:
		if pos.distance_to(node.position) < min_node_dist:
			return false
	return true

# Looks for nodes within range to create cross-connections (loops)
func link_nearby_neighbors(node: MapNode, parent_exception: MapNode) -> void:
	var connections_made = 0
	
	for other in all_nodes:
		if other == node or other == parent_exception:
			continue
			
		var dist = node.position.distance_to(other.position)
		
		# If close enough, connect
		if dist < neighbor_connect_range:
			# Visual check: Don't cross lines if possible? 
			# For now, simple distance check works well for "Webs"
			connect_nodes(node, other)
			connections_made += 1
			
			# Limit extra connections so it doesn't become a complete mess
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
	return node_instance
	
func connect_nodes(node_a: MapNode, node_b: MapNode) -> void:
	if not node_a.neighbors.has(node_b):
		node_a.neighbors.append(node_b)
	if not node_b.neighbors.has(node_a):
		node_b.neighbors.append(node_a)

func _draw():
	# Draw lines between all connected neighbors
	# To avoid drawing lines twice, we can use a simpler approach or a set
	var drawn_pairs = {} 
	
	for node in all_nodes:
		for neighbor in node.neighbors:
			# Create a unique ID for the pair to prevent double drawing
			var id1 = node.get_instance_id()
			var id2 = neighbor.get_instance_id()
			var pair_key = str(min(id1, id2)) + "-" + str(max(id1, id2))
			
			if not drawn_pairs.has(pair_key):
				draw_line(node.position, neighbor.position, branch_color, line_width)
				drawn_pairs[pair_key] = true

func _on_node_clicked(target_node: MapNode) -> void:
	if target_node == current_node:
		print("you are already here.")
		print(GameData.completed_node_indicies)
		print(GameData.combat_node)
		print(GameData.combat_success)
		return
	if target_node in current_node.neighbors:
		print("Traveling to node...")
		current_node.is_current_location = false
		current_node.update_visuals()
		
		current_node = target_node
		current_node.confirm_visited()
		
		queue_redraw()
		print(GameData.visited_node_indicies)
		start_encounter(current_node.encounter_id if "encounter_id" in current_node else "random")
	else:
		for neighbor in target_node.neighbors:
			if neighbor.node_index in GameData.visited_node_indicies:
				print("traveling to node...")
				current_node.is_current_location = false
				current_node.update_visuals()
				
				current_node = target_node
				current_node.confirm_visited()
				queue_redraw()
				start_encounter(current_node.encounter_id if "encounter_id" in current_node else "random")
				break
			else:
				print(neighbor.node_index)
	queue_redraw()

func start_encounter(id: String):
	#Send to Battle Manager?
	GameData.encounter_type = current_node.encounter_id
	GameData.combat_node = current_node
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	#print("start encounter: ", id)
	#var success = true
	#if randi_range(0, 100) <= 25:
	#	success = false
	#if not success:
	#	print('failed')
	#else:
	#	print('success')
	#	mark_available_nodes(current_node)

func mark_available_nodes(current_node: MapNode):
	for neighbor in current_node.neighbors:
		if neighbor.node_index not in GameData.visited_node_indicies:
			neighbor.is_available_node = true
			neighbor.update_visuals()
			neighbor.confirm_valid()
			queue_redraw()
	
