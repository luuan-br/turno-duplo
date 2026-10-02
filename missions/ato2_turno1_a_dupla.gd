extends Node2D
## Ato 2, Turno 1 — "A Dupla" (docs/ROTEIRO.md). Primeiro turno de Mark
## com o Doyle em Ironside. Doyle se apresenta (cínico, engraçado) e
## depois vira **companheiro que segue o jogador** (primeira vez — segue
## com atraso/lag simples via `move_toward`, não é pathfinding de
## verdade, mesmo espírito dos NPCs guiados das fases do Ato 1).
##
## Introduz o **medidor de reputação** (GDD Seção 9): uma abordagem de
## trânsito termina numa escolha binária (`ui/choice_prompt.gd`, novo —
## de-escalar vs. autoridade) que ajusta `GameState.reputation`. Não é o
## Modo Diálogo completo (ainda não prototipado) — só o necessário pra
## uma decisão alimentar um medidor que atravessa os próximos turnos.

const STREET_SIZE := Vector2(760.0, 400.0)
const STREET_ORIGIN := Vector2(60.0, 60.0)
const WALL_THICK := 20.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const PARTNER_FOLLOW_SPEED := 85.0
const PARTNER_FOLLOW_DIST := 50.0

var player: CharacterBody2D
var doyle_marker: Node2D
var _doyle_following := false

var greet_zone: Area2D
var _greeted := false

var car_zone: Area2D
var _stop_started := false

var story: Control
var choice: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> walk_to_doyle -> greet -> walk_to_car -> stop -> choice ->
## outcome -> done

const SCENE_PATH := "res://missions/ato2_turno1_a_dupla.tscn"


func _ready() -> void:
	_build_street()
	_build_player()
	_build_doyle()
	_build_greet_zone()
	_build_car_zone()
	_build_hud()
	_build_controls()
	_build_story_box()
	_build_choice()

	story.say(
		[
			"Ironside. Primeiro turno de verdade — sem instrutor observando, sem nota no fim do dia.",
			"Só o rádio, a viatura, e o cara que vai te ensinar o que a Academia não ensina.",
		],
		["", ""]
	)


# ---------- construção da cena (caixa cinza) ----------

func _build_street() -> void:
	var o := STREET_ORIGIN
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(STREET_SIZE.x, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + STREET_SIZE.y - WALL_THICK), Vector2(STREET_SIZE.x, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, STREET_SIZE.y)),
		Rect2(Vector2(o.x + STREET_SIZE.x - WALL_THICK, o.y), Vector2(WALL_THICK, STREET_SIZE.y)),
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
		poly.color = Color(0.3, 0.3, 0.33)
		poly.position = r.position
		add_child(poly)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = STREET_ORIGIN + Vector2(60, STREET_SIZE.y - 80)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_doyle() -> void:
	doyle_marker = Node2D.new()
	doyle_marker.position = STREET_ORIGIN + Vector2(150, STREET_SIZE.y - 80)
	add_child(doyle_marker)


func _build_greet_zone() -> void:
	greet_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(130.0, 130.0)
	shape.shape = rect
	greet_zone.add_child(shape)
	greet_zone.position = STREET_ORIGIN + Vector2(150, STREET_SIZE.y - 80)
	greet_zone.monitorable = true
	greet_zone.body_entered.connect(_on_greet_entered)
	add_child(greet_zone)


func _build_car_zone() -> void:
	car_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(140.0, 140.0)
	shape.shape = rect
	car_zone.add_child(shape)
	car_zone.position = STREET_ORIGIN + Vector2(STREET_SIZE.x - 140, 150)
	car_zone.monitorable = true
	car_zone.body_entered.connect(_on_car_entered)
	add_child(car_zone)


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


func _build_story_box() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	story = Control.new()
	story.set_script(load("res://ui/story_box.gd"))
	layer.add_child(story)
	story.finished.connect(_on_story_finished)


func _build_choice() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	choice = Control.new()
	choice.set_script(load("res://ui/choice_prompt.gd"))
	layer.add_child(choice)
	choice.chosen.connect(_on_choice_made)


# ---------- fluxo da fase ----------

func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "walk_to_doyle"
			_controls_locked = false
		"greet":
			_phase = "walk_to_car"
			_controls_locked = false
			_doyle_following = true
		"stop":
			_phase = "choice"
			choice.ask(
				"O motorista passou do sinal e está nervoso, falando alto. Como Mark conduz a abordagem?",
				["De-escalar", "Impor autoridade"]
			)
		"outcome":
			_phase = "done"
			next_btn.visible = true


func _on_greet_entered(body: Node) -> void:
	if body != player or _greeted or _phase != "walk_to_doyle":
		return
	_greeted = true
	_phase = "greet"
	_controls_locked = true
	story.say(
		[
			"Sgt. Ray Doyle. Dezoito anos de rua — e pelo visual, nenhuma vontade de voltar pra sala de aula.",
			"Reyes, né? Relaxa, eu não mordo. Só não espera que eu siga o manual à risca o turno inteiro.",
			"Entra. Primeira parada já apareceu no rádio.",
		],
		["", "Sgt. Doyle", "Sgt. Doyle"]
	)


func _on_car_entered(body: Node) -> void:
	if body != player or _stop_started or _phase != "walk_to_car":
		return
	_stop_started = true
	_phase = "stop"
	_controls_locked = true
	story.say(
		[
			"Um carro parado na contramão, pisca ligado. O motorista já está de cabeça pra fora da janela, discutindo antes de vocês chegarem perto.",
			"Sua parada, novato. Eu cubro.",
		],
		["", "Sgt. Doyle"]
	)


func _on_choice_made(index: int) -> void:
	_phase = "outcome"
	_controls_locked = true
	if index == 0:
		GameState.add_reputation(1)
		story.say(
			[
				"Mark baixa o tom, deixa o homem desabafar antes de pedir a documentação. Funciona — a raiva perde o alvo.",
				"Nada mal. Metade dos novatos só sabe gritar mais alto que o motorista.",
				"Fim do Turno 1 — A Dupla.",
			],
			["", "Sgt. Doyle", ""]
		)
	else:
		GameState.add_reputation(-1)
		story.say(
			[
				"Mark corta a conversa, tom firme, documentação na mão. O motorista obedece — calado, mas obedece.",
				"Resolveu rápido. Só não é assim que se faz amigo no bairro, Reyes.",
				"Fim do Turno 1 — A Dupla.",
			],
			["", "Sgt. Doyle", ""]
		)


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	if not _controls_locked:
		_move_player()
	if _doyle_following:
		_update_doyle_follow(delta)
	_update_hud()
	queue_redraw()


func _move_player() -> void:
	player.velocity = InputBridge.move_vector * SPEED_CAUTIOUS
	player.move_and_slide()


func _update_doyle_follow(delta: float) -> void:
	var to_player := player.position - doyle_marker.position
	if to_player.length() > PARTNER_FOLLOW_DIST:
		doyle_marker.position = doyle_marker.position.move_toward(player.position, PARTNER_FOLLOW_SPEED * delta)


func _update_hud() -> void:
	match _phase:
		"walk_to_doyle":
			status_label.text = tr("Objetivo: vá até o Sgt. Doyle.")
		"walk_to_car":
			status_label.text = tr("Objetivo: siga até o carro parado.")
		"done":
			status_label.text = tr("Turno 1 concluído. Reputação: %d") % GameState.reputation
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
	if doyle_marker:
		draw_circle(doyle_marker.position, 15.0, Color(0.5, 0.35, 0.15))
		_draw_name_tag(doyle_marker.position, "Doyle")
	if car_zone:
		draw_rect(Rect2(car_zone.position - Vector2(24, 14), Vector2(48, 28)), Color(0.5, 0.5, 0.2))


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
