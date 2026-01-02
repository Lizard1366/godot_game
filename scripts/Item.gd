# Item.gd
extends Resource

class_name Item

# --- Item Properties ---
@export var item_name: String = "New Item"
@export var damage_bonus: float = 0.0
@export var attack_speed: float = 3.0 
@export var texture: Texture2D 

@export var size: Vector2i = Vector2i(1, 1) 
