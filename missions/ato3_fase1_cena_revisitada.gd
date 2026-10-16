extends Node2D
## Ato 3, Fase 1 — "A Cena Revisitada" (docs/ROTEIRO.md). Mark, agora
## detetive, reabre o apartamento do Incidente (Ato 2, Turno 6) com
## outros olhos. Examina a mesma pista (o roteador escondido) e agora
## enxerga o que não fechava. Curta de propósito — é a virada de modo de
## jogo (uniformizado -> investigador), não uma cena de ação.

const ROOM_SIZE := Vector2(420.0, 360.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0
const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const INTERACT_DIST := 55.0

var player: CharacterBody2D
var clue_obj: Area2D
var _examined := false

var examine_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> free_roam -> examined -> done

const SCENE_PATH := "res://missions/ato3_fase1_cena_revisitada.tscn"


func _ready() -> void:
	_build_room()
	_build_player()
	_build_clue()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"Semanas depois. O apartamento ainda tem fita de isolamento na porta, mas ninguém mais olha pra ele como cena de crime.",
			"Mark olha. É o trabalho dele agora — olhar pro que todo mundo já decidiu que não importa.",
		],
		["", ""]
	)


func _build_room() -> void:
	var o := ROOM_ORIGIN
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(ROOM_SIZE.x, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + ROOM_SIZE.y - WALL_THICK), Vector2(ROOM_SIZE.x, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, ROOM_SIZE.y)),
		Rect2(Vector2(o.x + ROOM_SIZE.x - WALL_THICK, o.y), Vector2(WALL_THICK, ROOM_SIZE.y)),
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
		poly.color = Color(0.28, 0.26, 0.28)
		poly.position = r.position
		add_child(poly)


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


func _build_clue() -> void:
	clue_obj = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	clue_obj.add_child(shape)
	clue_obj.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x - 100, 100)
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
	left_stick.anchor_right = 1.0
	left_stick.anchor_top = 0.0
	left_stick.anchor_bottom = 1.0
	layer.add_child(left_stick)

	examine_btn = Control.new()
	examine_btn.set_script(load("res://ui/contextual_button.gd"))
	examine_btn.action_name = "examine"
	examine_btn.label_text = tr("EXAMINAR")
	examine_btn.layout_slot = "acao_principal"
	examine_btn.anchor_left = 1.0
	examine_btn.anchor_right = 1.0
	examine_btn.anchor_top = 1.0
	examine_btn.anchor_bottom = 1.0
	examine_btn.offset_right = -30.0
	examine_btn.offset_left = -130.0
	examine_btn.offset_bottom = -30.0
	examine_btn.offset_top = -130.0
	examine_btn.visible = false
	layer.add_child(examine_btn)


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
			_phase = "free_roam"
			_controls_locked = false
		"examined":
			_phase = "done"
			next_btn.visible = true


func _check_examine() -> void:
	if _examined or _controls_locked:
		examine_btn.visible = false
		return
	var near := player.position.distance_to(clue_obj.position) < INTERACT_DIST
	examine_btn.visible = near
	if near and InputBridge.consume_just_pressed("examine"):
		_examined = true
		examine_btn.visible = false
		_phase = "examined"
		_controls_locked = true
		story.say(
			[
				"O roteador de novo. Da primeira vez, Mark só fotografou. Agora ele vira o objeto na mão, procura número de série, procura QUALQUER coisa.",
				"Não é equipamento de casa. É profissional — do tipo que serve pra captar sinal de muito longe, não pra assistir TV a cabo.",
				"Alguém monitorava esse quarteirão antes do Doyle levar aquele tiro. E ninguém perguntou por quê.",
				"Fim da Fase 1 — A Cena Revisitada.",
			],
			["", "", "", ""]
		)


func _process(_delta: float) -> void:
	if not _controls_locked:
		_move_player()
		_check_examine()
	_update_hud()
	queue_redraw()


func _move_player() -> void:
	player.velocity = InputBridge.move_vector * SPEED_CAUTIOUS
	player.move_and_slide()


func _update_hud() -> void:
	match _phase:
		"free_roam":
			status_label.text = tr("Objetivo: examine a pista.")
		"done":
			status_label.text = tr("Fase 1 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
	if clue_obj:
		draw_circle(clue_obj.position, 16.0, Color(0.2, 0.2, 0.2) if _examined else Color(0.9, 0.8, 0.3))
