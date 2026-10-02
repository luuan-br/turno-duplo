extends Node2D
## Ato 4, Fase 3 — "Extração" (docs/ROTEIRO.md). Desvio pessoal: Sarah e
## Emma estão em perigo direto, e Mark interrompe a caçada a Kessler pra
## tirá-las de risco — o clímax pessoal do jogo, contrapeso ao clímax
## público do Cofre/Arquiteto que vem depois. Reaproveita o controlador
## tático validado (mesma ressalva da Fase 1 — ato 4 reaproveita de
## propósito em vez de reinventar) e fecha com o botão "LIBERTAR"
## genérico, no mesmo padrão do "EXAMINAR"/"ABRIR" já usado nos atos
## anteriores.

const ROOM_SIZE := Vector2(460.0, 360.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const PARTNER_FOLLOW_SPEED := 85.0
const PARTNER_FOLLOW_DIST := 50.0
const FIRE_RANGE := 900.0
const INTERACT_DIST := 55.0

var player: CharacterBody2D
var theo_marker: Node2D

var threat: Area2D
var threat_hit := false

var family_obj: Area2D
var _rescued := false

var _facing := Vector2.RIGHT
const FACING_TURN_SPEED_AIMING := 9.0

var fire_btn: Control
var rescue_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> fight -> aftermath -> rescue -> outro -> done

var _aim_end := Vector2.ZERO
var _aim_hit_threat := false
var _aim_valid := false

const SCENE_PATH := "res://missions/ato4_fase3_extracao.tscn"


func _ready() -> void:
	_build_room()
	_build_player()
	_build_theo()
	_build_threat()
	_build_family()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O rádio de Mark cospe estática e, no meio dela, a voz de um dos homens de Kessler — um erro de canal, não mensagem pra ele.",
			"\"A casa dos Reyes, segundo grupo. Mantém elas aí até a gente confirmar o Cofre.\"",
			"Mark já está correndo antes do Theo terminar de processar a frase. \"Vai\", Theo diz. \"Eu seguro o resto sozinho se precisar.\"",
		],
		["", "", "Theo Marsh"]
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
		poly.color = Color(0.26, 0.22, 0.24)
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

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_theo() -> void:
	theo_marker = Node2D.new()
	theo_marker.position = player.position + Vector2(-30, 0)
	add_child(theo_marker)


func _build_threat() -> void:
	threat = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0
	shape.shape = circle
	threat.add_child(shape)
	threat.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.5, ROOM_SIZE.y * 0.3)
	threat.monitorable = true
	add_child(threat)


func _build_family() -> void:
	family_obj = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	family_obj.add_child(shape)
	family_obj.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x - 90, ROOM_SIZE.y - 90)
	family_obj.monitorable = true
	add_child(family_obj)


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

	rescue_btn = _action_button("rescue", tr("LIBERTAR"), 30.0, 180.0, 100.0, 100.0)
	rescue_btn.show_hold_progress = true
	rescue_btn.visible = false
	layer.add_child(rescue_btn)


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
			_phase = "fight"
			_controls_locked = false
		"aftermath":
			_phase = "rescue"
			_controls_locked = false
		"outro":
			_phase = "done"
			next_btn.visible = true


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
				"O homem cai antes de ouvir o Mark entrar. Não teve tempo de reagir — nem de avisar os outros.",
				"Do fundo do corredor, uma voz abafada, presa atrás de uma porta: \"Mark?! MARK?!\" — Sarah, tentando não gritar e falhando.",
			],
			["", "Sarah Reyes"]
		)


func _check_rescue() -> void:
	if _rescued or _phase != "rescue":
		rescue_btn.visible = false
		return
	var near := player.position.distance_to(family_obj.position) < INTERACT_DIST
	rescue_btn.visible = near
	if near and InputBridge.consume_just_released("rescue"):
		_rescued = true
		rescue_btn.visible = false
		_phase = "outro"
		_controls_locked = true
		story.say(
			[
				"A corda cede fácil — amadores, pressa, não crueldade específica. Sarah abraça Mark antes mesmo de ele guardar a arma.",
				"Emma não solta a camisa dele. Não chora. Só segura, com a força de quem decidiu não deixar ir de novo.",
				"\"Vocês estão seguras agora\", Mark diz — e pela primeira vez em muito tempo, acredita na própria frase.",
				"Mas o trabalho não acabou. Em algum lugar do Cais, o Cofre ainda está aberto.",
				"Fim da Fase 3 — Extração.",
			],
			["", "", "", "", ""]
		)


func _process(delta: float) -> void:
	if not _controls_locked:
		_move_player()
		_update_facing(delta)
	_check_fire()
	_check_rescue()
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
	if _phase == "intro":
		return
	var to_player := player.position - theo_marker.position
	if to_player.length() > PARTNER_FOLLOW_DIST * 3.0:
		return # Theo ficou pra trás cobrindo o resto — não teleporta atrás do Mark na extração.
	if to_player.length() > PARTNER_FOLLOW_DIST:
		theo_marker.position = theo_marker.position.move_toward(player.position, PARTNER_FOLLOW_SPEED * delta)


func _update_hud() -> void:
	match _phase:
		"fight":
			status_label.text = tr("Neutralize a ameaça.")
		"rescue":
			status_label.text = tr("Objetivo: chegue até a Sarah e a Emma e liberte elas.")
		"done":
			status_label.text = tr("Fase 3 concluída.")
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

	if theo_marker and _phase != "rescue" and _phase != "outro" and _phase != "done":
		draw_circle(theo_marker.position, 15.0, Color(0.2, 0.45, 0.3))
		_draw_name_tag(theo_marker.position, "Theo")

	if threat:
		draw_circle(threat.position, 15.0, Color(0.2, 0.2, 0.2) if threat_hit else Color(0.8, 0.2, 0.2))

	if family_obj and threat_hit:
		draw_circle(family_obj.position, 18.0, Color(0.3, 0.7, 0.4) if _rescued else Color(0.85, 0.75, 0.3))


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
