extends Node2D

# ------------------------------------------------------------------ constants
const PLAYER_MAX_HP   := 100.0
const CONTACT_DPS     := 15.0
const HP_BAR_W        := 200.0

const ENEMY_SPEED     := 75.0
const ENEMY_MAX_HP    := 60.0
const SPAWN_INTERVAL  := 2.0
const SPAWN_DIST      := 550.0

# ------------------------------------------------------------------ boss constants
const BOSS_MAX_HP         := 300.0
const BOSS_SPEED          := 50.0
const BOSS_CONTACT_DPS    := 30.0
const BOSS_SHOOT_INTERVAL := 2.5
const BOSS_PROJ_SPEED     := 200.0
const BOSS_PROJ_DAMAGE    := 20.0
const BOSS_PROJ_LIFETIME  := 4.0

# ------------------------------------------------------------------ upgradeable stats
var _player_speed  := 220.0
var _damage_radius := 120.0
var _radius_dps    := 25.0

# ------------------------------------------------------------------ player state
var _player: CharacterBody2D
var _player_hp := PLAYER_MAX_HP
var _dead      := false

# ------------------------------------------------------------------ XP / levelling
var _xp        := 0
var _xp_needed := 5
var _level     := 1
var _leveling_up       := false
var _level_up_canvas: CanvasLayer

# ------------------------------------------------------------------ enemies
var _enemies: Array    = []
var _spawn_timer       := 0.0
var _spawn_count       := 1
var _spawn_interval    := SPAWN_INTERVAL

# ------------------------------------------------------------------ boss / projectiles
var _boss_pending  := false
var _projectiles: Array = []

# ------------------------------------------------------------------ UI refs
var _ui_canvas: CanvasLayer
var _hp_bar_fg: ColorRect
var _xp_bar_fg: ColorRect
var _level_label: Label

# ================================================================== lifecycle

func _ready() -> void:
	_setup_player()
	_setup_ui()

func _physics_process(delta: float) -> void:
	if _dead or _leveling_up:
		return
	queue_redraw()
	_move_player()
	_tick_enemies(delta)
	_tick_projectiles(delta)
	_update_ui()

func _draw() -> void:
	_draw_background()
	if _player != null:
		draw_circle(_player.position, _damage_radius, Color(0.35, 0.65, 1.0, 0.08))
		draw_arc(_player.position, _damage_radius, 0.0, TAU, 64,
				Color(0.45, 0.75, 1.0, 0.5), 1.5)
	for p in _projectiles:
		draw_circle(p["pos"], 8.0, Color(1.0, 0.5, 0.0, 0.55))
		draw_circle(p["pos"], 4.0, Color(1.0, 0.85, 0.2, 1.0))

func _draw_background() -> void:
	var size := 5000.0
	var cell := 64.0
	draw_rect(Rect2(-size, -size, size * 2.0, size * 2.0), Color(0.17, 0.38, 0.17))
	var steps := int(size / cell)
	var lc    := Color(0.13, 0.30, 0.13)
	for i in range(-steps, steps + 1):
		var v := i * cell
		draw_line(Vector2(v, -size), Vector2(v,  size), lc, 1.0)
		draw_line(Vector2(-size, v), Vector2(size, v),  lc, 1.0)

# ================================================================== player

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
	cam.position_smoothing_speed   = 8.0
	_player.add_child(cam)

	add_child(_player)

func _move_player() -> void:
	var x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
	x -= float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var y := float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	y -= float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var dir := Vector2(x, y)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		_player.rotation = dir.angle() + PI / 2.0
	_player.velocity = dir * _player_speed
	_player.move_and_slide()

# ================================================================== enemies

func _spawn_enemy() -> void:
	var angle := randf_range(0.0, TAU)
	var pos   := _player.position + Vector2(cos(angle), sin(angle)) * SPAWN_DIST

	var enemy := CharacterBody2D.new()
	enemy.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	enemy.position    = pos

	var shape := CircleShape2D.new()
	shape.radius = 14.0
	var col := CollisionShape2D.new()
	col.shape = shape
	enemy.add_child(col)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(10, 10), Vector2(0, 2), Vector2(-10, 10)
	])
	body.color = Color(0.85, 0.22, 0.22, 1.0)
	enemy.add_child(body)

	var hb_bg := ColorRect.new()
	hb_bg.color    = Color(0.15, 0.15, 0.15, 0.85)
	hb_bg.size     = Vector2(28.0, 4.0)
	hb_bg.position = Vector2(-14.0, -24.0)
	enemy.add_child(hb_bg)

	var hb_fg := ColorRect.new()
	hb_fg.color    = Color(0.9, 0.25, 0.25, 1.0)
	hb_fg.size     = Vector2(28.0, 4.0)
	hb_fg.position = Vector2(-14.0, -24.0)
	enemy.add_child(hb_fg)

	add_child(enemy)
	_enemies.append({
		"node": enemy, "body": body, "hp": ENEMY_MAX_HP, "hb_fg": hb_fg,
		"is_boss": false, "hb_w": 28.0, "max_hp": ENEMY_MAX_HP,
		"contact_dps": CONTACT_DPS, "shoot_timer": 0.0
	})

func _spawn_boss() -> void:
	var angle := randf_range(0.0, TAU)
	var pos   := _player.position + Vector2(cos(angle), sin(angle)) * SPAWN_DIST

	var enemy := CharacterBody2D.new()
	enemy.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	enemy.position    = pos

	var shape := CircleShape2D.new()
	shape.radius = 22.0
	var col := CollisionShape2D.new()
	col.shape = shape
	enemy.add_child(col)

	var shadow := Polygon2D.new()
	shadow.position = Vector2(4, 5)
	shadow.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(16, 0), Vector2(10, 16), Vector2(0, 6),
		Vector2(-10, 16), Vector2(-16, 0)
	])
	shadow.color = Color(0, 0, 0, 0.35)
	enemy.add_child(shadow)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(16, 0), Vector2(10, 16), Vector2(0, 6),
		Vector2(-10, 16), Vector2(-16, 0)
	])
	body.color = Color(1.0, 0.45, 0.0, 1.0)
	enemy.add_child(body)

	var hb_bg := ColorRect.new()
	hb_bg.color    = Color(0.15, 0.15, 0.15, 0.85)
	hb_bg.size     = Vector2(60.0, 6.0)
	hb_bg.position = Vector2(-30.0, -36.0)
	enemy.add_child(hb_bg)

	var hb_fg := ColorRect.new()
	hb_fg.color    = Color(1.0, 0.5, 0.1, 1.0)
	hb_fg.size     = Vector2(60.0, 6.0)
	hb_fg.position = Vector2(-30.0, -36.0)
	enemy.add_child(hb_fg)

	var lbl := Label.new()
	lbl.text = "BOSS"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	lbl.position = Vector2(-12.0, -50.0)
	enemy.add_child(lbl)

	add_child(enemy)
	_enemies.append({
		"node": enemy, "body": body, "hp": BOSS_MAX_HP, "hb_fg": hb_fg,
		"is_boss": true, "hb_w": 60.0, "max_hp": BOSS_MAX_HP,
		"contact_dps": BOSS_CONTACT_DPS, "shoot_timer": 0.0
	})

func _tick_enemies(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		for i in _spawn_count:
			_spawn_enemy()

	var pp      := _player.position
	var to_kill := []

	for e in _enemies:
		var node: CharacterBody2D = e["node"]
		var dist := node.position.distance_to(pp)
		var dir  := (pp - node.position).normalized()

		var speed := BOSS_SPEED if e["is_boss"] else ENEMY_SPEED
		node.velocity = dir * speed
		node.move_and_slide()
		(e["body"] as Polygon2D).rotation = dir.angle() + PI / 2.0

		if dist <= _damage_radius:
			e["hp"] -= _radius_dps * delta

		var contact_r := 40.0 if e["is_boss"] else 34.0
		if dist <= contact_r:
			_player_hp = maxf(_player_hp - e["contact_dps"] * delta, 0.0)

		(e["hb_fg"] as ColorRect).size.x = e["hb_w"] * maxf(e["hp"] / e["max_hp"], 0.0)

		if e["is_boss"]:
			e["shoot_timer"] += delta
			if e["shoot_timer"] >= BOSS_SHOOT_INTERVAL:
				e["shoot_timer"] = 0.0
				_fire_projectile(node.position, dir)

		if e["hp"] <= 0.0:
			to_kill.append(e)

	for e in to_kill:
		(e["node"] as Node).queue_free()
		_enemies.erase(e)
		_gain_xp()

	if _player_hp <= 0.0:
		_on_player_dead()

# ================================================================== boss projectiles

func _fire_projectile(from: Vector2, dir: Vector2) -> void:
	_projectiles.append({"pos": from, "vel": dir * BOSS_PROJ_SPEED, "life": BOSS_PROJ_LIFETIME})

func _tick_projectiles(delta: float) -> void:
	if _player == null:
		return
	var pp      := _player.position
	var to_kill := []
	for p in _projectiles:
		p["pos"]  += p["vel"] * delta
		p["life"] -= delta
		if p["life"] <= 0.0:
			to_kill.append(p)
			continue
		if p["pos"].distance_to(pp) <= 22.0:
			_player_hp = maxf(_player_hp - BOSS_PROJ_DAMAGE, 0.0)
			to_kill.append(p)
	for p in to_kill:
		_projectiles.erase(p)

# ================================================================== XP / levelling

func _gain_xp() -> void:
	_xp += 1
	if _xp >= _xp_needed:
		_xp            -= _xp_needed
		_xp_needed      = int(ceil(_xp_needed * 1.5))
		_level         += 1
		_spawn_count    = ceili(_level / 2.0)
		_spawn_interval = maxf(0.5, SPAWN_INTERVAL - (_level - 1) * 0.1)
		if _level % 5 == 0:
			_boss_pending = true
		_show_level_up_screen()

func _show_level_up_screen() -> void:
	_leveling_up    = true
	_level_up_canvas = CanvasLayer.new()
	add_child(_level_up_canvas)

	var vp := get_viewport().get_visible_rect().size

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.size  = vp
	_level_up_canvas.add_child(overlay)

	var title := Label.new()
	title.text = "LEVEL UP!   (Level %d)" % _level
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.position = Vector2(vp.x * 0.5 - 220.0, vp.y * 0.28)
	_level_up_canvas.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose an upgrade"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	subtitle.position = Vector2(vp.x * 0.5 - 100.0, vp.y * 0.28 + 56.0)
	_level_up_canvas.add_child(subtitle)

	if _boss_pending:
		var warn := Label.new()
		warn.text = "!! BOSS INCOMING !!"
		warn.add_theme_font_size_override("font_size", 18)
		warn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.0))
		warn.position = Vector2(vp.x * 0.5 - 110.0, vp.y * 0.28 + 88.0)
		_level_up_canvas.add_child(warn)

	var choices := [
		["Bigger Radius", "+25% damage radius size", "radius"],
		["More Damage",   "+30% damage per second",  "damage"],
		["Speed Boost",   "+20% movement speed",     "speed"],
	]

	var card_w := 190.0
	var card_h := 110.0
	var gap    := 28.0
	var ox     := (vp.x - (card_w * 3.0 + gap * 2.0)) * 0.5
	var oy     := vp.y * 0.5 - card_h * 0.5 + 20.0

	for i in 3:
		var c      = choices[i]
		var btn    := Button.new()
		btn.text   = c[0] + "\n\n" + c[1]
		btn.size   = Vector2(card_w, card_h)
		btn.position = Vector2(ox + i * (card_w + gap), oy)
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(_apply_upgrade.bind(c[2]))
		_level_up_canvas.add_child(btn)

func _apply_upgrade(id: String) -> void:
	match id:
		"radius": _damage_radius *= 1.25
		"damage": _radius_dps    *= 1.30
		"speed":  _player_speed  *= 1.20
	_level_up_canvas.queue_free()
	_level_up_canvas = null
	_leveling_up     = false
	if _boss_pending:
		_boss_pending = false
		_spawn_boss()
	queue_redraw()

# ================================================================== UI

func _setup_ui() -> void:
	_ui_canvas = CanvasLayer.new()
	add_child(_ui_canvas)

	# HP bar background
	var hp_bg := ColorRect.new()
	hp_bg.color    = Color(0.12, 0.12, 0.12, 0.9)
	hp_bg.size     = Vector2(HP_BAR_W + 4.0, 20.0)
	hp_bg.position = Vector2(16.0, 16.0)
	_ui_canvas.add_child(hp_bg)

	_hp_bar_fg          = ColorRect.new()
	_hp_bar_fg.size     = Vector2(HP_BAR_W, 16.0)
	_hp_bar_fg.position = Vector2(18.0, 18.0)
	_ui_canvas.add_child(_hp_bar_fg)

	var hp_lbl := Label.new()
	hp_lbl.text = "HP"
	hp_lbl.add_theme_font_size_override("font_size", 11)
	hp_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	hp_lbl.position = Vector2(18.0, 19.0)
	_ui_canvas.add_child(hp_lbl)

	# XP bar background
	var xp_bg := ColorRect.new()
	xp_bg.color    = Color(0.12, 0.12, 0.12, 0.9)
	xp_bg.size     = Vector2(HP_BAR_W + 4.0, 14.0)
	xp_bg.position = Vector2(16.0, 42.0)
	_ui_canvas.add_child(xp_bg)

	_xp_bar_fg          = ColorRect.new()
	_xp_bar_fg.color    = Color(0.9, 0.78, 0.1, 1.0)
	_xp_bar_fg.size     = Vector2(0.0, 10.0)
	_xp_bar_fg.position = Vector2(18.0, 44.0)
	_ui_canvas.add_child(_xp_bar_fg)

	var xp_lbl := Label.new()
	xp_lbl.text = "XP"
	xp_lbl.add_theme_font_size_override("font_size", 10)
	xp_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	xp_lbl.position = Vector2(18.0, 44.0)
	_ui_canvas.add_child(xp_lbl)

	# Level label
	_level_label          = Label.new()
	_level_label.text     = "Lv. 1"
	_level_label.add_theme_font_size_override("font_size", 13)
	_level_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	_level_label.position = Vector2(HP_BAR_W + 24.0, 40.0)
	_ui_canvas.add_child(_level_label)

func _update_ui() -> void:
	# HP bar colour: green → yellow → red
	var hp_ratio   := _player_hp / PLAYER_MAX_HP
	var green      := Color(0.2, 0.85, 0.3)
	var yellow     := Color(0.9, 0.85, 0.2)
	var red        := Color(0.85, 0.2, 0.2)
	_hp_bar_fg.size.x = HP_BAR_W * hp_ratio
	if hp_ratio > 0.5:
		_hp_bar_fg.color = yellow.lerp(green, (hp_ratio - 0.5) * 2.0)
	else:
		_hp_bar_fg.color = red.lerp(yellow, hp_ratio * 2.0)

	# XP bar
	_xp_bar_fg.size.x  = HP_BAR_W * (float(_xp) / float(_xp_needed))
	_level_label.text  = "Lv. %d" % _level

# ================================================================== game over

func _on_player_dead() -> void:
	_dead   = true
	_player.queue_free()
	_player = null
	_projectiles.clear()
	var lbl := Label.new()
	lbl.text = "YOU DIED"
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15))
	var vp   := get_viewport().get_visible_rect().size
	lbl.position = Vector2(vp.x * 0.5 - 160.0, vp.y * 0.5 - 40.0)
	_ui_canvas.add_child(lbl)
