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

func _physics_process(delta: float) -> void:
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
		
	# Cut jump short if button is released early (Variable Jump Height)
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
	
	# --- NEW SLOW TILE LOGIC ---
	var speed_multiplier := 1.0 # Default speed
	
	if is_on_floor():
		# Loop through all collisions occurring this frame
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# Check if we are standing on a TileMap or TileMapLayer
			if collider.has_method("get_cell_tile_data"):
				# Push slightly past the collision point to accurately grab the cell coordinates
				var push_point = collision.get_position() - collision.get_normal()
				var map_position = collider.local_to_map(collider.to_local(push_point))
				
				# Handle both older TileMap (requires layer index) and newer TileMapLayer
				var tile_data: TileData
				if collider is TileMap:
					tile_data = collider.get_cell_tile_data(0, map_position) # Assuming your tiles are on layer 0
				else:
					tile_data = collider.get_cell_tile_data(map_position)
				
				# Read the custom data we set up
				if tile_data and tile_data.get_custom_data("is_slow_tile"):
					speed_multiplier = 0.4 # Reduces speed to 40%
					break # We found a slow tile, stop checking other collisions
	# ---------------------------

	# Apply Horizontal Acceleration and Deceleration with the new multiplier
	if direction != 0:
		var target_speed = direction * (MAX_SPEED * speed_multiplier)
		velocity.x = move_toward(velocity.x, target_speed, current_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)

	move_and_slide()
