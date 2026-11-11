extends CharacterBody2D

## Movement speed in pixels per second.
@export var speed: float = 180.0


func _physics_process(_delta: float) -> void:
	# Input.get_vector() reads four named actions and returns a normalised Vector2.
	# This handles WASD, arrow keys, and diagonal normalisation automatically.
	var direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)

	velocity = direction * speed
	move_and_slide()
