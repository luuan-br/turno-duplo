extends Node2D
## Ato 4, Fase 5 — "O Cofre" (docs/ROTEIRO.md). Breach & clear final
## contra o músculo de apoio de Kessler, seguido de um trecho de fuga
## atirando enquanto dirige — a **fusão tático+perseguição** que ficava
## registrada como pendência desde o início do projeto (GDD Seção 8,
## "Prototipar a fusão tático+perseguição... só existe no papel"). Usa a
## mesma mira automática criada na Fase 2 (cone, sem apontar manual),
## só que virada pra TRÁS: aqui não é o jogador caçando, é o jogador
## sendo caçado por um reforço de Kessler na saída.

const ROOM_SIZE := Vector2(460.0, 380.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0
const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const FIRE_RANGE := 900.0

const TRACK_SIZE := Vector2(820.0, 300.0)
const TRACK_ORIGIN := Vector2(80.0, 520.0)
const MAX_SPEED := 190.0
const ACCEL := 220.0
const BRAKE_DECEL := 400.0
const REVERSE_SPEED := 90.0
const COAST_DECEL := 90.0
const TURN_RATE := 2.6
const STEER_DEADZONE := 0.2
const PURSUER_SPEED := 150.0
const PURSUER_DAMAGE_MAX := 2
const REAR_CONE_RANGE := 220.0
const REAR_CONE_DOT := 0.9

var player: CharacterBody2D
var player_camera: Camera2D
var threat_a: Area2D
var threat_a_hit := false
var threat_b: Area2D
var threat_b_hit := false
var vault_obj: Area2D
var _vault_opened := false

var _facing := Vector2.RIGHT
const FACING_TURN_SPEED_AIMING := 9.0

var player_car: CharacterBody2D
var player_speed := 0.0
var pursuer_car: CharacterBody2D
var pursuer_damage := 0
var pursuer_defeated := false
var escape_finish: Node2D
var _fire_target_valid := false

var left_stick: Control
var right_stick: Control
var breach_btn: Control
var fire_btn: Control
var open_btn: Control
var accel_btn: Control
var brake_btn: Control
var rear_fire_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> fight_a -> between -> fight_b -> aftermath -> open -> to_car -> escape -> outro -> done

var _aim_end := Vector2.ZERO
var _aim_hit_threat := false
var _aim_valid := false

const SCENE_PATH := "res://missions/ato4_fase5_cofre.tscn"


func _ready() -> void:
	_build_room()
	_build_player()
	_build_threats()
	_build_vault()
	_build_track()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"A porta do cofre já está entreaberta — Kessler não veio buscar dinheiro, veio buscar tempo. Documentos, servidores, provas.",
			"Dois homens cobrem a sala principal. Essa é a última barreira antes do que quer que o Kessler esteja levando embora.",
		],
		["", ""]
	)


func _build_room() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(w, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + h - WALL_THICK), Vector2(w, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, h)),
		Rect2(Vector2(o.x + w - WALL_THICK, o.y), Vector2(WALL_THICK, h)),
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
		poly.color = Color(0.2, 0.19, 0.16)
		poly.position = r.position
		add_child(poly)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 70)
	add_child(player)

	player_camera = Camera2D.new()
	player_camera.enabled = true
	player_camera.position_smoothing_enabled = true
	player_camera.position_smoothing_speed = 5.0
	player.add_child(player_camera)


func _build_threats() -> void:
	threat_a = Area2D.new()
	var s1 := CollisionShape2D.new()
	var c1 := CircleShape2D.new()
	c1.radius = 15.0
	s1.shape = c1
	threat_a.add_child(s1)
	threat_a.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.3, ROOM_SIZE.y * 0.25)
	threat_a.monitorable = true
	add_child(threat_a)

	threat_b = Area2D.new()
	var s2 := CollisionShape2D.new()
	var c2 := CircleShape2D.new()
	c2.radius = 15.0
	s2.shape = c2
	threat_b.add_child(s2)
	threat_b.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.75, ROOM_SIZE.y * 0.6)
	threat_b.monitorable = true
	add_child(threat_b)


func _build_vault() -> void:
	vault_obj = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	vault_obj.add_child(shape)
	vault_obj.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x - 80, ROOM_SIZE.y - 100)
	vault_obj.monitorable = true
	add_child(vault_obj)


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

	escape_finish = Node2D.new()
	escape_finish.position = top + Vector2(w - 70, h * 0.5)
	add_child(escape_finish)


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

	left_stick = Control.new()
	left_stick.set_script(load("res://ui/virtual_joystick.gd"))
	left_stick.anchor_left = 0.0
	left_stick.anchor_right = 0.5
	left_stick.anchor_top = 0.0
	left_stick.anchor_bottom = 1.0
	layer.add_child(left_stick)

	right_stick = Control.new()
	right_stick.set_script(load("res://ui/virtual_joystick.gd"))
	right_stick.right_stick = true
	right_stick.anchor_left = 0.5
	right_stick.anchor_right = 1.0
	right_stick.anchor_top = 0.0
	right_stick.anchor_bottom = 1.0
	layer.add_child(right_stick)

	breach_btn = _corner_button("breach", tr("ARROMBAR"), 30.0, 180.0, 100.0, 100.0)
	breach_btn.show_hold_progress = true
	breach_btn.visible = false
	layer.add_child(breach_btn)

	fire_btn = _corner_button("shoot", tr("ATIRAR"), 30.0, 180.0, 100.0, 100.0)
	fire_btn.visible = false
	layer.add_child(fire_btn)

	open_btn = _corner_button("open_vault", tr("ABRIR\nCOFRE"), 30.0, 180.0, 100.0, 100.0)
	open_btn.show_hold_progress = true
	open_btn.visible = false
	layer.add_child(open_btn)

	accel_btn = _corner_button("accelerate", tr("ACELERAR"), 30, 30, 110, 110)
	accel_btn.visible = false
	layer.add_child(accel_btn)

	brake_btn = _corner_button("brake", tr("FREAR"), 160, 40, 100, 100)
	brake_btn.visible = false
	layer.add_child(brake_btn)

	rear_fire_btn = _corner_button("rear_shoot", tr("ATIRAR\nPRA TRÁS"), 30, 160, 110, 110)
	rear_fire_btn.visible = false
	layer.add_child(rear_fire_btn)


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
			_phase = "fight_a"
			_controls_locked = false
		"between":
			_phase = "fight_b"
			_controls_locked = false
		"aftermath":
			_phase = "open"
			_controls_locked = false
		"to_car":
			_phase = "escape"
			_controls_locked = false
		"outro":
			_phase = "done"
			next_btn.visible = true


func _check_fire() -> void:
	if _phase != "fight_a" and _phase != "fight_b":
		fire_btn.visible = false
		return
	fire_btn.visible = true

	var active_threat: Area2D = threat_a if _phase == "fight_a" else threat_b

	var space_state := get_world_2d().direct_space_state
	var start := player.position + _facing * (PLAYER_RADIUS + 2.0)
	var query := PhysicsRayQueryParameters2D.create(start, start + _facing * FIRE_RANGE)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	var result := space_state.intersect_ray(query)

	_aim_valid = true
	if result.is_empty():
		_aim_end = start + _facing * FIRE_RANGE
		_aim_hit_threat = false
	else:
		_aim_end = result.position
		_aim_hit_threat = result.collider == active_threat

	if InputBridge.consume_just_pressed("shoot") and not result.is_empty() and result.collider == active_threat:
		if _phase == "fight_a":
			threat_a_hit = true
			_phase = "between"
			_controls_locked = true
			story.say(["Um cai. O outro vira a arma rápido demais — não dá tempo de respirar."], [""])
		else:
			threat_b_hit = true
			_phase = "aftermath"
			_controls_locked = true
			story.say(
				[
					"A sala principal está livre. Mas o cofre de verdade, o de dados e documentos, continua trancado.",
					"É agora ou nunca — Kessler não vai deixar essa prova esperando muito mais.",
				],
				["", ""]
			)


func _check_vault() -> void:
	if _phase != "open" or _vault_opened:
		open_btn.visible = false
		return
	var near := player.position.distance_to(vault_obj.position) < 60.0
	open_btn.visible = near
	if not open_btn.visible:
		return
	if InputBridge.consume_just_released("open_vault"):
		_vault_opened = true
		open_btn.visible = false
		_phase = "to_car"
		_controls_locked = true
		story.say(
			[
				"O cofre abre num estrondo de metal — servidor portátil, pastas, tudo que Kessler ia levar embora pra sumir de vez.",
				"Um alarme dispara em algum canto que ninguém tinha desarmado. Lá fora, motores ligam. Reforço.",
				"\"CORRE PRO CARRO!\", Theo grita de algum lugar atrás.",
			],
			["", "", "Theo Marsh"]
		)


func _process(delta: float) -> void:
	if not _controls_locked and (_phase == "fight_a" or _phase == "fight_b" or _phase == "open"):
		_move_player()
		_update_facing(delta)
	_check_fire()
	_check_vault()

	if _phase == "escape":
		_update_drive_buttons()
		if not _controls_locked:
			_drive_player(delta)
		_drive_pursuer(delta)
		_check_rear_fire()
		_check_escape_finish()

	_update_hud()
	queue_redraw()


func _move_player() -> void:
	player.velocity = InputBridge.move_vector * SPEED_CAUTIOUS
	player.move_and_slide()


func _update_facing(delta: float) -> void:
	if InputBridge.aim_touching and InputBridge.aim_vector.length() > 0.15:
		var target_dir := InputBridge.aim_vector.normalized()
		var diff := wrapf(target_dir.angle() - _facing.angle(), -PI, PI)
		var max_step := FACING_TURN_SPEED_AIMING * delta
		_facing = _facing.rotated(clamp(diff, -max_step, max_step))


# ---------- trecho de fuga de carro ----------

func _spawn_cars() -> void:
	if player_car:
		return
	player_car = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 16)
	shape.shape = rect
	player_car.add_child(shape)
	player_car.position = TRACK_ORIGIN + Vector2(60, TRACK_SIZE.y * 0.5)
	add_child(player_car)

	# Desativa a câmera tática explicitamente antes de ligar a do carro —
	# duas Camera2D com enabled=true ao mesmo tempo nem sempre trocam
	# sozinhas de forma confiável (bug relatado: câmera ficava presa no
	# player tático durante a fuga).
	player_camera.enabled = false

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player_car.add_child(camera)

	pursuer_car = CharacterBody2D.new()
	var shape2 := CollisionShape2D.new()
	var rect2 := RectangleShape2D.new()
	rect2.size = Vector2(28, 16)
	shape2.shape = rect2
	pursuer_car.add_child(shape2)
	# Dentro da pista, atrás do carro do jogador — a posição anterior
	# (TRACK_ORIGIN.x - 20) caía do lado de fora da parede esquerda
	# (parede ocupa até TRACK_ORIGIN.x + WALL_THICK), deixando o
	# perseguidor preso fora do cenário.
	pursuer_car.position = TRACK_ORIGIN + Vector2(WALL_THICK + 25.0, TRACK_SIZE.y * 0.5)
	add_child(pursuer_car)


func _update_drive_buttons() -> void:
	var escaping := _phase == "escape" and not _controls_locked
	accel_btn.visible = escaping
	brake_btn.visible = escaping
	# O manche direito (mira manual) fica embaixo do mesmo canto onde os
	# botões de carro aparecem — escondido durante a fuga pra não disputar
	# toque com ACELERAR/FREAR/ATIRAR PRA TRÁS (mesmo bug de sobreposição
	# já corrigido antes no tático, ver CLAUDE.md).
	right_stick.visible = not escaping
	if not player_car:
		_spawn_cars()


func _drive_player(delta: float) -> void:
	if not player_car:
		return
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


func _drive_pursuer(delta: float) -> void:
	if not pursuer_car or pursuer_defeated or not player_car:
		return
	var to_player := player_car.position - pursuer_car.position
	pursuer_car.rotation = to_player.angle()
	pursuer_car.velocity = to_player.normalized() * PURSUER_SPEED
	pursuer_car.move_and_slide()


func _check_rear_fire() -> void:
	if pursuer_defeated or not player_car or not pursuer_car:
		rear_fire_btn.visible = false
		return

	var rear_facing := -Vector2.RIGHT.rotated(player_car.rotation)
	var to_pursuer := pursuer_car.position - player_car.position
	var dist := to_pursuer.length()
	var dot := rear_facing.dot(to_pursuer.normalized()) if dist > 0.01 else 0.0

	_fire_target_valid = dist <= REAR_CONE_RANGE and dot >= REAR_CONE_DOT
	rear_fire_btn.visible = _fire_target_valid

	if _fire_target_valid and InputBridge.consume_just_pressed("rear_shoot"):
		pursuer_damage += 1
		if pursuer_damage >= PURSUER_DAMAGE_MAX:
			pursuer_defeated = true
			rear_fire_btn.visible = false


func _check_escape_finish() -> void:
	if _phase != "escape" or not player_car:
		return
	if player_car.position.distance_to(escape_finish.position) < 50.0:
		_phase = "outro"
		_controls_locked = true
		accel_btn.visible = false
		brake_btn.visible = false
		rear_fire_btn.visible = false
		if pursuer_defeated:
			story.say(
				[
					"O carro atrás perde o controle e bate na mureta — um obstáculo a menos entre o Mark e o que vem a seguir.",
					"Theo, ofegante, bate na lateral do carro: \"Prova em mãos, perseguidor fora. Falta só o Kessler.\"",
					"Fim da Fase 5 — O Cofre.",
				],
				["", "Theo Marsh", ""]
			)
		else:
			story.say(
				[
					"O carro atrás desiste perto da saída do Cais — reforço demais visível na área, nem Kessler arriscaria tanto por um motorista a menos.",
					"Theo, ofegante: \"A gente tirou a prova. Falta só o Kessler agora.\"",
					"Fim da Fase 5 — O Cofre.",
				],
				["", "Theo Marsh", ""]
			)


func _update_hud() -> void:
	match _phase:
		"fight_a", "fight_b":
			status_label.text = tr("Neutralize a ameaça.")
		"open":
			status_label.text = tr("Objetivo: chegue no cofre e abra.")
		"escape":
			status_label.text = tr("Fuja! Alinhe o carro e ATIRE PRA TRÁS pra deter o perseguidor.")
		"done":
			status_label.text = tr("Fase 5 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if _phase in ["fight_a", "fight_b", "open"] and player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
		if (_phase == "fight_a" or _phase == "fight_b") and _aim_valid:
			var line_color := Color(0.3, 1.0, 0.4, 0.8) if _aim_hit_threat else Color(1.0, 1.0, 1.0, 0.35)
			draw_dashed_line(player.position, _aim_end, line_color, 2.0, 10.0)
			draw_circle(_aim_end, 5.0, line_color)
		else:
			draw_line(player.position, player.position + _facing * (PLAYER_RADIUS + 24.0), Color.WHITE, 3.0)

	if threat_a:
		draw_circle(threat_a.position, 15.0, Color(0.2, 0.2, 0.2) if threat_a_hit else Color(0.8, 0.2, 0.2))
	if threat_b and threat_a_hit:
		draw_circle(threat_b.position, 15.0, Color(0.2, 0.2, 0.2) if threat_b_hit else Color(0.8, 0.2, 0.2))
	if vault_obj and threat_b_hit:
		draw_circle(vault_obj.position, 20.0, Color(0.3, 0.7, 0.4) if _vault_opened else Color(0.85, 0.7, 0.2))

	if player_car:
		_draw_car(player_car.position, player_car.rotation, Color(0.3, 0.6, 0.9))
		if _phase == "escape" and _fire_target_valid:
			var rear_facing := -Vector2.RIGHT.rotated(player_car.rotation)
			draw_dashed_line(player_car.position, player_car.position + rear_facing * REAR_CONE_RANGE, Color(1.0, 0.3, 0.3, 0.6), 2.0, 8.0)
	if pursuer_car and not pursuer_defeated:
		_draw_car(pursuer_car.position, pursuer_car.rotation, Color(0.15, 0.15, 0.15))
	if escape_finish:
		draw_circle(escape_finish.position, 16.0, Color(0.3, 0.8, 0.4, 0.4))


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
