extends Node2D
## Sandbox de perseguição — caixas cinzas. Revisado após o 3º teste no
## celular: direcionar continuava muito difícil — o usuário explicou que
## esquerda/direita do manche fazia sentido com o carro na vertical, mas
## confundia com o carro de lado, porque a direção era relativa ao carro
## (manche estilo "volante"). Trocado pra direção relativa à TELA: o
## manche aponta pra onde o jogador quer ir, e o carro gira o nariz até
## lá numa taxa limitada (não instantâneo — continua parecendo carro, só
## não depende mais de lembrar a própria orientação do veículo).
## Acelerar/frear já respondiam bem, mantidos como estavam. GDD Seção 8.

const TRACK_SIZE := Vector2(820.0, 460.0)
const TRACK_ORIGIN := Vector2(60.0, 40.0)
const WALL_THICK := 20.0

const MAX_SPEED := 185.0  ## era 240 — usuário achou rápido demais; número fácil de destravar depois
const ACCEL := 220.0
const BRAKE_DECEL := 420.0
const REVERSE_SPEED := 100.0
const COAST_DECEL := 90.0

const TURN_RATE := 2.6          ## rad/s máximo girando o carro pra alinhar com a direção pedida
const HANDBRAKE_TURN_BONUS := 1.2
const HANDBRAKE_SPEED_PENALTY := 0.55
const STEER_DEADZONE := 0.2     ## abaixo disso, o manche não indica direção nenhuma (mantém o rumo atual)

const PIT_RANGE := 70.0
const PIT_ANGLE_DOT := 0.6
const PIT_HOLD_NEEDED := 0.6

const SHOOT_RANGE := 220.0
const SHOOT_CONE_DOT := 0.8

var player_car: CharacterBody2D
var player_speed := 0.0
var _pit_hold := 0.0
var pit_landed := false

var target_car: CharacterBody2D
var _waypoints: Array[Vector2] = []
var _wp_index := 0
const TARGET_SPEED := 150.0
var target_spinning := false
var target_downed := false
var _spin_timer := 0.0

var status_label: Label
var shoot_btn: Control


func _ready() -> void:
	_build_track()
	_build_player_car()
	_build_target_car()
	_build_hud()
	_build_controls()


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
		top + Vector2(80, 80),
		top + Vector2(w - 80, 80),
		top + Vector2(w - 80, h - 80),
		top + Vector2(80, h - 80),
	]


func _build_player_car() -> void:
	player_car = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 16)
	shape.shape = rect
	player_car.add_child(shape)
	player_car.position = TRACK_ORIGIN + Vector2(120, 120)
	add_child(player_car)


func _build_target_car() -> void:
	target_car = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 16)
	shape.shape = rect
	target_car.add_child(shape)
	target_car.position = _waypoints[0]
	add_child(target_car)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(16, 16)
	status_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(status_label)

	var back := Button.new()
	back.text = "< Menu"
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

	# Manche: aponta pra onde o carro deve virar o nariz (direção
	# relativa à TELA, não ao carro — ver _drive_player). Metade
	# esquerda da tela (fração real, não pixel).
	var stick := Control.new()
	stick.set_script(load("res://ui/virtual_joystick.gd"))
	stick.anchor_left = 0.0
	stick.anchor_right = 0.55
	stick.anchor_top = 0.0
	stick.anchor_bottom = 1.0
	layer.add_child(stick)

	# Botões: todos ancorados no canto inferior direito de verdade,
	# empilhados numa grade fixa — não dependem de resolução assumida.
	var accel_btn := _corner_button("accelerate", "ACELERAR", 30, 30, 110, 110)
	layer.add_child(accel_btn)

	var brake_btn := _corner_button("brake", "FREAR", 160, 40, 100, 100)
	layer.add_child(brake_btn)

	var handbrake_btn := _corner_button("handbrake", "FREIO DE\nMÃO / PIT", 30, 160, 110, 110)
	layer.add_child(handbrake_btn)

	shoot_btn = _corner_button("shoot", "ATIRAR", 280, 30, 90, 90)
	shoot_btn.visible = false
	layer.add_child(shoot_btn)


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


func _process(delta: float) -> void:
	_drive_player(delta)
	_drive_target(delta)
	_try_pit(delta)
	_update_shoot(delta)
	_update_hud()
	queue_redraw()


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

	# Direção relativa à TELA, não ao carro: o manche aponta pra onde o
	# jogador quer que o carro vá, e o carro gira o nariz até lá, limitado
	# por uma taxa máxima (não vira instantaneamente — continua sendo um
	# carro, não um drone). Isso tira a confusão de "esquerda/direita do
	# manche" mudar de sentido dependendo de como o carro está virado —
	# o jogador só aponta o manche pra direção desejada na tela.
	if InputBridge.move_vector.length() >= STEER_DEADZONE and absf(player_speed) > 5.0:
		var desired_angle := InputBridge.move_vector.angle()
		var diff := wrapf(desired_angle - player_car.rotation, -PI, PI)
		var speed_factor: float = clamp(absf(player_speed) / MAX_SPEED, 0.35, 1.0)
		var max_step: float = turn_mult * speed_factor * delta
		player_car.rotation += clamp(diff, -max_step, max_step)

	player_car.velocity = Vector2.RIGHT.rotated(player_car.rotation) * player_speed
	player_car.move_and_slide()


func _drive_target(delta: float) -> void:
	if target_downed:
		return

	if target_spinning:
		_spin_timer -= delta
		target_car.rotation += 6.0 * delta
		target_car.velocity = Vector2.ZERO
		target_car.move_and_slide()
		if _spin_timer <= 0.0:
			target_spinning = false
		return

	var dest: Vector2 = _waypoints[_wp_index]
	var to_dest := dest - target_car.position
	if to_dest.length() < 12.0:
		_wp_index = (_wp_index + 1) % _waypoints.size()
		dest = _waypoints[_wp_index]
		to_dest = dest - target_car.position

	target_car.rotation = to_dest.angle()
	target_car.velocity = to_dest.normalized() * TARGET_SPEED
	target_car.move_and_slide()


func _try_pit(delta: float) -> void:
	if pit_landed or target_spinning or target_downed:
		_pit_hold = 0.0
		return

	var to_target := target_car.position - player_car.position
	var dist := to_target.length()
	var behind_dot := Vector2.RIGHT.rotated(player_car.rotation).dot(to_target.normalized())

	var lined_up: bool = dist <= PIT_RANGE and behind_dot > PIT_ANGLE_DOT
	if lined_up and InputBridge.is_held("handbrake"):
		_pit_hold += delta
		if _pit_hold >= PIT_HOLD_NEEDED:
			target_spinning = true
			_spin_timer = 1.2
			pit_landed = true
	else:
		_pit_hold = 0.0


func _update_shoot(_delta: float) -> void:
	if pit_landed or target_downed:
		shoot_btn.visible = false
		return

	var to_target := target_car.position - player_car.position
	var dist := to_target.length()
	var forward := Vector2.RIGHT.rotated(player_car.rotation)
	var locked := dist <= SHOOT_RANGE and forward.dot(to_target.normalized()) > SHOOT_CONE_DOT

	shoot_btn.visible = locked

	if locked and InputBridge.consume_just_pressed("shoot"):
		target_downed = true
		status_label.text = "ALVO NEUTRALIZADO (mira automática)"


func _update_hud() -> void:
	if pit_landed:
		status_label.text = "PIT MANEUVER conseguido!"
		return
	if target_downed:
		return
	status_label.text = "Manche: aponte pra ONDE quer ir na tela (não é mais esquerda/direita do carro) — o carro gira até lá, sem giro de 360°. ACELERAR/FREAR são botões.\nEncoste atrás do alvo e segure FREIO DE MÃO/PIT pra tentar o PIT.\nAlinhe o alvo à frente (cone) pra travar mira automática e ver ATIRAR."


func _draw() -> void:
	if player_car:
		_draw_car(player_car.position, player_car.rotation, Color(0.3, 0.6, 0.9))
	if target_car:
		_draw_car(target_car.position, target_car.rotation, Color(0.4, 0.4, 0.4) if target_downed else Color(0.9, 0.3, 0.3))


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
