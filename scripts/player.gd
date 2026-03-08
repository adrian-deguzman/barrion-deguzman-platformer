extends CharacterBody2D

# Movement constants
const MAX_SPEED = 150.0
const ACCELERATION = 800.0 
const FRICTION = 500.0 
const AIR_ACCELERATION = 400.0 
const AIR_FRICTION = 1000.0 
const JUMP_VELOCITY = -400.0
const WALL_JUMP_PUSHBACK = 150.0 

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# --- NEW: Set this exact coordinate in the Godot Inspector! ---
@export var respawn_coordinate := Vector2(40, 40)

func die() -> void:
	# Teleport to the specific coordinate and kill all momentum
	global_position = respawn_coordinate
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# --- TILE DATA LOGIC ---
	var speed_multiplier := 1.0 
	var is_sliding := false
	var is_dead := false # Track if we died this specific frame
	
	# Loop through ALL collisions 
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.has_method("get_cell_tile_data"):
			var push_point = collision.get_position() - collision.get_normal()
			var map_position = collider.local_to_map(collider.to_local(push_point))
			
			var tile_data: TileData
			if collider is TileMap:
				tile_data = collider.get_cell_tile_data(0, map_position)
			else:
				tile_data = collider.get_cell_tile_data(map_position)
			
			if tile_data:
				# 1. Check for Death Tile 
				if tile_data.get_custom_data("is_death_tile"):
					is_dead = true
					break # Stop checking other tiles, death takes priority
				
				# 2. Check for Slide/Slow 
				if is_on_floor() and collision.get_normal().y < 0:
					if tile_data.get_custom_data("is_slide_tile"):
						is_sliding = true
					elif tile_data.get_custom_data("is_slow_tile"):
						speed_multiplier = 0.4 
	# -----------------------

	# --- DEATH HANDLING ---
	if is_dead:
		die()
		move_and_slide() # Force Godot to recalculate collisions at the safe spot
		return # Skip all movement/input logic for this single frame to prevent bugs

	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump and wall jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall_only():
			var wall_normal = get_wall_normal()
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_normal.x * WALL_JUMP_PUSHBACK
		
	# Cut jump short if button is released early
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# Get the input direction
	var direction := Input.get_axis("move_left", "move_right")
	
	# Handle sprite flipping
	if is_on_wall_only():
		animated_sprite_2d.flip_h = get_wall_normal().x > 0
	else:
		if direction > 0:
			animated_sprite_2d.flip_h = false
		elif direction < 0:
			animated_sprite_2d.flip_h = true
		
	# Handle animations based on state
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	elif is_on_wall_only():
		animated_sprite_2d.play("wall_jump")
	else:
		animated_sprite_2d.play("jump")
	
	# Determine current acceleration and friction based on whether player is in the air
	var current_accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
	var current_friction = FRICTION if is_on_floor() else AIR_FRICTION

	# Apply Slide Mechanics
	if is_sliding:
		direction = 0 
		current_friction = 0 
		if velocity.x == 0:
			velocity.x = 50.0 if not animated_sprite_2d.flip_h else -50.0

	# Apply Horizontal Acceleration and Deceleration
	if direction != 0:
		var target_speed = direction * (MAX_SPEED * speed_multiplier)
		velocity.x = move_toward(velocity.x, target_speed, current_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)

	move_and_slide()
