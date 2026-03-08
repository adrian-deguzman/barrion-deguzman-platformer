extends Area2D

# Grab references to our child nodes
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _on_body_entered(body: Node2D) -> void:
	if not body:
		return
		
	# Check if it's the player
	if body.is_in_group("Player"):
		# 1. Safely turn off the hitbox so it can't be collected twice
		collision_shape.set_deferred("disabled", true)
		
		# 2. Play the new animation
		animated_sprite.play("disappear")
		
		# 3. Pause this specific function until the animation is completely done
		await animated_sprite.animation_finished
		
		# 4. Now safely delete the strawberry
		queue_free()
