extends CharacterBody2D

# Movement constants
const MAX_SPEED = 150.0
const ACCELERATION = 800.0 # How fast the character reaches max speed
const FRICTION = 1000.0 # How fast the character slows down to zero
const JUMP_VELOCITY = -300.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Cut jump short if button is released early (Variable Jump Height)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# Get the input direction
	var direction := Input.get_axis("move_left", "move_right")
	
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
	else:
		animated_sprite_2d.play("jump")
	
	# Apply Horizontal Acceleration and Deceleration
	if direction != 0:
		# Accelerate towards max speed in the chosen direction
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
	else:
		# Decelerate to zero velocity when the button is released
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	move_and_slide()
