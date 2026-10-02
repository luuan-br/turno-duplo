extends Node2D
## Ato 4, Fase 2 — "A Perseguição" (docs/ROTEIRO.md). Primeiro confronto
## direto com Wade "Ghost" Calloway — paga a rivalidade plantada sem
## rosto no Turno 4 do Ato 2 e nomeada no Ato 3. Resolve DUAS pendências
## registradas na Seção 8 do GDD de uma vez: "atirar dirigindo" (mira
## automática — cone à frente do carro, sem apontar manual, como o GDD
## já define) e "múltiplas formas de encerrar perseguição" (aqui:
## atirar no pneu OU bater até o carro quebrar — dano acumulado, não só
## PIT). Ghost absorve mais dano que o fugitivo comum do Turno 4: é pra
## ser um adversário de verdade, não um reaproveitamento 1:1.

const TRACK_SIZE := Vector2(900.0, 500.0)
const TRACK_ORIGIN := Vector2(60.0, 40.0)
const WALL_THICK := 20.0

const MAX_SPEED := 200.0
const ACCEL := 230.0
const BRAKE_DECEL := 420.0
const REVERSE_SPEED := 100.0
const COAST_DECEL := 90.0
const TURN_RATE := 2.6
const STEER_DEADZONE := 0.2

const GHOST_SPEED := 175.0
const GHOST_DAMAGE_MAX := 3
const RAM_COOLDOWN := 0.6
const FIRE_CONE_RANGE := 220.0
const FIRE_CONE_DOT := 0.92

var player_car: CharacterBody2D
var player_speed := 0.0

var ghost_car: CharacterBody2D
var _waypoints: Array[Vector2] = []
var _wp_index := 0
var ghost_damage := 0
var ghost_defeated := false
var ghost_spinning := false
var _spin_timer := 0.0
var _ram_cooldown := 0.0

var accel_btn: Control
var brake_btn: Control
var fire_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> chase -> outro -> done

var _fire_target_valid := false

const SCENE_PATH := "res://missions/ato4_fase2_perseguicao.tscn"


func _ready() -> void:
	_build_track()
	_build_player_car()
	_build_ghost_car()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"Um carro sai em disparada do fim do Cais no instante em que o segundo guarda cai — alguém avisou alguém, em algum lugar.",
			"Theo reconhece o jeito de dirigir antes mesmo da placa. \"É ele. É o Ghost.\"",
			"Pela primeira vez, Mark vai atrás de um nome, não de uma sombra.",
		],
		["", "Theo Marsh", ""]
	)


func _build_track() -> void:
	var top := TRACK_ORIGIN
	var w := TRACK_SIZE.x
	var h := TRACK_SIZE.y
	var rects: Array[Rect2] = [
		Rect2(top, Vector2(w, WALL_THICK)),
		Rect2(Vector2(top.x, top.y + h - WALL_THICK), Vector2(w, WALL_THICK)),
		Rect2(top, Vector2(WALL_THICK, h)),
		Rect2(Vector2(top.x + w - WALL_THICK, top.y), Vector2(WALL_THICK, h)),
	]
	for r in rects:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = r.size
		shape.shape = rect_shape
		shape.position = r.size * 0.5
		body.add_child(shape)
		body.position = r.position
		add_child(body)

		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2.ZERO, Vector2(r.size.x, 0), r.size, Vector2(0, r.size.y)])
		poly.color = Color(0.14, 0.14, 0.18)
		poly.position = r.position
		add_child(poly)

	_waypoints = [
		top + Vector2(120, 100),
		top + Vector2(w - 120, 90),
		top + Vector2(w - 100, h - 110),
		top + Vector2(380, h - 90),
		top + Vector2(120, h - 250),
	]


func _build_player_car() -> void:
	player_car = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 16)
	shape.shape = rect
	player_car.add_child(shape)
	player_car.position = TRACK_ORIGIN + Vector2(80, 80)
	add_child(player_car)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player_car.add_child(camera)


func _build_ghost_car() -> void:
	ghost_car = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 16)
	shape.shape = rect
	ghost_car.add_child(shape)
	ghost_car.position = _waypoints[0]
	add_child(ghost_car)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(16, 16)
	status_label.add_theme_font_size_override("font_size", 17)
	layer.add_child(status_label)

	var back := Button.new()
	back.text = tr("< Menu")
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_top = -60
	back.offset_bottom = -10
	back.offset_left = 16
	back.offset_right = 130
	layer.add_child(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://sandbox/menu.tscn"))

	next_btn = Button.new()
	next_btn.text = tr("Próxima Fase >")
	next_btn.anchor_top = 1.0
	next_btn.anchor_bottom = 1.0
	next_btn.anchor_right = 1.0
	next_btn.offset_top = -60
	next_btn.offset_bottom = -10
	next_btn.offset_right = -16
	next_btn.offset_left = -200
	next_btn.visible = false
	layer.add_child(next_btn)
	next_btn.pressed.connect(func(): MissionFlow.advance(SCENE_PATH))


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var stick := Control.new()
	stick.set_script(load("res://ui/virtual_joystick.gd"))
	stick.anchor_left = 0.0
	stick.anchor_right = 0.55
	stick.anchor_top = 0.0
	stick.anchor_bottom = 1.0
	layer.add_child(stick)

	accel_btn = _corner_button("accelerate", tr("ACELERAR"), 30, 30, 110, 110)
	layer.add_child(accel_btn)

	brake_btn = _corner_button("brake", tr("FREAR"), 160, 40, 100, 100)
	layer.add_child(brake_btn)

	fire_btn = _corner_button("shoot", tr("ATIRAR\nNO PNEU"), 30, 160, 110, 110)
	fire_btn.visible = false
	layer.add_child(fire_btn)


func _corner_button(action: String, label: String, right: float, bottom: float, w: float, h: float) -> Control:
	var btn := Control.new()
	btn.set_script(load("res://ui/contextual_button.gd"))
	btn.action_name = action
	btn.label_text = label
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_right = -right
	btn.offset_left = -right - w
	btn.offset_bottom = -bottom
	btn.offset_top = -bottom - h
	return btn


func _build_story_box() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	story = Control.new()
	story.set_script(load("res://ui/story_box.gd"))
	layer.add_child(story)
	story.finished.connect(_on_story_finished)


func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "chase"
			_controls_locked = false
		"outro":
			_phase = "done"
			next_btn.visible = true


func _check_ghost_defeated() -> void:
	if ghost_defeated or ghost_damage < GHOST_DAMAGE_MAX or _phase != "chase":
		return
	ghost_defeated = true
	ghost_spinning = true
	_spin_timer = 1.2
	_phase = "outro"
	_controls_locked = true
	story.say(
		[
			"O carro do Ghost derrapa, bate de lado no guard-rail e para torto, fumaça saindo do capô.",
			"Ele sai mancando, mãos já no alto antes mesmo do Mark gritar pra parar — profissional até no jeito de se render.",
			"\"Bonito trabalho\", ele diz, sem ironia nenhuma. \"Faz tempo que ninguém me pega.\"",
			"Não é o fim da operação de Kessler. Mas é a primeira peça que sai do tabuleiro dele.",
			"Fim da Fase 2 — A Perseguição.",
		],
		["", "Wade \"Ghost\" Calloway", "Wade \"Ghost\" Calloway", "", ""]
	)


func _process(delta: float) -> void:
	_update_drive_buttons()
	if not _controls_locked:
		_drive_player(delta)
	if _phase == "chase":
		_drive_ghost(delta)
		_try_ram()
		_check_fire_cone()
	if _ram_cooldown > 0.0:
		_ram_cooldown -= delta
	_update_hud()
	queue_redraw()


func _update_drive_buttons() -> void:
	accel_btn.visible = not _controls_locked
	brake_btn.visible = not _controls_locked


func _drive_player(delta: float) -> void:
	var accelerating := InputBridge.is_held("accelerate")
	var braking := InputBridge.is_held("brake")

	if accelerating and not braking:
		player_speed = move_toward(player_speed, MAX_SPEED, ACCEL * delta)
	elif braking:
		if player_speed > 0.0:
			player_speed = move_toward(player_speed, 0.0, BRAKE_DECEL * delta)
		else:
			player_speed = move_toward(player_speed, -REVERSE_SPEED, ACCEL * delta)
	else:
		player_speed = move_toward(player_speed, 0.0, COAST_DECEL * delta)

	player_speed = clamp(player_speed, -REVERSE_SPEED, MAX_SPEED)

	if InputBridge.move_vector.length() >= STEER_DEADZONE and absf(player_speed) > 5.0:
		var desired_angle := InputBridge.move_vector.angle()
		var diff := wrapf(desired_angle - player_car.rotation, -PI, PI)
		var speed_factor: float = clamp(absf(player_speed) / MAX_SPEED, 0.35, 1.0)
		var max_step: float = TURN_RATE * speed_factor * delta
		player_car.rotation += clamp(diff, -max_step, max_step)

	player_car.velocity = Vector2.RIGHT.rotated(player_car.rotation) * player_speed
	player_car.move_and_slide()


func _drive_ghost(delta: float) -> void:
	if ghost_spinning:
		_spin_timer -= delta
		ghost_car.rotation += 5.0 * delta
		ghost_car.velocity = Vector2.ZERO
		ghost_car.move_and_slide()
		return
	if ghost_defeated:
		return

	var dest: Vector2 = _waypoints[_wp_index]
	var to_dest := dest - ghost_car.position
	if to_dest.length() < 14.0:
		_wp_index = (_wp_index + 1) % _waypoints.size()
		dest = _waypoints[_wp_index]
		to_dest = dest - ghost_car.position

	ghost_car.rotation = to_dest.angle()
	ghost_car.velocity = to_dest.normalized() * GHOST_SPEED
	ghost_car.move_and_slide()


func _try_ram() -> void:
	if ghost_defeated or ghost_spinning or _ram_cooldown > 0.0:
		return
	for i in player_car.get_slide_collision_count():
		if player_car.get_slide_collision(i).get_collider() == ghost_car:
			ghost_damage += 1
			_ram_cooldown = RAM_COOLDOWN
			_check_ghost_defeated()
			return


func _check_fire_cone() -> void:
	if ghost_defeated or ghost_spinning:
		fire_btn.visible = false
		return

	var to_ghost := ghost_car.position - player_car.position
	var dist := to_ghost.length()
	var facing := Vector2.RIGHT.rotated(player_car.rotation)
	var dot := facing.dot(to_ghost.normalized()) if dist > 0.01 else 0.0

	_fire_target_valid = dist <= FIRE_CONE_RANGE and dot >= FIRE_CONE_DOT
	fire_btn.visible = _fire_target_valid

	if _fire_target_valid and InputBridge.consume_just_pressed("shoot"):
		ghost_damage += 2
		_check_ghost_defeated()


func _update_hud() -> void:
	match _phase:
		"chase":
			status_label.text = tr("Bata nele ou alinhe o carro à frente e ATIRE NO PNEU. Dano: %d/%d") % [ghost_damage, GHOST_DAMAGE_MAX]
		"done":
			status_label.text = tr("Fase 2 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player_car:
		_draw_car(player_car.position, player_car.rotation, Color(0.3, 0.6, 0.9))
		if _phase == "chase" and _fire_target_valid:
			var facing := Vector2.RIGHT.rotated(player_car.rotation)
			draw_dashed_line(player_car.position, player_car.position + facing * FIRE_CONE_RANGE, Color(1.0, 0.3, 0.3, 0.6), 2.0, 8.0)
	if ghost_car:
		_draw_car(ghost_car.position, ghost_car.rotation, Color(0.5, 0.5, 0.5) if ghost_defeated else Color(0.15, 0.15, 0.15))


func _draw_car(pos: Vector2, rot: float, color: Color) -> void:
	var half := Vector2(14, 8)
	var points := PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)
	])
	for i in points.size():
		points[i] = pos + points[i].rotated(rot)
	draw_colored_polygon(points, color)
	draw_line(pos, pos + Vector2.RIGHT.rotated(rot) * 20.0, Color.WHITE, 2.0)
