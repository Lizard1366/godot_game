# DamageNumber.gd
# Attach this script to your DamageNumber Label scene.

extends Label

var velocity: Vector2
var gravity: Vector2 = Vector2(0, 450) # How strongly it's pulled down.
var lifetime: float = 0.8
var time_alive: float = 0.0

# This function now runs asynchronously to handle the delay.
func _ready() -> void:
	# Hide the label initially.
	visible = false
	
	# Wait for a random delay between 0 and 0.2 seconds.
	await get_tree().create_timer(randf_range(0.0, 0.2)).timeout
	
	visible = true
	
	var random_x = randf_range(-150.0, 150.0) 
	var initial_y = -250.0 
	velocity = Vector2(random_x, initial_y)


func _process(delta: float) -> void:
	if not visible:
		return
		
	velocity += gravity * delta
	
	position += velocity * delta
	
	time_alive += delta
	
	modulate.a = 1.0 - (time_alive / lifetime)
	
	if time_alive >= lifetime:
		queue_free()
