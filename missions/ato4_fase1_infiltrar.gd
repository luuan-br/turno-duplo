extends Node2D
## Ato 4, Fase 1 — "Infiltrar o Cais" (docs/ROTEIRO.md). Abre o Ato 4:
## depois de responder junto no ataque à família (fim do Ato 3), o Theo
## Marsh assume oficialmente como parceiro de ação — o Doyle está fora
## de combate (literal e narrativamente, dependendo do `doyle_fate` da
## Fase 6 do Ato 3). Primeira vez que o jogador enfrenta ameaças reais
## de Kessler (não treino, não suspeito isolado) — tom sobe de vez.
## Reaproveita o controlador tático validado (regra dos três já estourada
## de propósito, ver CLAUDE.md — 4ª cópia, mas Ato 4 é a hora de "soltar
## a mão" com o que já foi ensinado, não de reinventar).

const YARD_SIZE := Vector2(480.0, 380.0)
const YARD_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0
const GATE_GAP := 90.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const PARTNER_FOLLOW_SPEED := 85.0
const PARTNER_FOLLOW_DIST := 50.0
const FIRE_RANGE := 900.0

var player: CharacterBody2D
var theo_marker: Node2D

var gate_body: StaticBody2D
var gate_open := false

var threat_a: Area2D
var threat_a_hit := false
var threat_b: Area2D
var threat_b_hit := false

var _facing := Vector2.RIGHT
const FACING_TURN_SPEED_AIMING := 9.0

var fire_btn: Control
var breach_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> approach -> breach -> fight_a -> between -> fight_b -> outro -> done

var _aim_end := Vector2.ZERO
var _aim_hit_threat := false
var _aim_valid := false

const SCENE_PATH := "res://missions/ato4_fase1_infiltrar.tscn"


func _ready() -> void:
	_build_yard()
	_build_player()
	_build_theo()
	_build_gate()
	_build_threats()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O Cais à noite não devia estar tão quieto. Sem guindaste rodando, sem rádio de trabalhador, só o som do próprio mar.",
			"Theo checa a arma pela terceira vez. \"Doyle não tá aqui. Hoje sou eu.\" Não é brincadeira — é um FTO de novo, só que invertido.",
			"\"Kessler isolou o quarteirão inteiro — câmera, semáforo, rádio. Então a gente é o único reforço que existe agora.\"",
		],
		["", "Theo Marsh", "Theo Marsh"]
	)


func _build_yard() -> void:
	var o := YARD_ORIGIN
	var w := YARD_SIZE.x
	var h := YARD_SIZE.y
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(w, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + h - WALL_THICK), Vector2(w, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, h)),
	]
	var gap := o.y + h * 0.5 - GATE_GAP * 0.5
	rects.append(Rect2(Vector2(o.x + w - WALL_THICK, o.y), Vector2(WALL_THICK, gap - o.y)))
	rects.append(Rect2(Vector2(o.x + w - WALL_THICK, gap + GATE_GAP), Vector2(WALL_THICK, o.y + h - (gap + GATE_GAP))))

	var o2 := o + Vector2(w, 0)
	var w2 := 420.0
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
		poly.color = Color(0.16, 0.18, 0.22)
		poly.position = r.position
		add_child(poly)

	var floor2 := Polygon2D.new()
	floor2.polygon = PackedVector2Array([Vector2.ZERO, Vector2(w2 - WALL_THICK * 2, 0), Vector2(w2 - WALL_THICK * 2, h - WALL_THICK * 2), Vector2(0, h - WALL_THICK * 2)])
	floor2.color = Color(0.1, 0.11, 0.14)
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
	player.position = YARD_ORIGIN + Vector2(60, YARD_SIZE.y - 70)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_theo() -> void:
	theo_marker = Node2D.new()
	theo_marker.position = player.position + Vector2(-30, 0)
	add_child(theo_marker)


func _build_gate() -> void:
	gate_body = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WALL_THICK, GATE_GAP)
	shape.shape = rect
	gate_body.add_child(shape)
	var gap := YARD_ORIGIN.y + YARD_SIZE.y * 0.5 - GATE_GAP * 0.5
	gate_body.position = Vector2(YARD_ORIGIN.x + YARD_SIZE.x - WALL_THICK * 0.5, gap + GATE_GAP * 0.5)
	gate_body.set_collision_layer_value(1, false)
	add_child(gate_body)


func _build_threats() -> void:
	threat_a = Area2D.new()
	var s1 := CollisionShape2D.new()
	var c1 := CircleShape2D.new()
	c1.radius = 15.0
	s1.shape = c1
	threat_a.add_child(s1)
	threat_a.position = YARD_ORIGIN + Vector2(YARD_SIZE.x + 150, YARD_SIZE.y * 0.3)
	threat_a.monitorable = true
	add_child(threat_a)

	threat_b = Area2D.new()
	var s2 := CollisionShape2D.new()
	var c2 := CircleShape2D.new()
	c2.radius = 15.0
	s2.shape = c2
	threat_b.add_child(s2)
	threat_b.position = YARD_ORIGIN + Vector2(YARD_SIZE.x + 320, YARD_SIZE.y * 0.7)
	threat_b.monitorable = true
	add_child(threat_b)


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


func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "approach"
			_controls_locked = false
		"breach":
			_phase = "fight_a"
			_controls_locked = false
		"between":
			_phase = "fight_b"
			_controls_locked = false
		"outro":
			_phase = "done"
			next_btn.visible = true


func _update_gate() -> void:
	if _phase != "approach":
		breach_btn.visible = false
		return
	var near := player.position.distance_to(gate_body.position) < 60.0
	breach_btn.visible = near and not gate_open
	if not breach_btn.visible:
		return
	if InputBridge.consume_just_released("breach"):
		gate_open = true
		_phase = "breach"
		_controls_locked = true
		story.say(
			[
				"O portão lateral cede sem muito esforço — alguém já tinha arrombado antes e nem se deu ao trabalho de disfarçar.",
				"Dois homens de colete tático cortam o caminho, armados, sem farda de empresa nenhuma. Não são seguranças. São música de fundo da operação de Kessler.",
			],
			["", ""]
		)


func _check_fire() -> void:
	if _phase != "fight_a" and _phase != "fight_b":
		fire_btn.visible = false
		return
	fire_btn.visible = true

	var active_threat: Area2D = threat_a if _phase == "fight_a" else threat_b
	var already_hit: bool = threat_a_hit if _phase == "fight_a" else threat_b_hit
	if already_hit:
		return

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
			story.say(
				[
					"Um cai. O outro berra alguma coisa num rádio curto, mas ninguém responde — o rádio deles também tá falhando, pela primeira vez a vantagem é do Mark.",
				],
				[""]
			)
		else:
			threat_b_hit = true
			_phase = "outro"
			_controls_locked = true
			story.say(
				[
					"O segundo cai perto o bastante da cerca pra Theo confirmar: equipamento caro, treino de verdade, nada de amador.",
					"\"Isso não é golpe de rua\", Theo diz, baixo. \"Isso é operação militar paga.\"",
					"Mark já sabia. Mas ouvir alguém mais dizer em voz alta torna real.",
					"Fim da Fase 1 — Infiltrar o Cais.",
				],
				["", "Theo Marsh", "", ""]
			)


func _process(delta: float) -> void:
	if not _controls_locked:
		_move_player()
		_update_facing(delta)
	_update_gate()
	_check_fire()
	_update_theo_follow(delta)
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


func _update_theo_follow(delta: float) -> void:
	var to_player := player.position - theo_marker.position
	if to_player.length() > PARTNER_FOLLOW_DIST:
		theo_marker.position = theo_marker.position.move_toward(player.position, PARTNER_FOLLOW_SPEED * delta)


func _update_hud() -> void:
	match _phase:
		"approach":
			status_label.text = tr("Objetivo: chegue no portão e arrombe.")
		"fight_a", "fight_b":
			status_label.text = tr("Neutralize a ameaça.")
		"done":
			status_label.text = tr("Fase 1 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
		if (_phase == "fight_a" or _phase == "fight_b") and _aim_valid:
			var line_color := Color(0.3, 1.0, 0.4, 0.8) if _aim_hit_threat else Color(1.0, 1.0, 1.0, 0.35)
			draw_dashed_line(player.position, _aim_end, line_color, 2.0, 10.0)
			draw_circle(_aim_end, 5.0, line_color)
		else:
			draw_line(player.position, player.position + _facing * (PLAYER_RADIUS + 24.0), Color.WHITE, 3.0)

	if theo_marker:
		draw_circle(theo_marker.position, 15.0, Color(0.2, 0.45, 0.3))
		_draw_name_tag(theo_marker.position, "Theo")

	if gate_body:
		draw_circle(gate_body.position, 8.0, Color.GREEN if gate_open else Color(0.7, 0.15, 0.15))

	if threat_a and gate_open:
		draw_circle(threat_a.position, 15.0, Color(0.2, 0.2, 0.2) if threat_a_hit else Color(0.8, 0.2, 0.2))
	if threat_b and threat_a_hit:
		draw_circle(threat_b.position, 15.0, Color(0.2, 0.2, 0.2) if threat_b_hit else Color(0.8, 0.2, 0.2))


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
