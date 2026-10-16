extends Node2D
## Ato 1, Fase 3 — "Direção Defensiva" (docs/ROTEIRO.md): circuito de
## direção seguro e fechado — acelerar, frear, PIT maneuver como
## exercício, não como perseguição de verdade. Sem risco nenhum: não há
## estado de falha, só o jogador aprendendo os comandos do carro antes
## de precisar deles de verdade.
##
## O jogador já começa dentro do carro (não existe mecânica de "entrar
## no veículo" ainda) — Okafor e Theo esperam parados na área de largada;
## dirigir até perto deles dispara a instrução, mesmo padrão de
## proximidade das Fases 1/2. Depois: 3 checkpoints em sequência, depois
## um carro-alvo pra praticar o PIT.
##
## Contraste narrativo de propósito: nas Fases 1/2, o Theo provoca o Mark
## por ser cuidadoso/certinho demais. Aqui a mesma característica
## finalmente paga — o Theo dirige rápido e quase bate, o Mark dirige
## limpo, e é a primeira vez que a Okafor valoriza isso sem ressalva.
##
## Reaproveita a física de direção/freio/PIT já validada no sandbox de
## perseguição (`sandbox/perseguicao.gd`) e `ui/story_box.gd` pra
## narrativa. 2ª cópia dessa lógica de carro — ainda não é a "regra dos
## três" (essa já bateu no controlador tático, não no de carro), mas vale
## observar se uma 3ª aparecer.
##
## PIT revisado após teste: antes bastava chegar perto por trás e segurar
## o botão parado por um tempo — sem contato nenhum entre os carros,
## o usuário achou que "não fez muito sentido". Agora precisa alinhar
## + segurar o botão + fazer contato físico de verdade (`_try_pit` usa
## `CharacterBody2D.get_slide_collision_count/get_slide_collision` pra
## detectar a batida). Formas alternativas de encerrar perseguição que o
## usuário sugeriu (atirar no pneu, perseguir até desistir, bater até
## quebrar, fechar o carro) ficaram registradas no GDD como variedade
## confirmada pro sistema de perseguição de verdade do Ato 2+ — essa
## fase é só o exercício básico de PIT que o ROTEIRO pede, não é o lugar
## certo pra introduzir tudo isso.

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

var okafor_marker: Node2D
var theo_marker: Node2D

var briefing_zone: Area2D
var _briefed := false

var checkpoints: Array[Area2D] = []
var _next_checkpoint := 0

var target_car: CharacterBody2D
var _waypoints: Array[Vector2] = []
var _wp_index := 0
const TARGET_SPEED := 130.0
var target_active := false
var target_spinning := false
var pit_landed := false
var _spin_timer := 0.0

var story: Control
var status_label: Label
var accel_btn: Control
var brake_btn: Control
var pit_btn: Control
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> approach_briefing -> briefing -> circuit -> pit_test ->
## evaluation -> outro -> done

const SCENE_PATH := "res://missions/ato1_fase3_direcao.tscn"


func _ready() -> void:
	_build_track()
	_build_player_car()
	_build_npcs()
	_build_briefing_zone()
	_build_checkpoints()
	_build_target_car()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"Terceiro dia de instrução. Fileiras de cones marcam uma pista fechada — sem trânsito de verdade, sem pressa de verdade.",
			"Só o carro, o Mark, e tudo que a Academia ainda não teve chance de testar nele.",
		],
		["", ""]
	)


# ---------- construção da cena (caixas cinzas) ----------

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


func _build_player_car() -> void:
	player_car = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 16)
	shape.shape = rect
	player_car.add_child(shape)
	player_car.position = TRACK_ORIGIN + Vector2(80, 380)
	add_child(player_car)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player_car.add_child(camera)


func _build_npcs() -> void:
	okafor_marker = Node2D.new()
	okafor_marker.position = TRACK_ORIGIN + Vector2(180, 380)
	add_child(okafor_marker)

	theo_marker = Node2D.new()
	theo_marker.position = TRACK_ORIGIN + Vector2(230, 380)
	add_child(theo_marker)


func _build_briefing_zone() -> void:
	briefing_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(160.0, 140.0)
	shape.shape = rect
	briefing_zone.add_child(shape)
	briefing_zone.position = TRACK_ORIGIN + Vector2(205, 380)
	briefing_zone.monitorable = true
	briefing_zone.body_entered.connect(_on_briefing_zone_entered)
	add_child(briefing_zone)


func _build_checkpoints() -> void:
	var positions := [
		TRACK_ORIGIN + Vector2(700, 80),
		TRACK_ORIGIN + Vector2(120, 80),
		TRACK_ORIGIN + Vector2(400, 380),
	]
	for pos in positions:
		var cp := Area2D.new()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 40.0
		shape.shape = circle
		cp.add_child(shape)
		cp.position = pos
		cp.monitorable = true
		cp.body_entered.connect(_on_checkpoint_entered.bind(cp))
		add_child(cp)
		checkpoints.append(cp)


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

	pit_btn = _corner_button("handbrake", tr("FREIO DE\nMÃO / PIT"), 30, 160, 110, 110)
	layer.add_child(pit_btn)


func _corner_button(action: String, label: String, right: float, bottom: float, w: float, h: float) -> Control:
	var btn := Control.new()
	btn.set_script(load("res://ui/contextual_button.gd"))
	btn.action_name = action
	btn.label_text = label
	btn.layout_slot = ControlLayout.slot_for_action(action)
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


# ---------- fluxo da fase ----------

func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "approach_briefing"
			_controls_locked = false
		"briefing":
			_phase = "circuit"
			_controls_locked = false
		"evaluation":
			_phase = "outro"
			story.say(
				[
					"Fim da instrução por hoje. Amanhã tem avaliação final — aí eu decido pra onde cada um de vocês vai.",
					"Fim da Fase 3 — Direção Defensiva.",
				],
				["Capitã Okafor", ""]
			)
		"outro":
			_phase = "done"
			next_btn.visible = true


func _on_briefing_zone_entered(body: Node) -> void:
	if body != player_car or _briefed or _phase != "approach_briefing":
		return
	_briefed = true
	_phase = "briefing"
	_controls_locked = true
	story.say(
		[
			"Direção defensiva. Não é sobre chegar rápido, é sobre chegar inteiro.",
			"Já dei a volta duas vezes esperando vocês. Nasci sabendo dirigir.",
			"Nasceu quase batendo num cone, Marsh. Reyes: três curvas até o carro-alvo, depois eu quero ver um PIT limpo.",
		],
		["Capitã Okafor", "Theo Marsh", "Capitã Okafor"]
	)


func _on_checkpoint_entered(body: Node, cp: Area2D) -> void:
	if _phase != "circuit" or body != player_car:
		return
	if checkpoints[_next_checkpoint] != cp:
		return
	_next_checkpoint += 1
	if _next_checkpoint >= checkpoints.size():
		_phase = "pit_test"
		target_active = true


func _check_pit_complete() -> void:
	if not pit_landed or _phase != "pit_test":
		return
	_phase = "evaluation"
	_controls_locked = true
	story.say(
		[
			"Limpo. Você não bateu em nada, não perdeu o controle. Isso conta mais do que velocidade, Reyes.",
			"...Foi bom, tá bom? Não precisa esfregar na cara.",
		],
		["Capitã Okafor", "Theo Marsh"]
	)


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	_update_drive_buttons()
	if not _controls_locked:
		_drive_player(delta)
	if target_active:
		_drive_target(delta)
		_try_pit(delta)
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

	if InputBridge.move_vector.length() >= STEER_DEADZONE and absf(player_speed) > 5.0:
		var desired_angle := InputBridge.move_vector.angle()
		var diff := wrapf(desired_angle - player_car.rotation, -PI, PI)
		var speed_factor: float = clamp(absf(player_speed) / MAX_SPEED, 0.35, 1.0)
		var max_step: float = turn_mult * speed_factor * delta
		player_car.rotation += clamp(diff, -max_step, max_step)

	player_car.velocity = Vector2.RIGHT.rotated(player_car.rotation) * player_speed
	player_car.move_and_slide()


func _drive_target(delta: float) -> void:
	if target_spinning:
		_spin_timer -= delta
		target_car.rotation += 6.0 * delta
		target_car.velocity = Vector2.ZERO
		target_car.move_and_slide()
		if _spin_timer <= 0.0:
			target_spinning = false
		return

	if pit_landed:
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


func _update_drive_buttons() -> void:
	# Visíveis sempre que os controles estão livres (não só em "circuit"/
	# "pit_test" — "approach_briefing" também precisa, senão o jogador
	# não tem como acelerar até a Okafor). Ligado direto ao mesmo flag
	# que libera o volante, pra nunca dessincronizar de novo.
	accel_btn.visible = not _controls_locked
	brake_btn.visible = not _controls_locked
	pit_btn.visible = not _controls_locked


## PIT de verdade: precisa se alinhar por trás, segurar o botão (sinaliza
## que é um toque controlado, não uma batida qualquer) E fazer contato
## físico com o carro-alvo. Antes bastava chegar perto e segurar o botão
## parado — sem nenhum contato, o que o usuário descreveu como "não fez
## muito sentido" (não tinha nada acontecendo de verdade entre os carros).
func _try_pit(_delta: float) -> void:
	if pit_landed or target_spinning or _phase != "pit_test":
		return
	if not InputBridge.is_held("handbrake"):
		return

	var to_target := target_car.position - player_car.position
	var dist := to_target.length()
	var behind_dot := Vector2.RIGHT.rotated(player_car.rotation).dot(to_target.normalized())
	var lined_up: bool = dist <= PIT_RANGE and behind_dot > PIT_ANGLE_DOT
	if not lined_up:
		return

	for i in player_car.get_slide_collision_count():
		if player_car.get_slide_collision(i).get_collider() == target_car:
			target_spinning = true
			_spin_timer = 1.2
			pit_landed = true
			_check_pit_complete()
			return


func _update_hud() -> void:
	match _phase:
		"approach_briefing":
			status_label.text = tr("Objetivo: dirija até a Capitã Okafor.")
		"circuit":
			status_label.text = tr("Checkpoint %d/%d — manche aponta pra onde ir, ACELERAR/FREAR são botões.") % [_next_checkpoint, checkpoints.size()]
		"pit_test":
			status_label.text = tr("Alinhe atrás do carro-alvo, segure FREIO DE MÃO/PIT e BATA nele por trás — encostar não basta, tem que ser contato de verdade.")
		"done":
			status_label.text = tr("Fase 3 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player_car:
		_draw_car(player_car.position, player_car.rotation, Color(0.3, 0.6, 0.9))
	if target_car and target_active:
		_draw_car(target_car.position, target_car.rotation, Color(0.4, 0.4, 0.4) if pit_landed else Color(0.9, 0.3, 0.3))

	if okafor_marker:
		draw_circle(okafor_marker.position, 15.0, Color(0.6, 0.2, 0.2))
		_draw_name_tag(okafor_marker.position, "Okafor")
	if theo_marker:
		draw_circle(theo_marker.position, 15.0, Color(0.2, 0.4, 0.6))
		_draw_name_tag(theo_marker.position, "Theo")

	for i in checkpoints.size():
		var cp := checkpoints[i]
		var done := i < _next_checkpoint
		var color := Color(0.3, 0.9, 0.3, 0.5) if done else Color(0.9, 0.8, 0.2, 0.5)
		draw_circle(cp.position, 40.0, color)
		_draw_name_tag(cp.position, str(i + 1))


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


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
