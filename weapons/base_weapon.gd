class_name WeaponBase extends Node3D 


@export var weapon_data : Weapon_data
var current_ammo : int
var current_reserve : int
var is_reloading : bool = false
var ray_hit : RayCast3D 
var cam : Camera3D
func _ready() -> void:
	if weapon_data :
		position = weapon_data.weapon_position
		current_ammo = weapon_data.clip_size
		current_reserve = weapon_data.mag_size
		if weapon_data.raycast_type : 
			ray_hit = RayCast3D.new()
			if cam:  
				cam.add_child(ray_hit)
				ray_hit.position = Vector3.ZERO # Center it in the camera's "pupil"
				ray_hit.rotation = Vector3.ZERO
			ray_hit.enabled = true 
				
			if owner is CollisionObject3D: ray_hit.add_exception(owner)
			ray_hit.target_position = Vector3(0,0,-weapon_data.range)
			ray_hit.collision_mask = 3 
func shoot():
	if ray_hit != null : print("ray exists ")
	if not weapon_data: return
	if weapon_data:
		
		if current_ammo> 0 : 
			print("Firing: ", weapon_data.weapon_name)
			current_ammo -=1
	if weapon_data.raycast_type : 
		if not ray_hit: 
			print("CRITICAL: ray_hit is null!")
			return
		if ray_hit.get_parent() == null:
			if not cam: cam = get_viewport().get_camera_3d()
			if cam : 
				cam.add_child(ray_hit)
				ray_hit.position = Vector3.ZERO
				ray_hit.rotation = Vector3.ZERO
				print("Successfully attached ray to: ", cam.name)
			else : print("still no parent ?? ")
		if current_ammo >0 :
			ray_hit.force_raycast_update()
			if ray_hit.is_colliding() :
				var target = ray_hit.get_collider()
				print("hitted , " + target.name)
			else : 
				print("ray hit nothing ")
			
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
		
