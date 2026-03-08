extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# 1. This prints exactly what touched the coin to the Output console
	print("Something touched the coin! It was: ", body.name)
	
	# 2. Check the group
	if body.is_in_group("Player"):
		print("It is the player! Deleting coin...")
		queue_free()
