extends Node2D

const WORLD_SIZE := 4096.0
const CELL := 64.0
const BG_COLOR := Color(0.17, 0.38, 0.17, 1.0)
const LINE_COLOR := Color(0.13, 0.30, 0.13, 1.0)

func _draw() -> void:
	draw_rect(Rect2(-WORLD_SIZE, -WORLD_SIZE, WORLD_SIZE * 2, WORLD_SIZE * 2), BG_COLOR)
	var steps := int(WORLD_SIZE / CELL)
	for i in range(-steps, steps + 1):
		var v := i * CELL
		draw_line(Vector2(v, -WORLD_SIZE), Vector2(v, WORLD_SIZE), LINE_COLOR, 1.0)
		draw_line(Vector2(-WORLD_SIZE, v), Vector2(WORLD_SIZE, v), LINE_COLOR, 1.0)
