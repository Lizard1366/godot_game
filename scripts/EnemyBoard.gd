# EnemyBoard.gd
# Attach this script to your main "Enemy_Board" node.

extends Control

signal defeated

# --- Preloads ---
var damage_number_scene = preload("res://scenes/DamageNumber.tscn")

# --- Equipment ---
@export var items: Array[Item]
@export var item_positions: Array[Vector2i]

# --- Stats ---
@export var strength: int = 15
@export var intellect: int = 8
@export var agility: int = 3

# --- Health ---
@export var max_health: int = 550
@export var current_health: int = 550

# --- Battle State ---
var is_battling: bool = false
var opponent = null
var weapon_timers: Array = []

# --- Node References ---
@onready var health_bar: TextureProgressBar = $Enemy_Board_Elements/Enemy_Portrait/Enemy_Hp
@onready var name_label: Label = $Enemy_Board_Elements/Enemy_Portrait/Label
@onready var portrait: TextureRect = $Enemy_Board_Elements/Enemy_Portrait/TextureRect
@onready var damage_number_spawn = $Enemy_Board_Elements/DamageNumberSpawn
@onready var damage_number_spawn_2 = $Enemy_Board_Elements/DamageNumberSpawn2
@onready var inventory_grid = $Enemy_Board_Elements/Enemy_Inventory/InventoryGrid


func _ready() -> void:
	name_label.text = "Denial"
	health_bar.min_value = 0
	health_bar.max_value = max_health
	update_health_display()
	
	_setup_visual_inventory()
	_setup_weapon_timers()

func _process(delta: float) -> void:
	if not is_battling: return
	
	for i in range(items.size()):
		if items[i]:
			weapon_timers[i] += delta
			if weapon_timers[i] >= items[i].attack_speed:
				weapon_timers[i] = 0.0
				var damage = strength + items[i].damage_bonus
				print("Enemy attacks with %s for %d damage!" % [items[i].item_name, damage])
				if opponent:
					opponent.take_damage(damage)

func _setup_visual_inventory() -> void:
	if items.size() != item_positions.size():
		print("ERROR in EnemyBoard: 'items' and 'item_positions' arrays must have the same size.")
		return
	var inventory_data = []
	for i in range(items.size()):
		inventory_data.append({"item": items[i], "position": item_positions[i]})
	inventory_grid.load_inventory_data(inventory_data)

func _setup_weapon_timers() -> void:
	weapon_timers.resize(items.size())
	weapon_timers.fill(0.0)

func remove_item(item_data: Dictionary) -> void:
	var item_to_remove = item_data.get("item")
	var index = items.find(item_to_remove)
	if index != -1:
		items.remove_at(index)
		item_positions.remove_at(index)
		_setup_visual_inventory()
		_setup_weapon_timers()

func add_item(item_to_add: Item, position: Vector2i) -> void:
	items.append(item_to_add)
	item_positions.append(position)
	_setup_visual_inventory()
	_setup_weapon_timers()

func start_battle(target) -> void:
	opponent = target
	is_battling = true

func stop_battle() -> void:
	is_battling = false

func take_damage(damage_amount: int) -> void:
	current_health -= damage_amount
	current_health = clamp(current_health, 0, max_health)
	update_health_display()
	_show_damage_number(damage_amount)
	if current_health <= 0:
		emit_signal("defeated")

func update_health_display() -> void:
	health_bar.value = current_health

func _show_damage_number(amount: int) -> void:
	var damage_number = damage_number_scene.instantiate()
	damage_number.text = str(amount)
	if randi_range(1, 2) == 1:
		damage_number.global_position = damage_number_spawn.global_position
	else:
		damage_number.global_position = damage_number_spawn_2.global_position
	get_tree().root.add_child(damage_number)
