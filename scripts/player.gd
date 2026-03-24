extends CharacterBody3D
@onready var head: Node3D = $neck/head
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var neck: Node3D = $neck
var can_slide : bool = true
@export var slide_cooldown : float = 1.25# 1 second cooldown
@export var free_look_tilt_amount : float = 8
@export var air_lerp_speed : float = 0.3 
var colray 
var direction = Vector3.ZERO
var current_speed : float = 5.0
var lastvel = Vector3.ZERO
@export var sprint_speed : float = 8.0
@onready var eyes: Node3D = $neck/head/eyes
@onready var cam: Camera3D = $neck/head/eyes/Camera3D
@onready var animation_player: AnimationPlayer = $neck/AnimationPlayer

const walk_speed = 5.0
const crouch_speed :float = 3.0
const jump_vel = 4.5
var mouse_sens = 0.35
var lerp_speed = 10.0
@export var crouch_depth:float = -0.8
# slide vars
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0
# states

enum state {walking,sprinting, crouching , sliding}
var free_looking : bool = false 

var current_state = state.walking
 # headbobbing vars
const head_bobb_sprint_speed = 22.0
const head_bobb_walk_speed = 14.0
const head_bobb_crouch_speed = 10

const head_bobb_crouch_intensity = 0.05
const head_bobb_sprint_intensity = 0.03
const head_bobb_walk_intensity = 0.02
var head_bobb_current_intensity = 0.0
var headbobbing_vec = Vector2.ZERO
var headbobbing_index = 0.0
func _handle_speed(delta) : 
	if current_state == state.sliding: return
	if (Input.is_action_pressed("sprint") && standing_collision_shape.disabled == false) : 
		current_state = state.sprinting
		current_speed = lerp(current_speed,sprint_speed,lerp_speed*delta ) ;
	elif current_state != state.crouching : 
		current_speed = lerp(current_speed,walk_speed,lerp_speed*delta ) ;
		current_state = state.walking
	print(state.keys()[current_state])
	
	
	
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crouching_collision_shape.disabled = true 
	init_col_ray() 
	free_looking = false
func _input(event):
	if event is InputEventMouseMotion : 
		if free_looking :
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else : 
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(90))
func _physics_process(delta: float) -> void:
	handle_landing()
	_handle_speed(delta)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_vel
		animation_player.play("jump")
		if current_state == state.sliding : 
			var jump_direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
			velocity.x = jump_direction.x * slide_speed
			velocity.z = jump_direction.z * slide_speed
			current_state = state.walking
			start_slide_cooldown()
			

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "down")
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	else : 
		if input_dir != Vector2.ZERO :
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*air_lerp_speed)
		
	if current_state == state.sliding : 
		direction  = (transform.basis * Vector3(slide_vector.x ,0 , slide_vector.y)).normalized()
		current_speed = (slide_timer +0.1)  * slide_speed
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		 
		
	
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	handle_slide(input_dir,delta)
	lastvel = velocity
	move_and_slide()
	
func _process(delta: float) -> void:
	handle_headbobbing(delta,Input.get_vector("left", "right", "forward", "down"))
	handle_free_looking(delta)
	reset_col_on_air(delta)
	print(free_looking)

	handle_crouching(delta)
func head_hit_celling():
	if colray.is_colliding() : 
		return true ;
	else : return false 

func init_col_ray() : 
	colray = RayCast3D.new()
	colray.add_exception(self)
	add_child(colray)
	colray.enabled = true 
	colray.target_position = Vector3(0,2.1,0)
func handle_crouching(d) : 
	if not is_on_floor() : return 
	if current_state == state.sliding: 
		head.position.y = lerp(head.position.y,crouch_depth,d * lerp_speed)
		standing_collision_shape.disabled = true ; 
		crouching_collision_shape.disabled = false; 
		return 
	if Input.is_action_pressed("crouch ") or head_hit_celling() : 
		current_speed = lerp(current_speed, crouch_speed , d * lerp_speed)
		current_state = state.crouching
		head.position.y = lerp(head.position.y,crouch_depth,d * lerp_speed)
		standing_collision_shape.disabled = true ; 
		crouching_collision_shape.disabled = false
		
	
	elif !head_hit_celling(): 
		head.position.y = lerp(head.position.y,0.0,d * lerp_speed)
		standing_collision_shape.disabled = false ; 
		crouching_collision_shape.disabled = true
		current_state = state.walking
func handle_free_looking (d): 
	
	if Input.is_action_pressed("free_look") or current_state == state.sliding  : 
		free_looking = true 
		if current_state == state.sliding : 
			eyes.rotation.z = lerp(eyes.rotation.z,-deg_to_rad(7.0),d)
		else : 
			eyes.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else : 
		free_looking=false 
		neck.rotation.y = lerp(neck.rotation.y , 0.0 , d * lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z , 0.0 , d * lerp_speed)
func handle_slide(dir,delta) : 
	if not is_on_floor()  : return 
	if Input.is_action_pressed("sprint") && can_slide && dir != Vector2.ZERO && current_state != state.sliding  && current_state != state.crouching: 
		if  Input.is_action_just_pressed("slide"):
			current_state =state.sliding 
			slide_timer = slide_timer_max
			print("sliding start ")
			slide_vector = dir
			
	if current_state == state.sliding  : 
		slide_timer -= delta
		free_looking = true 
		if slide_timer <= 0 : 
			current_state = state.crouching
			free_looking = false
			print("sliding end ")
			start_slide_cooldown()
func start_slide_cooldown():
	can_slide = false
	await get_tree().create_timer(slide_cooldown).timeout
	can_slide = true
	print("can slide again")
func reset_col_on_air(delta):
	if not is_on_floor() : 
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
func handle_headbobbing(delta, input_dir) : 
	if current_state == state.sprinting : 
		head_bobb_current_intensity = head_bobb_sprint_intensity
		headbobbing_index += head_bobb_sprint_speed* delta 
	elif current_state == state.walking : 
		head_bobb_current_intensity = head_bobb_walk_intensity
		headbobbing_index += head_bobb_walk_speed* delta 
	elif current_state == state.crouching : 
		head_bobb_current_intensity = head_bobb_crouch_intensity
		headbobbing_index += head_bobb_crouch_speed* delta 
	if is_on_floor() && current_state!= state.sliding && input_dir != Vector2.ZERO : 
		headbobbing_vec.y = sin (headbobbing_index )
		headbobbing_vec.x = sin (headbobbing_index /2.0 )+0.5
		eyes.position.y = lerp(eyes.position.y , headbobbing_vec.y*(head_bobb_current_intensity/2.0) , lerp_speed*delta)
		eyes.position.x = lerp(eyes.position.x , headbobbing_vec.x*(head_bobb_current_intensity) , lerp_speed*delta)
	else : 
		eyes.position.y = lerp(eyes.position.y ,0.0 , lerp_speed*delta)
		eyes.position.x = lerp(eyes.position.x , 0.0, lerp_speed*delta)
func handle_landing () : 
	if is_on_floor() : 
		if lastvel.y < 0.0:
			animation_player.play("landing")
