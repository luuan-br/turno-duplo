extends Node2D
## Ato 2, Turno 3 — "Corrida a Pé" (docs/ROTEIRO.md). Primeiro uso real
## do sprint tático pra alcançar alguém — o suspeito foge numa velocidade
## entre o passo cauteloso e o sprint do jogador, então só dá pra alcançar
## carregando o sprint (segurar o manche no máximo ~2s, mecânica já
## validada no sandbox tático). Doyle comenta sobre o excesso de zelo do
## Mark no final, mantendo o atrito estabelecido desde o Ato 1.

const ALLEY_SIZE := Vector2(900.0, 320.0)
const ALLEY_ORIGIN := Vector2(60.0, 60.0)
const WALL_THICK := 20.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const SPEED_SPRINT := 170.0
const SPRINT_CHARGE_TIME := 2.0
const SPRINT_DEFLECT_THRESHOLD := 0.75
const SPRINT_CHARGE_DECAY := 2.0

const SUSPECT_SPEED := 120.0
const CATCH_DIST := 45.0

var player: CharacterBody2D
var _sprint_charge := 0.0

var suspect: CharacterBody2D
var _waypoints: Array[Vector2] = []
var _wp_index := 0
var suspect_caught := false

var start_zone: Area2D
var _chase_started := false

var catch_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> approach -> chase -> caught -> done

const SCENE_PATH := "res://missions/ato2_turno3_corrida.tscn"


func _ready() -> void:
	_build_alley()
	_build_player()
	_build_suspect()
	_build_start_zone()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"\"217 em andamento, suspeito a pé, últimos visto na Rua 4 com a Alameda.\"",
			"Doyle já está manobrando a viatura pra bloquear a saída. \"Vai, eu corto o acesso!\"",
		],
		["", "Sgt. Doyle"]
	)


# ---------- construção da cena ----------

func _build_alley() -> void:
	var o := ALLEY_ORIGIN
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(ALLEY_SIZE.x, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + ALLEY_SIZE.y - WALL_THICK), Vector2(ALLEY_SIZE.x, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, ALLEY_SIZE.y)),
		Rect2(Vector2(o.x + ALLEY_SIZE.x - WALL_THICK, o.y), Vector2(WALL_THICK, ALLEY_SIZE.y)),
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
		poly.color = Color(0.28, 0.28, 0.3)
		poly.position = r.position
		add_child(poly)

	_waypoints = [
		o + Vector2(250, 80),
		o + Vector2(500, 240),
		o + Vector2(750, 80),
		o + Vector2(ALLEY_SIZE.x - 60, ALLEY_SIZE.y * 0.5),
	]


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = ALLEY_ORIGIN + Vector2(60, ALLEY_SIZE.y * 0.5)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_suspect() -> void:
	suspect = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	suspect.add_child(shape)
	suspect.position = ALLEY_ORIGIN + Vector2(160, ALLEY_SIZE.y * 0.5)
	add_child(suspect)


func _build_start_zone() -> void:
	start_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80.0, ALLEY_SIZE.y - 60.0)
	shape.shape = rect
	start_zone.add_child(shape)
	start_zone.position = ALLEY_ORIGIN + Vector2(120, ALLEY_SIZE.y * 0.5)
	start_zone.monitorable = true
	start_zone.body_entered.connect(_on_start_zone_entered)
	add_child(start_zone)


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

	catch_btn = Control.new()
	catch_btn.set_script(load("res://ui/contextual_button.gd"))
	catch_btn.action_name = "catch"
	catch_btn.label_text = tr("ALGEMAR")
	catch_btn.layout_slot = "acao_principal"
	catch_btn.anchor_left = 1.0
	catch_btn.anchor_right = 1.0
	catch_btn.anchor_top = 1.0
	catch_btn.anchor_bottom = 1.0
	catch_btn.offset_right = -30.0
	catch_btn.offset_left = -130.0
	catch_btn.offset_bottom = -30.0
	catch_btn.offset_top = -130.0
	catch_btn.visible = false
	layer.add_child(catch_btn)


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
		"caught":
			_phase = "done"
			next_btn.visible = true


func _on_start_zone_entered(body: Node) -> void:
	if body != player or _chase_started or _phase != "approach":
		return
	_chase_started = true
	_phase = "chase"


func _check_catch() -> void:
	if suspect_caught or _phase != "chase":
		catch_btn.visible = false
		return
	var near := player.position.distance_to(suspect.position) < CATCH_DIST
	catch_btn.visible = near
	if near and InputBridge.consume_just_pressed("catch"):
		suspect_caught = true
		_phase = "caught"
		_controls_locked = true
		story.say(
			[
				"Mark alcança e prende o braço antes da próxima esquina — sem drama, sem tombo, só peso e firmeza.",
				"Viu, foi rápido assim. Não precisava ter esperado quase perder ele de vista pra correr de verdade.",
				"Fim do Turno 3 — Corrida a Pé.",
			],
			["", "Sgt. Doyle", ""]
		)


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	if not _controls_locked:
		_move_player(delta)
		_check_catch()
	if _phase == "chase" and not suspect_caught:
		_move_suspect(delta)
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


func _move_suspect(delta: float) -> void:
	var dest: Vector2 = _waypoints[_wp_index]
	var to_dest := dest - suspect.position
	if to_dest.length() < 16.0:
		_wp_index = min(_wp_index + 1, _waypoints.size() - 1)
		dest = _waypoints[_wp_index]
		to_dest = dest - suspect.position
	if to_dest.length() > 2.0:
		suspect.velocity = to_dest.normalized() * SUSPECT_SPEED
		suspect.move_and_slide()


func _update_hud() -> void:
	match _phase:
		"approach":
			status_label.text = tr("Objetivo: entre no beco pra começar a perseguição.")
		"chase":
			var sprinting := _sprint_charge >= SPRINT_CHARGE_TIME
			status_label.text = tr("Persiga o suspeito — segure o manche no máximo pra correr.%s") % (tr(" SPRINT!") if sprinting else "")
		"done":
			status_label.text = tr("Turno 3 concluído.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
		if _sprint_charge > 0.05 and _sprint_charge < SPRINT_CHARGE_TIME:
			var frac := _sprint_charge / SPRINT_CHARGE_TIME
			draw_arc(player.position, PLAYER_RADIUS + 7.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 24, Color.YELLOW, 3.0)
	if suspect and not suspect_caught:
		draw_circle(suspect.position, PLAYER_RADIUS, Color(0.8, 0.5, 0.2))
		_draw_name_tag(suspect.position, "Suspeito")


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
