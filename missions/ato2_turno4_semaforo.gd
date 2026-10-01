extends Node2D
## Ato 2, Turno 4 — "Semáforo Cego" (docs/ROTEIRO.md). Falha "isolada" de
## semáforo causa um acidente que vira perseguição de carro — primeiro
## PIT maneuver de verdade (fora do treino sem risco da Fase 3). No caos,
## um motorista sem rosto escapa com facilidade suspeita — a primeira
## aparição do Wade "Ghost" Calloway, ainda sem nome (GDD Seção 10):
## tratado como um beat narrado/visual rápido, não uma segunda perseguição
## de verdade, pra não duplicar a mecânica principal do turno.
##
## Reaproveita a física de direção/PIT por contato já validada na Fase 3
## (`missions/ato1_fase3_direcao.gd`) — 3ª cópia desse controlador de
## carro, agora sim bate a "regra dos três" (ver CLAUDE.md): se uma 4ª
## aparecer, vale extrair um componente compartilhado.

const TRACK_SIZE := Vector2(820.0, 460.0)
const TRACK_ORIGIN := Vector2(60.0, 40.0)
const WALL_THICK := 20.0

const MAX_SPEED := 185.0
const ACCEL := 220.0
const BRAKE_DECEL := 420.0
const REVERSE_SPEED := 100.0
const COAST_DECEL := 90.0

const TURN_RATE := 2.6
const HANDBRAKE_TURN_BONUS := 1.2
const HANDBRAKE_SPEED_PENALTY := 0.55
const STEER_DEADZONE := 0.2

const PIT_RANGE := 70.0
const PIT_ANGLE_DOT := 0.6

var player_car: CharacterBody2D
var player_speed := 0.0

var fleeing_car: CharacterBody2D
var _waypoints: Array[Vector2] = []
var _wp_index := 0
const FLEEING_SPEED := 140.0
var fleeing_active := false
var fleeing_spinning := false
var pit_landed := false
var _spin_timer := 0.0

var ghost_car: CharacterBody2D
var ghost_active := false
var _ghost_timer := 0.0
const GHOST_SPEED := 220.0
var ghost_start: Vector2
var ghost_end: Vector2

var accel_btn: Control
var brake_btn: Control
var pit_btn: Control
var story: Control
var status_label: Label
var _controls_locked := true
var _phase := "intro"
## intro -> chase -> ghost_glimpse -> outro -> done


func _ready() -> void:
	_build_track()
	_build_player_car()
	_build_fleeing_car()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O semáforo da Décima com Industrial pisca duas vezes e apaga. Ninguém percebe até ser tarde demais.",
			"Um carro corta o cruzamento, bate de leve num poste e sai em disparada — pânico, não maldade, mas foge do jeito que importa.",
			"Doyle, do rádio: \"Vai atrás, eu cuido do ferido aqui!\"",
		],
		["", "", "Sgt. Doyle"]
	)


# ---------- construção da cena ----------

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
		poly.color = Color(0.3, 0.3, 0.35)
		poly.position = r.position
		add_child(poly)

	_waypoints = [
		top + Vector2(100, 100),
		top + Vector2(w - 100, 100),
		top + Vector2(w - 100, h - 100),
		top + Vector2(100, h - 100),
	]
	ghost_start = top + Vector2(-40, h * 0.5)
	ghost_end = top + Vector2(w + 40, h * 0.5)


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


func _build_fleeing_car() -> void:
	fleeing_car = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 16)
	shape.shape = rect
	fleeing_car.add_child(shape)
	fleeing_car.position = _waypoints[0]
	add_child(fleeing_car)


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

	pit_btn = _corner_button("handbrake", tr("FREIO DE\nMÃO / PIT"), 30, 160, 110, 110)
	layer.add_child(pit_btn)


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


# ---------- fluxo ----------

func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "chase"
			_controls_locked = false
			fleeing_active = true
		"ghost_glimpse":
			_phase = "outro"
			story.say(
				[
					"Mark algema o motorista — assustado, não perigoso. Vai levar uma multa feia e uma baita história.",
					"Ninguém no bairro vai lembrar do susto. Mark, sim — do jeito que aquele outro carro sumiu sem nem acender o farol.",
					"Fim do Turno 4 — Semáforo Cego.",
				],
				["", "", ""]
			)
		"outro":
			_phase = "done"


func _check_pit_complete() -> void:
	if not pit_landed or _phase != "chase":
		return
	fleeing_active = false
	_phase = "ghost_glimpse"
	_controls_locked = true
	ghost_active = true
	_ghost_timer = 0.0
	story.say(
		[
			"O carro perde o rumo e para de lado na calçada. No retrovisor, outro veículo passa reto pelo cruzamento quebrado — sem parar, sem hesitar, como quem já sabia que o sinal ia falhar.",
		],
		[""]
	)


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	_update_drive_buttons()
	if not _controls_locked:
		_drive_player(delta)
	if fleeing_active:
		_drive_fleeing(delta)
		_try_pit()
	if ghost_active:
		_update_ghost(delta)
	_update_hud()
	queue_redraw()


func _update_drive_buttons() -> void:
	# Visíveis só quando os controles estão livres — mesmo bug que a
	# Fase 3 teve antes de corrigir (botão ficava visível por padrão
	# inclusive durante diálogo travado, já que nada definia o estado
	# inicial). Ligado direto ao flag, nunca mais dessincroniza.
	accel_btn.visible = not _controls_locked
	brake_btn.visible = not _controls_locked
	pit_btn.visible = not _controls_locked


func _drive_player(delta: float) -> void:
	var accelerating := InputBridge.is_held("accelerate")
	var braking := InputBridge.is_held("brake")
	var handbraking := InputBridge.is_held("handbrake")

	if accelerating and not braking:
		player_speed = move_toward(player_speed, MAX_SPEED, ACCEL * delta)
	elif braking:
		if player_speed > 0.0:
			player_speed = move_toward(player_speed, 0.0, BRAKE_DECEL * delta)
		else:
			player_speed = move_toward(player_speed, -REVERSE_SPEED, ACCEL * delta)
	else:
		player_speed = move_toward(player_speed, 0.0, COAST_DECEL * delta)

	var turn_mult: float = TURN_RATE + (HANDBRAKE_TURN_BONUS if handbraking else 0.0)
	var speed_cap: float = MAX_SPEED * (HANDBRAKE_SPEED_PENALTY if handbraking else 1.0)
	player_speed = clamp(player_speed, -REVERSE_SPEED, speed_cap)

	if InputBridge.move_vector.length() >= STEER_DEADZONE and absf(player_speed) > 5.0:
		var desired_angle := InputBridge.move_vector.angle()
		var diff := wrapf(desired_angle - player_car.rotation, -PI, PI)
		var speed_factor: float = clamp(absf(player_speed) / MAX_SPEED, 0.35, 1.0)
		var max_step: float = turn_mult * speed_factor * delta
		player_car.rotation += clamp(diff, -max_step, max_step)

	player_car.velocity = Vector2.RIGHT.rotated(player_car.rotation) * player_speed
	player_car.move_and_slide()


func _drive_fleeing(delta: float) -> void:
	if fleeing_spinning:
		_spin_timer -= delta
		fleeing_car.rotation += 6.0 * delta
		fleeing_car.velocity = Vector2.ZERO
		fleeing_car.move_and_slide()
		if _spin_timer <= 0.0:
			fleeing_spinning = false
		return
	if pit_landed:
		return

	var dest: Vector2 = _waypoints[_wp_index]
	var to_dest := dest - fleeing_car.position
	if to_dest.length() < 12.0:
		_wp_index = (_wp_index + 1) % _waypoints.size()
		dest = _waypoints[_wp_index]
		to_dest = dest - fleeing_car.position

	fleeing_car.rotation = to_dest.angle()
	fleeing_car.velocity = to_dest.normalized() * FLEEING_SPEED
	fleeing_car.move_and_slide()


func _try_pit() -> void:
	if pit_landed or fleeing_spinning or _phase != "chase":
		return
	if not InputBridge.is_held("handbrake"):
		return

	var to_target := fleeing_car.position - player_car.position
	var dist := to_target.length()
	var behind_dot := Vector2.RIGHT.rotated(player_car.rotation).dot(to_target.normalized())
	if dist > PIT_RANGE or behind_dot <= PIT_ANGLE_DOT:
		return

	for i in player_car.get_slide_collision_count():
		if player_car.get_slide_collision(i).get_collider() == fleeing_car:
			fleeing_spinning = true
			_spin_timer = 1.2
			pit_landed = true
			_check_pit_complete()
			return


func _update_ghost(delta: float) -> void:
	if not ghost_car:
		ghost_car = CharacterBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(28, 16)
		shape.shape = rect
		ghost_car.add_child(shape)
		ghost_car.position = ghost_start
		ghost_car.rotation = (ghost_end - ghost_start).angle()
		add_child(ghost_car)

	_ghost_timer += delta
	ghost_car.position = ghost_start.lerp(ghost_end, clamp(_ghost_timer / 1.6, 0.0, 1.0))
	if _ghost_timer >= 1.6:
		ghost_active = false
		GameState.ghost_spotted = true


func _update_hud() -> void:
	match _phase:
		"chase":
			status_label.text = tr("Alinhe atrás do carro e segure FREIO DE MÃO/PIT — precisa bater nele pra funcionar.")
		"done":
			status_label.text = tr("Turno 4 concluído.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player_car:
		_draw_car(player_car.position, player_car.rotation, Color(0.3, 0.6, 0.9))
	if fleeing_car and fleeing_active:
		_draw_car(fleeing_car.position, fleeing_car.rotation, Color(0.4, 0.4, 0.4) if pit_landed else Color(0.9, 0.3, 0.3))
	if ghost_car and ghost_active:
		_draw_car(ghost_car.position, ghost_car.rotation, Color(0.15, 0.15, 0.15))


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
