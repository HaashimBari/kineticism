extends CharacterBody2D

const SPEED := 220.0

func _physics_process(_delta: float) -> void:
	var x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) \
		   - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var y := float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) \
		   - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var dir := Vector2(x, y)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		rotation = dir.angle() + PI / 2.0
	velocity = dir * SPEED
	move_and_slide()
