extends Area2D

# Node references
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _on_body_entered(body: Node2D) -> void:
	if not body:
		return
		
	if body.is_in_group("Player"):
		# Prevent double collection
		collision_shape.set_deferred("disabled", true)
		
		# Play visual effect before despawning
		animated_sprite.play("disappear")
		await animated_sprite.animation_finished
		queue_free()
