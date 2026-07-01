extends CharacterBody2D

# Movement constants
const MAX_SPEED = 150.0
const ACCELERATION = 800.0 
const FRICTION = 500.0 
const AIR_ACCELERATION = 400.0 
const AIR_FRICTION = 1000.0 
const JUMP_VELOCITY = -400.0
const WALL_JUMP_PUSHBACK = 150.0 # Horizontal force applied when jumping from a wall

# Node references
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Game state
@export var respawn_coordinate := Vector2(40, 40)

func die() -> void:
	# Reset position and momentum when dead
	global_position = respawn_coordinate
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var speed_multiplier := 1.0 
	var is_sliding := false
	var is_dead := false 
	
	# Process tile-specific mechanics (death, slide, slow)
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
				if tile_data.get_custom_data("is_death_tile"):
					is_dead = true
					break 
				
				if is_on_floor() and collision.get_normal().y < 0:
					if tile_data.get_custom_data("is_slide_tile"):
						is_sliding = true
					elif tile_data.get_custom_data("is_slow_tile"):
						speed_multiplier = 0.4 # Reduce target speed by 60%
	
	# Execute death penalty and abort movement frameand respawn
	if is_dead:
		die()
		move_and_slide() 
		return 

	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle floor and wall jumps
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall_only():
			var wall_normal = get_wall_normal()
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_normal.x * WALL_JUMP_PUSHBACK
		
	# Enable variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# Get input direction
	var direction := Input.get_axis("move_left", "move_right")
	
	# Update sprite orientation
	if is_on_wall_only():
		animated_sprite_2d.flip_h = get_wall_normal().x > 0
	else:
		if direction > 0:
			animated_sprite_2d.flip_h = false
		elif direction < 0:
			animated_sprite_2d.flip_h = true
		
	# Update animation state
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	elif is_on_wall_only():
		animated_sprite_2d.play("wall_jump")
	else:
		animated_sprite_2d.play("jump")
	
	# Set drag for acceleration and air control
	var current_accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
	var current_friction = FRICTION if is_on_floor() else AIR_FRICTION

	# Override input for ice/sliding tiles
	if is_sliding:
		direction = 0 
		current_friction = 0 
		if velocity.x == 0:
			velocity.x = 50.0 if not animated_sprite_2d.flip_h else -50.0 # Nudge character if stuck

	# Apply horizontal forces
	if direction != 0:
		var target_speed = direction * (MAX_SPEED * speed_multiplier)
		velocity.x = move_toward(velocity.x, target_speed, current_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)

	move_and_slide()
