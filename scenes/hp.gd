extends Node3D

@export var max_health :int = 50
var current_health : int = max_health

# Called when the node enters the scene tree for the first time.
func take_dmg(amount) : 
	current_health = clamp(current_health - amount , 0 , max_health)

func _process(delta: float) -> void:
	print(current_health)
	if current_health <= 0 : 
		queue_free()
