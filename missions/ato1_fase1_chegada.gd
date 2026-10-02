extends Node2D
## Ato 1, Fase 1 — "Chegada" (docs/ROTEIRO.md). Primeira missão de
## conteúdo real do jogo.
##
## Layout em 3 áreas: Rua/Estacionamento (fora da academia, onde o Mark
## chega) -> Entrada (Okafor e Theo esperam parados, só falam quando o
## Mark chega perto — não andam até então) -> Estande de tiro (bancada de
## armas, Theo demonstra acertando os 4 alvos, alvos resetam, vez do
## Mark).
##
## Mecânica nova: pegar arma na bancada (botão contextual "PEGAR", só
## depois disso o botão ATIRAR aparece). É a base do sistema futuro de
## pegar a arma de um suspeito quando a do jogador ficar sem munição —
## implementado aqui de um jeito genérico o bastante pra reaproveitar
## depois (zona de interação + botão de pegar + estado "tem arma").
##
## Mira: linha de mira em tempo real (raio calculado todo frame) e giro
## suavizado ainda mais a pedido do usuário (`FACING_TURN_SPEED_AIMING`).
##
## Reaproveita os controles do sandbox tático (validados em 8 rodadas de
## teste) e `ui/story_box.gd` pra narrativa linear.

const STREET_SIZE := Vector2(260.0, 420.0)
const ENTRANCE_SIZE := Vector2(360.0, 420.0)
const RANGE_SIZE := Vector2(420.0, 420.0)
const WALL_THICK := 20.0
const DOOR_GAP := 120.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const FIRE_RANGE := 900.0

const NPC_WALK_SPEED := 80.0

var _street_origin: Vector2
var _entrance_origin: Vector2
var _range_origin: Vector2

var player: CharacterBody2D
var _facing := Vector2.RIGHT
const FACING_TURN_SPEED_AIMING := 9.0   ## voltou de 6 pra 9 depois que manche/movimento foram desacoplados

var okafor_marker: Node2D
var theo_marker: Node2D
var okafor_range_pos: Vector2
var theo_range_pos: Vector2

var greet_zone: Area2D
var _greeted := false
var range_zone: Area2D
var _range_entered := false

var weapon_rack: Area2D
var has_weapon := false
const RACK_INTERACT_DIST := 55.0

var targets: Array[Area2D] = []
var _targets_hit := 0
const TARGET_COUNT := 4

var story: Control
var status_label: Label
var fire_btn: Control
var pickup_btn: Control
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> walk_to_entrance -> greet -> walk_to_range -> range_setup ->
## theo_turn -> theo_result -> shooting -> reaction -> outro -> done

const SCENE_PATH := "res://missions/ato1_fase1_chegada.tscn"

var _theo_turn_timer := 0.0
var _theo_targets_hit := 0
const THEO_HIT_START_DELAY := 0.8
const THEO_HIT_INTERVAL := 0.7
const THEO_HIT_PAUSE_AFTER := 0.9

var _player_any_miss := false

var _aim_end := Vector2.ZERO
var _aim_hit_target := false
var _aim_valid := false


func _ready() -> void:
	_build_rooms()
	_build_player()
	_build_npcs()
	_build_greet_zone()
	_build_range_zone()
	_build_weapon_rack()
	_build_targets()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"Bellmont, Academia Regional de Polícia. Primeiro dia.",
			"O ônibus deixou Mark Reyes no estacionamento — mochila num ombro só, os documentos amassados de tanto conferir no caminho.",
			"O pai dele foi policial da cidade por 25 anos. Nunca falou sobre o trabalho em casa. Talvez aqui, Mark entenda por quê.",
		],
		["", "", ""]
	)


# ---------- construção da cena (caixas cinzas) ----------

func _build_rooms() -> void:
	_street_origin = Vector2(80.0, 60.0)
	_entrance_origin = _street_origin + Vector2(STREET_SIZE.x, 0.0)
	_range_origin = _entrance_origin + Vector2(ENTRANCE_SIZE.x, 0.0)

	var walls: Array[Rect2] = []
	var s := _street_origin
	var e := _entrance_origin
	var r := _range_origin

	# Rua/estacionamento.
	walls.append(Rect2(s, Vector2(STREET_SIZE.x, WALL_THICK)))
	walls.append(Rect2(Vector2(s.x, s.y + STREET_SIZE.y - WALL_THICK), Vector2(STREET_SIZE.x, WALL_THICK)))
	walls.append(Rect2(s, Vector2(WALL_THICK, STREET_SIZE.y)))

	# Frente da academia (parede entre rua e entrada), com vão = porta.
	var door_gap := s.y + STREET_SIZE.y * 0.5 - DOOR_GAP * 0.5
	walls.append(Rect2(Vector2(s.x + STREET_SIZE.x - WALL_THICK, s.y), Vector2(WALL_THICK, door_gap - s.y)))
	walls.append(Rect2(Vector2(s.x + STREET_SIZE.x - WALL_THICK, door_gap + DOOR_GAP), Vector2(WALL_THICK, s.y + STREET_SIZE.y - (door_gap + DOOR_GAP))))

	# Entrada.
	walls.append(Rect2(e, Vector2(ENTRANCE_SIZE.x, WALL_THICK)))
	walls.append(Rect2(Vector2(e.x, e.y + ENTRANCE_SIZE.y - WALL_THICK), Vector2(ENTRANCE_SIZE.x, WALL_THICK)))

	var range_gap := e.y + ENTRANCE_SIZE.y * 0.5 - DOOR_GAP * 0.5
	walls.append(Rect2(Vector2(e.x + ENTRANCE_SIZE.x - WALL_THICK, e.y), Vector2(WALL_THICK, range_gap - e.y)))
	walls.append(Rect2(Vector2(e.x + ENTRANCE_SIZE.x - WALL_THICK, range_gap + DOOR_GAP), Vector2(WALL_THICK, e.y + ENTRANCE_SIZE.y - (range_gap + DOOR_GAP))))

	# Estande.
	walls.append(Rect2(r, Vector2(RANGE_SIZE.x, WALL_THICK)))
	walls.append(Rect2(Vector2(r.x, r.y + RANGE_SIZE.y - WALL_THICK), Vector2(RANGE_SIZE.x, WALL_THICK)))
	walls.append(Rect2(Vector2(r.x + RANGE_SIZE.x - WALL_THICK, r.y), Vector2(WALL_THICK, RANGE_SIZE.y)))

	for wr in walls:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = wr.size
		shape.shape = rect_shape
		shape.position = wr.size * 0.5
		body.add_child(shape)
		body.position = wr.position
		add_child(body)

		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2.ZERO, Vector2(wr.size.x, 0), wr.size, Vector2(0, wr.size.y)])
		poly.color = Color(0.35, 0.35, 0.4)
		poly.position = wr.position
		add_child(poly)

	# Piso da rua (asfalto) e do estande (grama/tapete de tiro), só pra
	# diferenciar visualmente as três áreas sem precisar de arte.
	var street_floor := Polygon2D.new()
	street_floor.polygon = PackedVector2Array([Vector2.ZERO, Vector2(STREET_SIZE.x - WALL_THICK * 2, 0), Vector2(STREET_SIZE.x - WALL_THICK * 2, STREET_SIZE.y - WALL_THICK * 2), Vector2(0, STREET_SIZE.y - WALL_THICK * 2)])
	street_floor.color = Color(0.16, 0.16, 0.18)
	street_floor.position = s + Vector2(WALL_THICK, WALL_THICK)
	street_floor.z_index = -1
	add_child(street_floor)

	var range_floor := Polygon2D.new()
	range_floor.polygon = PackedVector2Array([Vector2.ZERO, Vector2(RANGE_SIZE.x - WALL_THICK * 2, 0), Vector2(RANGE_SIZE.x - WALL_THICK * 2, RANGE_SIZE.y - WALL_THICK * 2), Vector2(0, RANGE_SIZE.y - WALL_THICK * 2)])
	range_floor.color = Color(0.18, 0.2, 0.16)
	range_floor.position = r + Vector2(WALL_THICK, WALL_THICK)
	range_floor.z_index = -1
	add_child(range_floor)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = _street_origin + Vector2(60, STREET_SIZE.y - 90)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_npcs() -> void:
	# Parados perto da porta da entrada, esperando — só reagem quando o
	# Mark chega perto (ver `greet_zone`), não andam antes disso.
	okafor_marker = Node2D.new()
	okafor_marker.position = _entrance_origin + Vector2(70, 100)
	add_child(okafor_marker)

	theo_marker = Node2D.new()
	theo_marker.position = _entrance_origin + Vector2(140, 100)
	add_child(theo_marker)


func _build_greet_zone() -> void:
	greet_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(150.0, 150.0)
	shape.shape = rect
	greet_zone.add_child(shape)
	greet_zone.position = _entrance_origin + Vector2(105, 130)
	greet_zone.monitorable = true
	greet_zone.body_entered.connect(_on_greet_zone_entered)
	add_child(greet_zone)


func _build_range_zone() -> void:
	range_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80.0, DOOR_GAP)
	shape.shape = rect
	range_zone.add_child(shape)
	var gap := _entrance_origin.y + ENTRANCE_SIZE.y * 0.5 - DOOR_GAP * 0.5
	range_zone.position = Vector2(_entrance_origin.x + ENTRANCE_SIZE.x, gap + DOOR_GAP * 0.5)
	range_zone.monitorable = true
	range_zone.body_entered.connect(_on_range_entered)
	add_child(range_zone)


func _build_weapon_rack() -> void:
	weapon_rack = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	weapon_rack.add_child(shape)
	weapon_rack.position = _range_origin + Vector2(55, RANGE_SIZE.y * 0.5)
	weapon_rack.monitorable = true
	add_child(weapon_rack)


func _build_targets() -> void:
	for i in TARGET_COUNT:
		var t := Area2D.new()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 15.0
		shape.shape = circle
		t.add_child(shape)
		t.position = _range_origin + Vector2(RANGE_SIZE.x - 60, 70 + i * 90)
		t.monitorable = true
		t.set_meta("hit", false)
		add_child(t)
		targets.append(t)

	okafor_range_pos = _range_origin + Vector2(60, 200)
	theo_range_pos = _range_origin + Vector2(60, 300)


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

	var left_stick := Control.new()
	left_stick.set_script(load("res://ui/virtual_joystick.gd"))
	left_stick.anchor_left = 0.0
	left_stick.anchor_right = 0.5
	left_stick.anchor_top = 0.0
	left_stick.anchor_bottom = 1.0
	layer.add_child(left_stick)

	var right_stick := Control.new()
	right_stick.set_script(load("res://ui/virtual_joystick.gd"))
	right_stick.right_stick = true
	right_stick.anchor_left = 0.5
	right_stick.anchor_right = 1.0
	right_stick.anchor_top = 0.0
	right_stick.anchor_bottom = 1.0
	layer.add_child(right_stick)

	fire_btn = _action_button("shoot", tr("ATIRAR"), 30.0, 180.0, 100.0, 100.0)
	fire_btn.visible = false
	layer.add_child(fire_btn)

	pickup_btn = _action_button("pickup", tr("PEGAR"), 30.0, 180.0, 100.0, 100.0)
	pickup_btn.visible = false
	layer.add_child(pickup_btn)


func _action_button(action: String, label: String, right: float, bottom: float, w: float, h: float) -> Control:
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


# ---------- fluxo da fase ----------

func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "walk_to_entrance"
			_controls_locked = false
		"greet":
			_phase = "walk_to_range"
			_controls_locked = false
		"range_setup":
			_phase = "theo_turn"
			_theo_turn_timer = 0.0
			_theo_targets_hit = 0
			_controls_locked = true
		"theo_result":
			_begin_player_turn()
		"reaction":
			_phase = "outro"
			story.say(
				[
					"Chega por hoje na pontaria. Amanhã a gente fala de abordagem — a diferença entre reagir e responder.",
					"O pai de Mark nunca contou essas histórias. Talvez fosse por isso — não cabiam em conversa de jantar.",
					"Fim da Fase 1 — Chegada. Próxima fase (Abordagem Tática) ainda não foi construída.",
				],
				["Capitã Okafor", "", ""]
			)
		"outro":
			_phase = "done"
			next_btn.visible = true


func _on_greet_zone_entered(body: Node) -> void:
	if body != player or _greeted or _phase != "walk_to_entrance":
		return
	_greeted = true
	_phase = "greet"
	_controls_locked = true
	story.say(
		[
			"Uma mulher de farda impecável espera perto da porta, prancheta na mão. Ao lado dela, um recruta mais novo já bate o pé, impaciente.",
			"Recruta Mark Reyes, senhora. Cheguei o quanto antes.",
			"\"Quanto antes\" era quinze minutos atrás, Reyes. Capitã Diane Okafor. Não se atrase de novo.",
			"Alguns de nós já estavam prontos desde as seis, capitã.",
			"Menos conversa, Marsh. Os dois, comigo até a linha de tiro.",
		],
		["", "Mark", "Capitã Okafor", "Theo Marsh", "Capitã Okafor"]
	)


func _on_range_entered(body: Node) -> void:
	if body != player or _range_entered or _phase != "walk_to_range":
		return
	_range_entered = true
	_phase = "range_setup"
	_controls_locked = true
	story.say(
		[
			"Cada um pega uma arma na bancada. Vamos ver do que vocês são feitos.",
			"Deixa que eu vou primeiro, capitã. Já fiz isso mil vezes.",
			"Vai, Marsh. Mostra.",
		],
		["Capitã Okafor", "Theo Marsh", "Capitã Okafor"]
	)


func _update_theo_turn(delta: float) -> void:
	if _phase != "theo_turn":
		return
	_theo_turn_timer += delta

	var expected := int(floor((_theo_turn_timer - THEO_HIT_START_DELAY) / THEO_HIT_INTERVAL)) + 1
	expected = clamp(expected, 0, TARGET_COUNT)
	while _theo_targets_hit < expected:
		_mark_target_hit(_theo_targets_hit)
		_theo_targets_hit += 1

	var sequence_end := THEO_HIT_START_DELAY + (TARGET_COUNT - 1) * THEO_HIT_INTERVAL + THEO_HIT_PAUSE_AFTER
	if _theo_targets_hit >= TARGET_COUNT and _theo_turn_timer >= sequence_end:
		_phase = "theo_result"
		story.say(["Quatro de quatro, sem hesitar. Theo dá de ombros, como se fosse óbvio."], [""])


func _begin_player_turn() -> void:
	for t in targets:
		t.set_meta("hit", false)
	_targets_hit = 0
	_player_any_miss = false
	_phase = "shooting"
	_controls_locked = false
	story.say(
		["Sua vez, Reyes. Sua arma está na bancada — pega e mostra o que sabe."],
		["Capitã Okafor"]
	)


func _mark_target_hit(index: int) -> void:
	var t := targets[index]
	if t.get_meta("hit"):
		return
	t.set_meta("hit", true)
	_targets_hit += 1


func _check_shooting_complete() -> void:
	if _targets_hit < TARGET_COUNT or _phase != "shooting":
		return
	_phase = "reaction"
	_controls_locked = true
	if _player_any_miss:
		story.say(
			["Theo solta uma risadinha guardando a arma.", "Relaxa, recruta. Ainda dá tempo de pedir transferência pro trânsito."],
			["", "Theo Marsh"]
		)
	else:
		story.say(
			["Quatro de quatro, sem um tiro sobrando. Theo encara os alvos, depois o Mark, calculando alguma coisa.", "Nada mal."],
			["", "Theo Marsh"]
		)


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	_update_npc_walk(delta)
	if not _controls_locked:
		_move_player()
		_update_facing(delta)
		_update_weapon_pickup()
		_update_aim_preview()
		_update_fire()
	else:
		_aim_valid = false
	_update_theo_turn(delta)
	_update_hud()
	queue_redraw()


func _update_npc_walk(delta: float) -> void:
	if _phase != "walk_to_range":
		return
	okafor_marker.position = okafor_marker.position.move_toward(okafor_range_pos, NPC_WALK_SPEED * delta)
	theo_marker.position = theo_marker.position.move_toward(theo_range_pos, NPC_WALK_SPEED * delta)


func _move_player() -> void:
	player.velocity = InputBridge.move_vector * SPEED_CAUTIOUS
	player.move_and_slide()


func _update_facing(delta: float) -> void:
	# Manches desacoplados: esquerdo só move, direito é o único jeito de
	# mudar a mira. Sem tocar o manche direito, a mira congela onde
	# estava (não segue mais a direção de movimento).
	if InputBridge.aim_touching and InputBridge.aim_vector.length() > 0.15:
		var target_dir := InputBridge.aim_vector.normalized()
		var diff := wrapf(target_dir.angle() - _facing.angle(), -PI, PI)
		var max_step := FACING_TURN_SPEED_AIMING * delta
		_facing = _facing.rotated(clamp(diff, -max_step, max_step))


## Pegar arma na bancada — base do sistema futuro de pegar arma de
## suspeito quando a do jogador ficar sem munição (zona de interação +
## botão "Pegar" + estado "tem arma"). Aqui é só o Mark pegando a
## própria arma antes do tutorial de mira.
func _update_weapon_pickup() -> void:
	if _phase != "shooting" or has_weapon:
		pickup_btn.visible = false
		fire_btn.visible = has_weapon and _phase == "shooting"
		return

	var near := player.position.distance_to(weapon_rack.position) < RACK_INTERACT_DIST
	pickup_btn.visible = near
	fire_btn.visible = false

	if near and InputBridge.consume_just_pressed("pickup"):
		has_weapon = true
		pickup_btn.visible = false


## O jogador e a bancada nunca devem ser o que o raio de mira/tiro acerta
## (a bancada é só decoração depois de pegar a arma, mas continua sendo
## um Area2D com colisão de verdade — sem excluir, um tiro mirado de
## volta pra entrada poderia "acertar" a bancada em vez de um alvo/parede).
## Alvos já atingidos também entram na exclusão — sem isso, a mira parava
## num alvo já abatido em vez de passar pra o que estiver atrás dele.
func _fire_exclude() -> Array[RID]:
	var ex: Array[RID] = [player.get_rid(), weapon_rack.get_rid()]
	for t in targets:
		if t.get_meta("hit"):
			ex.append(t.get_rid())
	return ex


## Calcula todo frame onde o tiro bateria SE fosse disparado agora — uma
## linha de mira de verdade, não só a direção que o personagem olha.
func _update_aim_preview() -> void:
	if _phase != "shooting" or not has_weapon:
		_aim_valid = false
		return

	var space_state := get_world_2d().direct_space_state
	var start := player.position + _facing * (PLAYER_RADIUS + 2.0)
	var query := PhysicsRayQueryParameters2D.create(start, start + _facing * FIRE_RANGE)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = _fire_exclude()
	var result := space_state.intersect_ray(query)

	_aim_valid = true
	if result.is_empty():
		_aim_end = start + _facing * FIRE_RANGE
		_aim_hit_target = false
	else:
		_aim_end = result.position
		_aim_hit_target = (result.collider in targets) and not result.collider.get_meta("hit")


func _update_fire() -> void:
	if _phase != "shooting" or not has_weapon:
		return
	if not InputBridge.consume_just_pressed("shoot"):
		return

	var space_state := get_world_2d().direct_space_state
	var start := player.position + _facing * (PLAYER_RADIUS + 2.0)
	var query := PhysicsRayQueryParameters2D.create(start, start + _facing * FIRE_RANGE)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = _fire_exclude()
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		_player_any_miss = true
		return

	var collider = result.collider
	if collider in targets and not collider.get_meta("hit"):
		collider.set_meta("hit", true)
		_targets_hit += 1
		_check_shooting_complete()
	else:
		_player_any_miss = true


func _update_hud() -> void:
	match _phase:
		"walk_to_entrance":
			status_label.text = tr("Objetivo: entre na academia.")
		"walk_to_range":
			status_label.text = tr("Objetivo: siga a Capitã Okafor até o estande de tiro.")
		"theo_turn":
			status_label.text = tr("Theo Marsh vai primeiro...")
		"shooting":
			if not has_weapon:
				status_label.text = tr("Vá até a bancada e pegue sua arma (PEGAR).")
			else:
				status_label.text = tr("Alvos acertados: %d/%d — a linha de mira mostra onde o tiro vai bater.") % [_targets_hit, TARGET_COUNT]
		"done":
			status_label.text = tr("Fase 1 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))

		if _aim_valid:
			var line_color := Color(0.3, 1.0, 0.4, 0.8) if _aim_hit_target else Color(1.0, 1.0, 1.0, 0.35)
			draw_dashed_line(player.position, _aim_end, line_color, 2.0, 10.0)
			draw_circle(_aim_end, 5.0, line_color)
		else:
			draw_line(player.position, player.position + _facing * (PLAYER_RADIUS + 24.0), Color.WHITE, 3.0)

	if okafor_marker:
		draw_circle(okafor_marker.position, 15.0, Color(0.6, 0.2, 0.2))
		_draw_name_tag(okafor_marker.position, "Okafor")
	if theo_marker:
		draw_circle(theo_marker.position, 15.0, Color(0.2, 0.4, 0.6))
		_draw_name_tag(theo_marker.position, "Theo")

	if weapon_rack:
		draw_rect(Rect2(weapon_rack.position - Vector2(16, 10), Vector2(32, 20)), Color(0.4, 0.35, 0.3) if not has_weapon else Color(0.2, 0.2, 0.2))

	for t in targets:
		var hit: bool = t.get_meta("hit")
		draw_circle(t.position, 15.0, Color(0.2, 0.2, 0.2) if hit else Color(0.8, 0.2, 0.2))


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
