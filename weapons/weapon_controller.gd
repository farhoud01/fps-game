class_name  Weapon extends Node 


@export var weapon_scenes : Array[PackedScene] = []
@export var weapon_container : Node3D # The node where guns will appear
var current_weapon_node : WeaponBase = null
var spawned_weapons : Array[Node3D] = []
var current_index : int = -1 # Start at -1 so the first swap works


func _ready() -> void:
	if weapon_scenes.size() <= 0 : return
	for scene in weapon_scenes : 
		var gun = scene.instantiate()
		weapon_container.add_child(gun)
		
		gun.visible = false 
		
		gun.process_mode = Node.PROCESS_MODE_DISABLED
		spawned_weapons.append(gun)
	if spawned_weapons.size() > 0:
		current_index =-1
		swap_weapon(0)

func _input(event: InputEvent) : 
	if event.is_action_pressed("weapon_1"): 
		swap_weapon(0)
		print("weapon 1 ")
	elif event.is_action_pressed("weapon_2"): 
		swap_weapon(1)
		print("weapon 2")
	#elif event.is_action_pressed("weapon_3"): 
	#	swap_weapon(2)
	#	print("weapon2")
	if event.is_action_pressed("shoot") and current_weapon_node:
		current_weapon_node.shoot()
	if event.is_action_pressed("reload")  : 
		current_weapon_node.reload()
func swap_weapon(index) : 
	if index < 0 or index >= spawned_weapons.size() or index == current_index:
		return
	if current_index != -1:
		var old_gun = spawned_weapons[current_index]
		old_gun.visible = false
		old_gun.process_mode = Node.PROCESS_MODE_DISABLED
	current_index = index
	var new_gun = spawned_weapons[current_index]
	new_gun.visible = true
	new_gun.process_mode = Node.PROCESS_MODE_INHERIT
	current_weapon_node = new_gun
	
