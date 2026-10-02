extends Node2D
## Ato 2, Turno 5 — "Fora de Serviço" (docs/ROTEIRO.md). Cena opcional de
## bar com o Doyle (alimenta `GameState.doyle_relationship` via
## `ui/choice_prompt.gd`) e o Theo Marsh aparece de passagem, já em outro
## distrito — a rivalidade da Academia virando provocação amigável entre
## colegas de farda. Narrativa, sem combate/direção, igual a Ato 1 Fase 4:
## não tem mecânica nova pra ensinar aqui, só peso de personagem.

const BAR_SIZE := Vector2(480.0, 360.0)
const BAR_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0

var player: CharacterBody2D
var doyle_marker: Node2D
var theo_marker: Node2D

var table_zone: Area2D
var _sat_down := false

var story: Control
var choice: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> walk_to_table -> setup -> choice -> outcome -> theo -> done

const SCENE_PATH := "res://missions/ato2_turno5_fora_de_servico.tscn"


func _ready() -> void:
	_build_bar()
	_build_player()
	_build_npcs()
	_build_table_zone()
	_build_hud()
	_build_controls()
	_build_story_box()
	_build_choice()

	story.say(
		[
			"Fim de turno. Doyle não pergunta se o Mark quer uma cerveja — só aponta pra mesa do fundo, já sentado.",
		],
		[""]
	)


# ---------- construção da cena ----------

func _build_bar() -> void:
	var o := BAR_ORIGIN
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(BAR_SIZE.x, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + BAR_SIZE.y - WALL_THICK), Vector2(BAR_SIZE.x, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, BAR_SIZE.y)),
		Rect2(Vector2(o.x + BAR_SIZE.x - WALL_THICK, o.y), Vector2(WALL_THICK, BAR_SIZE.y)),
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
		poly.color = Color(0.25, 0.2, 0.18)
		poly.position = r.position
		add_child(poly)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = BAR_ORIGIN + Vector2(60, BAR_SIZE.y - 80)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_npcs() -> void:
	doyle_marker = Node2D.new()
	doyle_marker.position = BAR_ORIGIN + Vector2(BAR_SIZE.x - 120, 120)
	add_child(doyle_marker)

	theo_marker = Node2D.new()
	theo_marker.position = BAR_ORIGIN + Vector2(-200, 120)  # fora de vista até o beat dele
	add_child(theo_marker)


func _build_table_zone() -> void:
	table_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(150.0, 140.0)
	shape.shape = rect
	table_zone.add_child(shape)
	table_zone.position = doyle_marker.position
	table_zone.monitorable = true
	table_zone.body_entered.connect(_on_table_entered)
	add_child(table_zone)


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


# ---------- fluxo ----------

func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "walk_to_table"
			_controls_locked = false
		"setup":
			_phase = "choice"
			choice.ask(
				"Doyle puxa assunto — meio sério, meio brincando. Como Mark responde?",
				["Pergunta sobre a vida dele", "Mantém a conversa no trabalho"]
			)
		"outcome":
			_phase = "theo"
			theo_marker.position = BAR_ORIGIN + Vector2(BAR_SIZE.x - 60, BAR_SIZE.y - 60)
			story.say(
				[
					"A porta bate. Theo Marsh entra de farda ainda suada, reconhece a mesa e vem direto, sem ser convidado.",
					"Reyes! Achei que ia te encontrar numa cena de crime, não bebendo cerveja quente com o Doyle.",
					"Cerveja quente é a única coisa boa desse bar, Marsh. Senta, se não for atrapalhar o distrito Norte.",
					"Theo senta. A provocação de recruta virou outra coisa — mais parecida com saudade.",
					"Fim do Turno 5 — Fora de Serviço.",
				],
				["", "Theo Marsh", "Sgt. Doyle", "", ""]
			)
		"theo":
			_phase = "done"
			next_btn.visible = true


func _on_table_entered(body: Node) -> void:
	if body != player or _sat_down or _phase != "walk_to_table":
		return
	_sat_down = true
	_phase = "setup"
	_controls_locked = true
	story.say(
		[
			"Mark senta. Doyle empurra uma garrafa sem perguntar se ele bebe.",
			"Primeira semana sobrevivida. Não é pouco, novato.",
		],
		["", "Sgt. Doyle"]
	)


func _on_choice_made(index: int) -> void:
	_phase = "outcome"
	_controls_locked = true
	if index == 0:
		GameState.add_doyle_relationship(1)
		story.say(
			[
				"Mark pergunta há quanto tempo ele está no bairro. Doyle hesita — depois conta, sem drama, sobre uma filha que não vê toda semana.",
				"Não é todo parceiro que pergunta. Anotado, Reyes.",
			],
			["", "Sgt. Doyle"]
		)
	else:
		story.say(
			[
				"Mark mantém no seguro — pergunta sobre os procedimentos do distrito, estatísticas, nada pessoal.",
				"Doyle dá de ombros, nem ofendido. \"Tudo bem. Nem todo mundo gosta de conversa de bar.\"",
			],
			["", "Sgt. Doyle"]
		)


# ---------- lógica de jogo ----------

func _process(_delta: float) -> void:
	if not _controls_locked:
		_move_player()
	_update_hud()
	queue_redraw()


func _move_player() -> void:
	player.velocity = InputBridge.move_vector * SPEED_CAUTIOUS
	player.move_and_slide()


func _update_hud() -> void:
	match _phase:
		"walk_to_table":
			status_label.text = tr("Objetivo: vá até a mesa do Doyle.")
		"done":
			status_label.text = tr("Turno 5 concluído. Relação com Doyle: %d") % GameState.doyle_relationship
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
	if doyle_marker:
		draw_circle(doyle_marker.position, 15.0, Color(0.5, 0.35, 0.15))
		_draw_name_tag(doyle_marker.position, "Doyle")
	if _phase == "theo" or _phase == "done":
		draw_circle(theo_marker.position, 15.0, Color(0.2, 0.4, 0.6))
		_draw_name_tag(theo_marker.position, "Theo")


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
