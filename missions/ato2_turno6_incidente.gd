extends Node2D
## Ato 2, Turno 6 — "O Incidente" (docs/ROTEIRO.md). Fecha o Ato 2 e abre
## o gancho pro Ato 3: um chamado de rotina dá errado, o Doyle é ferido
## em serviço (evento narrado/roteirizado, não algo que o jogador possa
## "falhar" em evitar — ROTEIRO é explícito que na hora parece só um
## risco do ofício), o Mark neutraliza a ameaça (reaproveita mira/tiro
## por raycast já validado) e depois **examina a cena** — encontra um
## detalhe que não fecha, plantando a semente que só vai fazer sentido
## no Ato 3. Isso chama atenção da Capitã Okafor e transfere o Mark pra
## Investigações.

const ROOM_SIZE := Vector2(460.0, 380.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0
const DOOR_GAP := 90.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const PARTNER_FOLLOW_SPEED := 85.0
const PARTNER_FOLLOW_DIST := 50.0
const FIRE_RANGE := 900.0
const INTERACT_DIST := 55.0

var player: CharacterBody2D
var doyle_marker: Node2D
var _doyle_following := true
var _doyle_down := false

var door_body: StaticBody2D
var door_open := false

var threat: Area2D
var threat_hit := false

var clue_obj: Area2D
var _clue_examined := false

var _facing := Vector2.RIGHT
const FACING_TURN_SPEED_AIMING := 9.0

var fire_btn: Control
var breach_btn: Control
var examine_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> approach -> breach -> ambush -> fight -> aftermath -> examine -> outro -> done

const SCENE_PATH := "res://missions/ato2_turno6_incidente.tscn"

var _aim_end := Vector2.ZERO
var _aim_hit_threat := false
var _aim_valid := false


func _ready() -> void:
	_build_room()
	_build_player()
	_build_doyle()
	_build_door()
	_build_threat()
	_build_clue()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"\"Desentendimento familiar, sem feridos reportados.\" Chamado número duzentos e tantos da semana — o tipo que ninguém mais presta atenção.",
			"Doyle nem checa o colete direito antes de descer da viatura. \"Esses são sempre rápidos\", ele diz. Vai ser a última coisa tranquila que ele diz hoje.",
		],
		["", ""]
	)


# ---------- construção da cena ----------

func _build_room() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(w, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + h - WALL_THICK), Vector2(w, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, h)),
	]
	var gap := o.y + h * 0.5 - DOOR_GAP * 0.5
	rects.append(Rect2(Vector2(o.x + w - WALL_THICK, o.y), Vector2(WALL_THICK, gap - o.y)))
	rects.append(Rect2(Vector2(o.x + w - WALL_THICK, gap + DOOR_GAP), Vector2(WALL_THICK, o.y + h - (gap + DOOR_GAP))))

	# Segundo cômodo (onde a emboscada acontece) — sem isso, a ameaça e a
	# pista ficavam numa área aberta sem parede nenhuma.
	var o2 := o + Vector2(w, 0)
	var w2 := 380.0
	rects.append(Rect2(o2, Vector2(w2, WALL_THICK)))
	rects.append(Rect2(Vector2(o2.x, o2.y + h - WALL_THICK), Vector2(w2, WALL_THICK)))
	rects.append(Rect2(Vector2(o2.x + w2 - WALL_THICK, o2.y), Vector2(WALL_THICK, h)))

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
		poly.color = Color(0.3, 0.28, 0.3)
		poly.position = r.position
		add_child(poly)

	var floor2 := Polygon2D.new()
	floor2.polygon = PackedVector2Array([Vector2.ZERO, Vector2(w2 - WALL_THICK * 2, 0), Vector2(w2 - WALL_THICK * 2, h - WALL_THICK * 2), Vector2(0, h - WALL_THICK * 2)])
	floor2.color = Color(0.2, 0.16, 0.18)
	floor2.position = o2 + Vector2(WALL_THICK, WALL_THICK)
	floor2.z_index = -1
	add_child(floor2)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 80)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_doyle() -> void:
	doyle_marker = Node2D.new()
	doyle_marker.position = player.position + Vector2(-30, 0)
	add_child(doyle_marker)


func _build_door() -> void:
	door_body = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WALL_THICK, DOOR_GAP)
	shape.shape = rect
	door_body.add_child(shape)
	var gap := ROOM_ORIGIN.y + ROOM_SIZE.y * 0.5 - DOOR_GAP * 0.5
	door_body.position = Vector2(ROOM_ORIGIN.x + ROOM_SIZE.x - WALL_THICK * 0.5, gap + DOOR_GAP * 0.5)
	door_body.set_collision_layer_value(1, false)
	add_child(door_body)


func _build_threat() -> void:
	threat = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0
	shape.shape = circle
	threat.add_child(shape)
	threat.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x + 160, ROOM_SIZE.y * 0.5)
	threat.monitorable = true
	add_child(threat)


func _build_clue() -> void:
	clue_obj = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	clue_obj.add_child(shape)
	clue_obj.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x + 260, ROOM_SIZE.y * 0.3)
	clue_obj.monitorable = true
	add_child(clue_obj)


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
	breach_btn.show_hold_progress = true
	breach_btn.visible = false
	layer.add_child(breach_btn)

	fire_btn = _action_button("shoot", tr("ATIRAR"), 30.0, 180.0, 100.0, 100.0)
	fire_btn.visible = false
	layer.add_child(fire_btn)

	examine_btn = _action_button("examine", tr("EXAMINAR"), 30.0, 180.0, 100.0, 100.0)
	examine_btn.visible = false
	layer.add_child(examine_btn)


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


# ---------- fluxo ----------

func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "approach"
			_controls_locked = false
		"ambush":
			_phase = "fight"
			_controls_locked = false
		"aftermath":
			_phase = "examine"
			_controls_locked = false
		"outro":
			_phase = "done"
			next_btn.visible = true


func _update_door() -> void:
	if _phase != "approach":
		breach_btn.visible = false
		return
	var near := player.position.distance_to(door_body.position) < 60.0
	breach_btn.visible = near and not door_open
	if not breach_btn.visible:
		return
	if InputBridge.consume_just_released("breach"):
		door_open = true
		_phase = "ambush"
		_controls_locked = true
		_doyle_down = true
		story.say(
			[
				"A porta cede. Lá dentro, não tem casal brigando — tem um homem armado, de costas, e ele vira rápido demais pro Doyle reagir primeiro.",
				"Um tiro. Doyle cai contra a parede, mão no ombro, ainda tentando gritar um aviso que já chegou tarde.",
				"Mark não tem tempo de ter medo.",
			],
			["", "", ""]
		)


func _check_fire() -> void:
	if _phase != "fight":
		fire_btn.visible = false
		return
	fire_btn.visible = true

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
		_aim_hit_threat = (result.collider == threat) and not threat_hit

	if InputBridge.consume_just_pressed("shoot") and not result.is_empty() and result.collider == threat and not threat_hit:
		threat_hit = true
		_phase = "aftermath"
		_controls_locked = true
		story.say(
			[
				"A ameaça cai. Mark já está correndo pro Doyle antes mesmo de guardar a arma.",
				"\"Tô bem, tô bem\" — ele não está, mas a voz ainda sai firme. Mark pede reforço e ambulância antes de pensar em respirar de novo.",
				"Enquanto espera, alguma coisa na sala continua incomodando o Mark. Fora de lugar.",
			],
			["", "Sgt. Doyle", ""]
		)


func _check_examine() -> void:
	if _clue_examined or _phase != "examine":
		examine_btn.visible = false
		return
	var near := player.position.distance_to(clue_obj.position) < INTERACT_DIST
	examine_btn.visible = near
	if near and InputBridge.consume_just_pressed("examine"):
		_clue_examined = true
		examine_btn.visible = false
		_phase = "outro"
		_controls_locked = true
		story.say(
			[
				"Um roteador pequeno, escondido atrás do que devia ser só uma briga de família. Não combina com nada no resto do apartamento.",
				"Mark fotografa antes de mexer em qualquer coisa. Não sabe o que é — só sabe que não devia estar ali.",
				"Dias depois, Okafor lê o relatório duas vezes. \"Isso é faro de detetive, Reyes. Vem comigo.\"",
				"Doyle vai ficar bem — semanas de afastamento, não mais que isso. Mas o turno que era dos dois agora é só do Mark.",
				"Fim do Turno 6 — O Incidente. Fim do Ato 2 — Novato nas Ruas.",
				"Ato 3 (Emblema de Detetive) ainda não foi construído.",
			],
			["", "", "Capitã Okafor", "", "", ""]
		)


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	if not _controls_locked:
		_move_player()
		_update_facing(delta)
	_update_door()
	_check_fire()
	_check_examine()
	if _doyle_following and not _doyle_down:
		_update_doyle_follow(delta)
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


func _update_doyle_follow(delta: float) -> void:
	var to_player := player.position - doyle_marker.position
	if to_player.length() > PARTNER_FOLLOW_DIST:
		doyle_marker.position = doyle_marker.position.move_toward(player.position, PARTNER_FOLLOW_SPEED * delta)


func _update_hud() -> void:
	match _phase:
		"approach":
			status_label.text = tr("Objetivo: chegue na porta e arrombe.")
		"fight":
			status_label.text = tr("Neutralize a ameaça.")
		"examine":
			status_label.text = tr("Objetivo: examine a cena antes de ir embora.")
		"done":
			status_label.text = tr("Turno 6 concluído. Fim do Ato 2.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
		if _phase == "fight" and _aim_valid:
			var line_color := Color(0.3, 1.0, 0.4, 0.8) if _aim_hit_threat else Color(1.0, 1.0, 1.0, 0.35)
			draw_dashed_line(player.position, _aim_end, line_color, 2.0, 10.0)
			draw_circle(_aim_end, 5.0, line_color)
		else:
			draw_line(player.position, player.position + _facing * (PLAYER_RADIUS + 24.0), Color.WHITE, 3.0)

	if doyle_marker:
		draw_circle(doyle_marker.position, 15.0, Color(0.3, 0.3, 0.3) if _doyle_down else Color(0.5, 0.35, 0.15))
		_draw_name_tag(doyle_marker.position, "Doyle")

	if door_body:
		draw_circle(door_body.position, 8.0, Color.GREEN if door_open else Color(0.7, 0.15, 0.15))

	if threat and door_open:
		draw_circle(threat.position, 15.0, Color(0.2, 0.2, 0.2) if threat_hit else Color(0.8, 0.2, 0.2))

	if clue_obj and threat_hit:
		draw_circle(clue_obj.position, 10.0, Color(0.2, 0.2, 0.2) if _clue_examined else Color(0.9, 0.8, 0.3))


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
