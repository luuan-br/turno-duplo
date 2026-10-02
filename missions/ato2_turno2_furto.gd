extends Node2D
## Ato 2, Turno 2 — "O Furto que Não Era Nada" (docs/ROTEIRO.md). Chamado
## de furto numa loja de conveniência — parece pequeno e aleatório (na
## verdade é Kessler testando acesso/financiamento, mas o jogador não
## sabe disso ainda). Doyle já está presente como parceiro (segue o
## jogador, igual ficou estabelecido no Turno 1).
##
## Mecânica: **examinar** (botão contextual que aparece perto de um
## objeto de interesse — reaproveita o padrão de interação por proximidade
## já usado em portas/bancada nas fases do Ato 1, agora genérico o
## bastante pra "olhar uma pista" em vez de só "abrir"). Chamado de rádio
## extra opcional (GDD Seção 9: planta um retorno mais tarde — aqui vira
## uma flag em `GameState`, já que ainda não existe sistema de save real
## pra carregar isso até um ato futuro de verdade).

const STORE_SIZE := Vector2(480.0, 360.0)
const STORE_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const PARTNER_FOLLOW_SPEED := 85.0
const PARTNER_FOLLOW_DIST := 50.0
const INTERACT_DIST := 55.0

var player: CharacterBody2D
var doyle_marker: Node2D
var shopkeeper_marker: Node2D

var window_obj: Area2D
var _window_examined := false
var radio_zone: Area2D
var _radio_visited := false

var examine_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> approach -> shopkeeper -> free_roam -> wrap_up -> done

const SCENE_PATH := "res://missions/ato2_turno2_furto.tscn"

var _shopkeeper_talked := false


func _ready() -> void:
	_build_store()
	_build_player()
	_build_doyle()
	_build_shopkeeper()
	_build_window()
	_build_radio_zone()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"Chamado de rotina: furto numa loja de conveniência, sem suspeito no local. Dez minutos de carro.",
			"Doyle nem desliga o rádio enquanto estaciona. \"Desses a gente vê trinta por mês\", ele resmunga.",
		],
		["", ""]
	)


# ---------- construção da cena ----------

func _build_store() -> void:
	var o := STORE_ORIGIN
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(STORE_SIZE.x, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + STORE_SIZE.y - WALL_THICK), Vector2(STORE_SIZE.x, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, STORE_SIZE.y)),
		Rect2(Vector2(o.x + STORE_SIZE.x - WALL_THICK, o.y), Vector2(WALL_THICK, STORE_SIZE.y)),
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
		poly.color = Color(0.32, 0.3, 0.28)
		poly.position = r.position
		add_child(poly)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = STORE_ORIGIN + Vector2(60, STORE_SIZE.y - 80)
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


func _build_shopkeeper() -> void:
	shopkeeper_marker = Node2D.new()
	shopkeeper_marker.position = STORE_ORIGIN + Vector2(STORE_SIZE.x - 100, 100)
	add_child(shopkeeper_marker)

	var zone := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(130.0, 130.0)
	shape.shape = rect
	zone.add_child(shape)
	zone.position = shopkeeper_marker.position
	zone.monitorable = true
	zone.body_entered.connect(_on_shopkeeper_entered)
	add_child(zone)


func _build_window() -> void:
	window_obj = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60.0, 20.0)
	shape.shape = rect
	window_obj.add_child(shape)
	window_obj.position = STORE_ORIGIN + Vector2(STORE_SIZE.x * 0.5, STORE_ORIGIN.y + WALL_THICK + 10)
	window_obj.monitorable = true
	add_child(window_obj)


func _build_radio_zone() -> void:
	radio_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(90.0, 90.0)
	shape.shape = rect
	radio_zone.add_child(shape)
	radio_zone.position = STORE_ORIGIN + Vector2(100, STORE_SIZE.y - 100)
	radio_zone.monitorable = true
	radio_zone.body_entered.connect(_on_radio_entered)
	add_child(radio_zone)


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
	examine_btn.anchor_left = 1.0
	examine_btn.anchor_right = 1.0
	examine_btn.anchor_top = 1.0
	examine_btn.anchor_bottom = 1.0
	examine_btn.offset_right = -30.0
	examine_btn.offset_left = -130.0
	examine_btn.offset_bottom = -180.0
	examine_btn.offset_top = -280.0
	examine_btn.visible = false
	layer.add_child(examine_btn)


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
			_phase = "free_roam"
			_controls_locked = false
		"shopkeeper":
			_phase = "free_roam"
			_controls_locked = false
		"wrap_up":
			_phase = "done"
			next_btn.visible = true


func _on_shopkeeper_entered(body: Node) -> void:
	if body != player or _shopkeeper_talked or _controls_locked:
		return
	_shopkeeper_talked = true
	_phase = "shopkeeper"
	_controls_locked = true
	story.say(
		[
			"\"Levaram uns trocados do caixa e duas garrafas de água. Nem acionei alarme, só reparei de manhã.\"",
			"Vidro da porta dos fundos quebrado — mão pequena, ou alguém com pressa.",
			"Dá uma olhada aí, novato. Eu cubro a frente.",
		],
		["Lojista", "", "Sgt. Doyle"]
	)


func _on_radio_entered(body: Node) -> void:
	if body != player or _radio_visited or _controls_locked:
		return
	_radio_visited = true
	story.say(
		[
			"O rádio crepita: um morador do quarteirão ao lado reclamando de barulho de noite, nada urgente.",
			"Mark anota o endereço de cabeça — não parece nada agora, mas é o tipo de coisa que vale lembrar depois.",
		],
		["", ""]
	)


func _check_examine() -> void:
	if _window_examined or _controls_locked:
		examine_btn.visible = false
		return
	var near := player.position.distance_to(window_obj.position) < INTERACT_DIST
	examine_btn.visible = near
	if near and InputBridge.consume_just_pressed("examine"):
		_window_examined = true
		examine_btn.visible = false
		_wrap_up()


func _wrap_up() -> void:
	_phase = "wrap_up"
	_controls_locked = true
	story.say(
		[
			"Vidro quebrado de fora pra dentro, cacos do lado de dentro. Alguém entrou por aqui mesmo — provavelmente um garoto, pelo tamanho do buraco.",
			"Viu? Metade dos chamados daqui é isso. Bota no relatório e segue o turno.",
			"Mark escreve o relatório, mas guarda o detalhe do vidro na cabeça de qualquer jeito. Não sabe bem por quê.",
			"Fim do Turno 2 — O Furto que Não Era Nada.",
		],
		["", "Sgt. Doyle", "", ""]
	)


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	if not _controls_locked:
		_move_player()
		_check_examine()
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
		"free_roam":
			status_label.text = tr("Objetivo: fale com o lojista e examine a cena.")
		"done":
			status_label.text = tr("Turno 2 concluído.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
	if doyle_marker:
		draw_circle(doyle_marker.position, 15.0, Color(0.5, 0.35, 0.15))
		_draw_name_tag(doyle_marker.position, "Doyle")
	if shopkeeper_marker:
		draw_circle(shopkeeper_marker.position, 15.0, Color(0.4, 0.4, 0.2))
		_draw_name_tag(shopkeeper_marker.position, "Lojista")
	if window_obj:
		draw_rect(Rect2(window_obj.position - Vector2(30, 10), Vector2(60, 20)), Color(0.2, 0.5, 0.6, 0.6) if not _window_examined else Color(0.2, 0.2, 0.2))


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
