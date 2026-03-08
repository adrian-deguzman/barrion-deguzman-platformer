extends CharacterBody2D

# Movement constants
const MAX_SPEED = 150.0
const ACCELERATION = 800.0 # How fast the character reaches max speed
const FRICTION = 500.0 # How fast the character slows down to zero
const AIR_ACCELERATION = 400.0 # Slower horizontal movement in the air
const AIR_FRICTION = 1000.0 # Less friction in the air (keeps momentum)
const JUMP_VELOCITY = -400.0
const WALL_JUMP_PUSHBACK = 150.0 # Horizontal force when jumping off a wall

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
			# Get the direction the wall is facing
			var wall_normal = get_wall_normal()
			# Jump up and push away from the wall
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_normal.x * WALL_JUMP_PUSHBACK
		
	# Cut jump short if button is released early (Variable Jump Height)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# Get the input direction
	var direction := Input.get_axis("move_left", "move_right")
	
	# Handle sprite flipping
	if is_on_wall_only():
		# Face away from the wall (depends on normal)
		animated_sprite_2d.flip_h = get_wall_normal().x > 0
	else:
		# Face pressed direction
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
	
	# Apply Horizontal Acceleration and Deceleration
	if direction != 0:
		# Accelerate towards max speed in the chosen direction
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, current_accel * delta)
	else:
		# Decelerate to zero velocity when the button is released
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)

	move_and_slide()
