extends Node2D
## Ato 1, Fase 2 — "Abordagem Tática" (docs/ROTEIRO.md): treino de
## arrombar/espiar, e Okafor avaliando decisões de uso da força. Gancho
## mecânico: uma casa de treinamento com ALVOS-AMEAÇA e ALVOS-NÃO-AMEAÇA
## (civil/refém) misturados — o jogador precisa discriminar antes de
## atirar, não só acertar. Isso é o que dá conteúdo de verdade pra
## "decisões de uso da força" em vez de só um texto dizendo isso.
##
## Diferença estrutural da Fase 1: Okafor e Theo **não acompanham** o
## Mark pra dentro da casa de treinamento — ficam observando de fora
## (como instrução de verdade funciona), avaliam quando ele termina.
##
## Reaproveita os sistemas já validados (manches, câmera, cobertura/
## espiar, arrombar, mira com linha em tempo real, `story_box.gd`).
## Nota de arquitetura: esse é o 3º arquivo com essa mesma lógica de
## jogador (movimento/mira/cobertura/tiro) quase idêntica — bateu a
## "regra dos três". Se uma 4ª missão tática precisar do mesmo, vale
## extrair um componente compartilhado em vez de copiar de novo.

const STAGING_SIZE := Vector2(280.0, 380.0)
const HOUSE_SIZE := Vector2(460.0, 420.0)
const WALL_THICK := 20.0
const DOOR_GAP := 90.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const SPEED_SPRINT := 170.0
const SPRINT_CHARGE_TIME := 2.0
const SPRINT_DEFLECT_THRESHOLD := 0.75
const SPRINT_CHARGE_DECAY := 2.0
const FIRE_RANGE := 900.0
const COVER_DISTANCE := 30.0
const DOOR_INTERACT_DIST := 60.0

const FACING_TURN_SPEED_AIMING := 9.0   ## voltou de 6 pra 9 depois que manche/movimento foram desacoplados

var _staging_origin: Vector2
var _house_origin: Vector2

var player: CharacterBody2D
var _facing := Vector2.RIGHT
var _sprint_charge := 0.0
var _in_cover := false
var _peeking := false

var okafor_marker: Node2D
var theo_marker: Node2D

var briefing_zone: Area2D
var _briefed := false

var door_body: StaticBody2D
var door_open := false
var _breached_loud := false

var _wall_rects: Array[Rect2] = []

var threats: Array[Area2D] = []
var non_threats: Array[Area2D] = []
const THREAT_COUNT := 3
var _threats_hit := 0
var _non_threats_hit := 0

var story: Control
var status_label: Label
var fire_btn: Control
var breach_btn: Control
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> walk_to_briefing -> briefing -> approach_door -> clearing ->
## evaluation -> outro -> done

const SCENE_PATH := "res://missions/ato1_fase2_abordagem.tscn"

var _aim_end := Vector2.ZERO
var _aim_hit_threat := false
var _aim_valid := false


func _ready() -> void:
	_build_rooms()
	_build_player()
	_build_npcs()
	_build_briefing_zone()
	_build_door()
	_build_targets()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"Segundo dia de instrução. A sala de tiro deu lugar a um corredor estreito, com uma porta que não abre sozinha.",
			"Hoje não é sobre acertar rápido. É sobre decidir certo.",
		],
		["", ""]
	)


# ---------- construção da cena (caixas cinzas) ----------

func _build_rooms() -> void:
	_staging_origin = Vector2(80.0, 60.0)
	_house_origin = _staging_origin + Vector2(STAGING_SIZE.x, 0.0)

	_wall_rects.clear()
	var st := _staging_origin
	var h := _house_origin

	_wall_rects.append(Rect2(st, Vector2(STAGING_SIZE.x, WALL_THICK)))
	_wall_rects.append(Rect2(Vector2(st.x, st.y + STAGING_SIZE.y - WALL_THICK), Vector2(STAGING_SIZE.x, WALL_THICK)))
	_wall_rects.append(Rect2(st, Vector2(WALL_THICK, STAGING_SIZE.y)))

	var gap := st.y + STAGING_SIZE.y * 0.5 - DOOR_GAP * 0.5
	_wall_rects.append(Rect2(Vector2(st.x + STAGING_SIZE.x - WALL_THICK, st.y), Vector2(WALL_THICK, gap - st.y)))
	_wall_rects.append(Rect2(Vector2(st.x + STAGING_SIZE.x - WALL_THICK, gap + DOOR_GAP), Vector2(WALL_THICK, st.y + STAGING_SIZE.y - (gap + DOOR_GAP))))

	_wall_rects.append(Rect2(h, Vector2(HOUSE_SIZE.x, WALL_THICK)))
	_wall_rects.append(Rect2(Vector2(h.x, h.y + HOUSE_SIZE.y - WALL_THICK), Vector2(HOUSE_SIZE.x, WALL_THICK)))
	_wall_rects.append(Rect2(Vector2(h.x + HOUSE_SIZE.x - WALL_THICK, h.y), Vector2(WALL_THICK, HOUSE_SIZE.y)))

	# Obstáculo solto dentro da casa — obriga espiar/reposicionar pra ver
	# todos os alvos, em vez de mirar tudo de um canto só.
	_wall_rects.append(Rect2(h + Vector2(90, 220), Vector2(90, 90)))

	for wr in _wall_rects:
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

	var house_floor := Polygon2D.new()
	house_floor.polygon = PackedVector2Array([Vector2.ZERO, Vector2(HOUSE_SIZE.x - WALL_THICK * 2, 0), Vector2(HOUSE_SIZE.x - WALL_THICK * 2, HOUSE_SIZE.y - WALL_THICK * 2), Vector2(0, HOUSE_SIZE.y - WALL_THICK * 2)])
	house_floor.color = Color(0.2, 0.17, 0.15)
	house_floor.position = h + Vector2(WALL_THICK, WALL_THICK)
	house_floor.z_index = -1
	add_child(house_floor)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = _staging_origin + Vector2(50, STAGING_SIZE.y - 80)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_npcs() -> void:
	# Ficam parados aqui o tempo todo — não entram na casa de treinamento
	# com o Mark, só observam e avaliam quando ele termina.
	okafor_marker = Node2D.new()
	okafor_marker.position = _staging_origin + Vector2(140, 90)
	add_child(okafor_marker)

	theo_marker = Node2D.new()
	theo_marker.position = _staging_origin + Vector2(200, 90)
	add_child(theo_marker)


func _build_briefing_zone() -> void:
	briefing_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(150.0, 130.0)
	shape.shape = rect
	briefing_zone.add_child(shape)
	briefing_zone.position = _staging_origin + Vector2(170, 120)
	briefing_zone.monitorable = true
	briefing_zone.body_entered.connect(_on_briefing_zone_entered)
	add_child(briefing_zone)


func _build_door() -> void:
	door_body = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WALL_THICK, DOOR_GAP)
	shape.shape = rect
	door_body.add_child(shape)
	var gap := _staging_origin.y + STAGING_SIZE.y * 0.5 - DOOR_GAP * 0.5
	door_body.position = Vector2(_staging_origin.x + STAGING_SIZE.x - WALL_THICK * 0.5, gap + DOOR_GAP * 0.5)
	door_body.set_collision_layer_value(1, false)
	add_child(door_body)


func _build_targets() -> void:
	var h := _house_origin
	var threat_positions := [h + Vector2(250, 100), h + Vector2(360, 300), h + Vector2(140, 330)]
	var non_threat_positions := [h + Vector2(250, 220), h + Vector2(380, 130)]

	for pos in threat_positions:
		var t := Area2D.new()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 15.0
		shape.shape = circle
		t.add_child(shape)
		t.position = pos
		t.monitorable = true
		t.set_meta("hit", false)
		t.set_meta("is_threat", true)
		add_child(t)
		threats.append(t)

	for pos in non_threat_positions:
		var nt := Area2D.new()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 15.0
		shape.shape = circle
		nt.add_child(shape)
		nt.position = pos
		nt.monitorable = true
		nt.set_meta("hit", false)
		nt.set_meta("is_threat", false)
		add_child(nt)
		non_threats.append(nt)


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

	breach_btn = _action_button("breach", tr("ARROMBAR"), 30.0, 180.0, 100.0, 100.0)
	breach_btn.visible = false
	breach_btn.show_hold_progress = true
	layer.add_child(breach_btn)

	fire_btn = _action_button("shoot", tr("ATIRAR"), 30.0, 180.0, 100.0, 100.0)
	fire_btn.visible = false
	layer.add_child(fire_btn)


func _action_button(action: String, label: String, right: float, bottom: float, w: float, h: float) -> Control:
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
			_phase = "walk_to_briefing"
			_controls_locked = false
		"briefing":
			_phase = "approach_door"
			_controls_locked = false
		"evaluation":
			_phase = "outro"
			story.say(
				[
					"Fim da Fase 2 — Abordagem Tática.",
				],
				[""]
			)
		"outro":
			_phase = "done"
			next_btn.visible = true


func _on_briefing_zone_entered(body: Node) -> void:
	if body != player or _briefed or _phase != "walk_to_briefing":
		return
	_briefed = true
	_phase = "briefing"
	_controls_locked = true
	story.say(
		[
			"Hoje não é sobre atirar rápido. É sobre atirar certo. Tem gente inocente atrás dessa porta — nem tudo lá é ameaça.",
			"Aposto que o Reyes vai revisar o manual mental umas três vezes antes de decidir.",
			"Quieto, Marsh. Reyes, a porta é sua — devagar ou rápido, a escolha é sua. Mas a pontaria tem que ser sua também.",
		],
		["Capitã Okafor", "Theo Marsh", "Capitã Okafor"]
	)


func _update_door() -> void:
	if _phase != "approach_door":
		breach_btn.visible = false
		return
	var near := player.position.distance_to(door_body.position) < DOOR_INTERACT_DIST
	breach_btn.visible = near and not door_open
	if not breach_btn.visible:
		return
	if InputBridge.consume_just_released("breach"):
		var hold := InputBridge.last_hold_time("breach")
		door_open = true
		_breached_loud = hold <= 0.5
		_phase = "clearing"


func _check_clearing_complete() -> void:
	if _threats_hit < THREAT_COUNT or _phase != "clearing":
		return
	_phase = "evaluation"
	_controls_locked = true
	if _non_threats_hit > 0:
		story.say(
			[
				"Você atirou num civil, Reyes. Em campo isso não é erro de mira — é vida. Refaz esse raciocínio antes de voltar aqui.",
				"Isso não teve graça nenhuma.",
			],
			["Capitã Okafor", "Theo Marsh"]
		)
	elif _breached_loud:
		story.say(
			[
				"Três ameaças, zero baixas colaterais. Um pouco barulhenta a entrada, mas não errada.",
				"Só reclamo que você demorou mais que eu no estande, Reyes.",
			],
			["Capitã Okafor", "Theo Marsh"]
		)
	else:
		story.say(
			[
				"Três ameaças, zero baixas colaterais, entrada limpa. Isso é controle, recruta.",
				"Só reclamo que você demorou mais que eu no estande, Reyes.",
			],
			["Capitã Okafor", "Theo Marsh"]
		)


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	if not _controls_locked:
		_move_player(delta)
		_update_facing(delta)
		_update_cover_and_peek()
		_update_door()
		_update_aim_preview()
		_update_fire()
	else:
		_aim_valid = false
	_update_hud()
	queue_redraw()


func _move_player(delta: float) -> void:
	var move := InputBridge.move_vector
	var deflect := move.length()

	if deflect >= SPRINT_DEFLECT_THRESHOLD:
		_sprint_charge += delta
	else:
		_sprint_charge = max(0.0, _sprint_charge - SPRINT_CHARGE_DECAY * delta)

	var sprinting := _sprint_charge >= SPRINT_CHARGE_TIME
	var speed := SPEED_SPRINT if sprinting else SPEED_CAUTIOUS

	player.velocity = move * speed
	player.move_and_slide()


func _update_facing(delta: float) -> void:
	# Manches desacoplados: esquerdo só move, direito é o único jeito de
	# mudar a mira. Sem tocar o manche direito, a mira congela onde
	# estava (não segue mais a direção de movimento — isso deixava a
	# gameplay travada numa sala com mais alvos e obstáculo, como aqui).
	if InputBridge.aim_touching and InputBridge.aim_vector.length() > 0.15:
		var target_dir := InputBridge.aim_vector.normalized()
		var diff := wrapf(target_dir.angle() - _facing.angle(), -PI, PI)
		var max_step := FACING_TURN_SPEED_AIMING * delta
		_facing = _facing.rotated(clamp(diff, -max_step, max_step))


func _nearest_wall_distance() -> float:
	var best := INF
	for r in _wall_rects:
		var closest := Vector2(
			clamp(player.position.x, r.position.x, r.position.x + r.size.x),
			clamp(player.position.y, r.position.y, r.position.y + r.size.y)
		)
		best = min(best, player.position.distance_to(closest))
	return best


func _update_cover_and_peek() -> void:
	var dist := _nearest_wall_distance()
	_in_cover = dist <= COVER_DISTANCE
	_peeking = _in_cover and InputBridge.move_vector.length() > 0.15 and InputBridge.move_vector.length() < 0.6


## Ameaças/civis já atingidos entram na exclusão — sem isso, a mira parava
## num alvo já abatido em vez de passar pra o que estiver atrás dele.
func _fire_exclude() -> Array[RID]:
	var ex: Array[RID] = [player.get_rid()]
	for t in threats:
		if t.get_meta("hit"):
			ex.append(t.get_rid())
	for nt in non_threats:
		if nt.get_meta("hit"):
			ex.append(nt.get_rid())
	return ex


func _update_aim_preview() -> void:
	if _phase != "clearing":
		_aim_valid = false
		fire_btn.visible = false
		return
	fire_btn.visible = true

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
		_aim_hit_threat = false
	else:
		_aim_end = result.position
		var c = result.collider
		_aim_hit_threat = c is Area2D and (c in threats) and not c.get_meta("hit")


func _update_fire() -> void:
	if _phase != "clearing":
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
		return

	var collider = result.collider
	if collider is Area2D and collider in threats and not collider.get_meta("hit"):
		collider.set_meta("hit", true)
		_threats_hit += 1
		_check_clearing_complete()
	elif collider is Area2D and collider in non_threats and not collider.get_meta("hit"):
		collider.set_meta("hit", true)
		_non_threats_hit += 1


func _update_hud() -> void:
	match _phase:
		"walk_to_briefing":
			status_label.text = tr("Objetivo: vá até a Capitã Okafor.")
		"approach_door":
			status_label.text = tr("Objetivo: chegue na porta e segure ARROMBAR até o anel ficar AZUL pra entrar em silêncio (ou solte antes disso pra entrar com força).")
		"clearing":
			status_label.text = tr("Ameaças neutralizadas: %d/%d — cuidado com quem não é ameaça.") % [_threats_hit, THREAT_COUNT]
		"done":
			status_label.text = tr("Fase 2 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		var color := Color(0.9, 0.3, 0.3)
		if _in_cover:
			color = Color(0.3, 0.6, 0.9)
		if _peeking:
			color = Color(0.9, 0.8, 0.2)
		draw_circle(player.position, PLAYER_RADIUS, color)

		if _aim_valid:
			var line_color := Color(0.3, 1.0, 0.4, 0.8) if _aim_hit_threat else Color(1.0, 1.0, 1.0, 0.35)
			draw_dashed_line(player.position, _aim_end, line_color, 2.0, 10.0)
			draw_circle(_aim_end, 5.0, line_color)
		else:
			draw_line(player.position, player.position + _facing * (PLAYER_RADIUS + 24.0), Color.WHITE, 3.0)

		if _sprint_charge > 0.05 and _sprint_charge < SPRINT_CHARGE_TIME:
			var frac := _sprint_charge / SPRINT_CHARGE_TIME
			draw_arc(player.position, PLAYER_RADIUS + 7.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 24, Color.YELLOW, 3.0)

	if okafor_marker:
		draw_circle(okafor_marker.position, 15.0, Color(0.6, 0.2, 0.2))
		_draw_name_tag(okafor_marker.position, "Okafor")
	if theo_marker:
		draw_circle(theo_marker.position, 15.0, Color(0.2, 0.4, 0.6))
		_draw_name_tag(theo_marker.position, "Theo")

	if door_body:
		draw_circle(door_body.position, 8.0, Color.GREEN if door_open else Color(0.7, 0.15, 0.15))

	for t in threats:
		var hit: bool = t.get_meta("hit")
		draw_circle(t.position, 15.0, Color(0.2, 0.2, 0.2) if hit else Color(0.8, 0.2, 0.2))
		if not hit:
			_draw_name_tag(t.position, "Ameaça")

	for nt in non_threats:
		var hit: bool = nt.get_meta("hit")
		draw_circle(nt.position, 15.0, Color(0.9, 0.3, 0.1) if hit else Color(0.7, 0.8, 1.0))
		_draw_name_tag(nt.position, "Civil")


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
