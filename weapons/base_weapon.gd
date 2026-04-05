class_name WeaponBase extends Node3D 


@export var weapon_data : Weapon_data
var current_ammo : int
var current_reserve : int
var is_reloading : bool = false


func _ready() -> void:
	if weapon_data :
		position = weapon_data.weapon_position
		current_ammo = weapon_data.clip_size
		current_reserve = weapon_data.mag_size
func shoot():
	# Common logic for ALL guns (Ammo check, Raycast)
	if weapon_data:
		
		if current_ammo> 0 : 
			print("Firing: ", weapon_data.weapon_name)
			current_ammo -=1
			#shoot ray or projectile 
		# You can put a generic Raycast call here
		
func reload() : 
	if Input.is_action_just_pressed("reload") || current_ammo ==0 && current_reserve > 0:
		# wait reload time play anim 
		is_reloading = true
		await get_tree().create_timer(weapon_data.reload_speed).timeout
		var amount_needed = weapon_data.clip_size - current_ammo
		var amount_to_transfer = min(current_reserve, amount_needed)
		
		# 3. Apply the transaction
		current_reserve -= amount_to_transfer
		current_ammo += amount_to_transfer

		is_reloading = false
		print("Reload Done. Ammo: ", current_ammo, " Reserve: ", current_reserve)
		
