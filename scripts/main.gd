extends Node2D

const SPEED := 220.0

var _player: CharacterBody2D

func _ready() -> void:
	_setup_player()

func _draw() -> void:
	var size := 5000.0
	var cell := 64.0
	draw_rect(Rect2(-size, -size, size * 2.0, size * 2.0), Color(0.17, 0.38, 0.17))
	var steps := int(size / cell)
	var line_col := Color(0.13, 0.30, 0.13)
	for i in range(-steps, steps + 1):
		var v := i * cell
		draw_line(Vector2(v, -size), Vector2(v, size), line_col, 1.0)
		draw_line(Vector2(-size, v), Vector2(size, v), line_col, 1.0)

func _setup_player() -> void:
	_player = CharacterBody2D.new()
	_player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	var shape := CircleShape2D.new()
	shape.radius = 18.0
	var col := CollisionShape2D.new()
	col.shape = shape
	_player.add_child(col)

	var shadow := Polygon2D.new()
	shadow.position = Vector2(3, 4)
	shadow.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(13, 13), Vector2(0, 4), Vector2(-13, 13)
	])
	shadow.color = Color(0, 0, 0, 0.3)
	_player.add_child(shadow)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(13, 13), Vector2(0, 4), Vector2(-13, 13)
	])
	body.color = Color(0.22, 0.55, 0.95, 1.0)
	_player.add_child(body)

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	_player.add_child(cam)

	add_child(_player)

func _physics_process(_delta: float) -> void:
	if _player == null:
		return
	var x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
	x -= float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var y := float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	y -= float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var dir := Vector2(x, y)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		_player.rotation = dir.angle() + PI / 2.0
	_player.velocity = dir * SPEED
	_player.move_and_slide()
