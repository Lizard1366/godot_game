# PlayerBoard.gd
# Attach this script to your main "Player_Board" node.

extends Control

signal defeated

# --- Preloads ---
var damage_number_scene = preload("res://scenes/DamageNumber.tscn")

# --- Equipment ---
@export var items: Array[Item]
@export var item_positions: Array[Vector2i]

# --- Stats ---
@export var strength: int = 10
@export var intellect: int = 5
@export var agility: int = 5

# --- Health ---
@export var max_health: int = 100
@export var current_health: int = 100

# --- Battle State ---
var is_battling: bool = false
var opponent = null
var weapon_timers: Array = []

# --- Node References ---
@onready var health_bar: TextureProgressBar = $Player_Board_Elements/Player_Portrait/Player_Hp
@onready var name_label: Label = $Player_Board_Elements/Player_Portrait/Label
@onready var portrait: TextureRect = $Player_Board_Elements/Player_Portrait/TextureRect
@onready var damage_number_spawn = $Player_Board_Elements/DamageNumberSpawn
@onready var damage_number_spawn_2 = $Player_Board_Elements/DamageNumberSpawn2
@onready var inventory_grid = $Player_Board_Elements/Player_Inventory/InventoryGrid 


func _ready() -> void:
	name_label.text = "Player"
	health_bar.min_value = 0
	health_bar.max_value = max_health
	update_health_display()
	
	_setup_visual_inventory()
	_setup_weapon_timers()

func _process(delta: float) -> void:
	if not is_battling: return
	
	for i in range(items.size()):
		var item = items[i]
		
		if item:
			weapon_timers[i] += delta
			if weapon_timers[i] >= item.attack_speed:
				weapon_timers[i] = 0.0
				var damage = strength + item.damage_bonus
				if opponent:
					opponent.take_damage(damage)

# --- Public Functions for Inventory Management ---
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

# --- Internal Setup Functions ---

func _setup_visual_inventory() -> void:
	if items.size() != item_positions.size():
		print("ERROR in PlayerBoard: 'items' and 'item_positions' arrays must have the same size.")
		return
		
	var inventory_data = []
	for i in range(items.size()):
		inventory_data.append({
			"item": items[i],
			"position": item_positions[i]
		})
	
	inventory_grid.load_inventory_data(inventory_data)

func _setup_weapon_timers() -> void:
	weapon_timers.resize(items.size())
	weapon_timers.fill(0.0)

# --- Battle Functions ---

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
