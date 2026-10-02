extends Node2D
## Ato 3, Fase 3 — "Vigilância" (docs/ROTEIRO.md). Primeira fase sem
## confronto físico possível — Mark observa um ponto de encontro suspeito
## de um beco, precisa avançar entre 3 sombras sem ser visto pelo vigia
## que patrulha de leva e volta. Ser visto não é "game over": o vigia
## grita, Mark recua pro início do trecho — pressão sem punição dura,
## coerente com "sem XP/grind" do GDD Seção 11, isso aqui é tensão, não
## skill check de precisão.

const ALLEY_SIZE := Vector2(760.0, 300.0)
const ALLEY_ORIGIN := Vector2(60.0, 100.0)
const WALL_THICK := 20.0
const PLAYER_RADIUS := 12.0
const SPEED_CAUTIOUS := 85.0
const CONE_RANGE := 160.0
const CONE_HALF_ANGLE := deg_to_rad(28.0)
const GUARD_SPEED := 55.0

var player: CharacterBody2D
var guard: Node2D
var guard_dir := 1
var guard_from: Vector2
var guard_to: Vector2
var shadow_zones: Array[Rect2] = []
var start_pos: Vector2
var vantage_zone: Area2D

var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> sneak -> spotted_warning -> vantage -> done

const SCENE_PATH := "res://missions/ato3_fase3_vigilancia.tscn"
var _spotted_cooldown := 0.0


func _ready() -> void:
	_build_alley()
	_build_shadows()
	_build_guard()
	_build_player()
	_build_vantage()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O endereço que o Lou — ou o Miko, depende de quem falou — soltou dá nesse beco atrás de um depósito fechado.",
			"Tem um cara de vigia, ida e volta, lento, mas atento. Mark não tem mandado pra abordar ninguém aqui — só pra ver.",
			"As sombras ao longo da parede escondem bem. O meio do beco, não.",
		],
		["", "", ""]
	)


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
		poly.color = Color(0.22, 0.22, 0.24)
		poly.position = r.position
		add_child(poly)


func _build_shadows() -> void:
	var o := ALLEY_ORIGIN
	shadow_zones = [
		Rect2(Vector2(o.x + 40, o.y + 30), Vector2(90, ALLEY_SIZE.y - 60)),
		Rect2(Vector2(o.x + 320, o.y + 30), Vector2(90, ALLEY_SIZE.y - 60)),
		Rect2(Vector2(o.x + 600, o.y + 30), Vector2(90, ALLEY_SIZE.y - 60)),
	]


func _build_guard() -> void:
	guard = Node2D.new()
	guard_from = ALLEY_ORIGIN + Vector2(180, ALLEY_SIZE.y * 0.5)
	guard_to = ALLEY_ORIGIN + Vector2(ALLEY_SIZE.x - 180, ALLEY_SIZE.y * 0.5)
	guard.position = guard_from
	add_child(guard)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	start_pos = ALLEY_ORIGIN + Vector2(60, ALLEY_SIZE.y - 50)
	player.position = start_pos
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_vantage() -> void:
	vantage_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	vantage_zone.add_child(shape)
	vantage_zone.position = ALLEY_ORIGIN + Vector2(ALLEY_SIZE.x - 60, ALLEY_SIZE.y - 50)
	vantage_zone.monitorable = true
	vantage_zone.body_entered.connect(_on_vantage_entered)
	add_child(vantage_zone)


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


func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "sneak"
			_controls_locked = false
		"spotted_warning":
			_phase = "sneak"
			_controls_locked = false
			player.position = start_pos
		"vantage":
			_phase = "done"
			next_btn.visible = true


func _on_vantage_entered(body: Node) -> void:
	if body != player or _phase != "sneak":
		return
	_phase = "vantage"
	_controls_locked = true
	story.say(
		[
			"Do canto certo, dá pra ver sem ser visto: dois carros, placas trocadas na hora, e uma troca de caixas que não tem nada de inocente.",
			"Mark não reconhece ninguém. Mas reconhece o padrão — é logística, não crime de oportunidade. Alguém tá coordenando isso.",
			"Hora de levar isso pro quadro.",
			"Fim da Fase 3 — Vigilância.",
		],
		["", "", "", ""]
	)


func _is_in_shadow(pos: Vector2) -> bool:
	for r in shadow_zones:
		if r.has_point(pos):
			return true
	return false


func _process(delta: float) -> void:
	if _spotted_cooldown > 0.0:
		_spotted_cooldown -= delta
	if _phase == "sneak" and not _controls_locked:
		_move_player()
		_update_guard(delta)
		_check_spotted()
	_update_hud()
	queue_redraw()


func _move_player() -> void:
	player.velocity = InputBridge.move_vector * SPEED_CAUTIOUS
	player.move_and_slide()


func _update_guard(delta: float) -> void:
	var target := guard_to if guard_dir > 0 else guard_from
	guard.position = guard.position.move_toward(target, GUARD_SPEED * delta)
	if guard.position.distance_to(target) < 4.0:
		guard_dir *= -1


func _guard_facing() -> Vector2:
	return Vector2(guard_dir, 0.0)


func _check_spotted() -> void:
	if _spotted_cooldown > 0.0:
		return
	if _is_in_shadow(player.position):
		return
	var to_player := player.position - guard.position
	var dist := to_player.length()
	if dist > CONE_RANGE:
		return
	var angle := _guard_facing().angle_to(to_player.normalized())
	if absf(angle) <= CONE_HALF_ANGLE:
		_on_spotted()


func _on_spotted() -> void:
	_phase = "spotted_warning"
	_controls_locked = true
	_spotted_cooldown = 1.5
	story.say(
		[
			"\"Ei! Quem tá aí?!\"",
			"Mark recua pro começo do beco antes que o vigia largue a posição pra confirmar.",
		],
		["Vigia", ""]
	)


func _update_hud() -> void:
	match _phase:
		"sneak":
			status_label.text = tr("Objetivo: avance pelas sombras sem ser visto.")
		"done":
			status_label.text = tr("Fase 3 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	for r in shadow_zones:
		draw_rect(r, Color(0.1, 0.1, 0.12, 0.85))
	if guard:
		var facing := _guard_facing()
		var points := PackedVector2Array(
			[
				guard.position,
				guard.position + facing.rotated(-CONE_HALF_ANGLE) * CONE_RANGE,
				guard.position + facing.rotated(CONE_HALF_ANGLE) * CONE_RANGE,
			]
		)
		draw_colored_polygon(points, Color(0.9, 0.8, 0.2, 0.25))
		draw_circle(guard.position, 14.0, Color(0.8, 0.3, 0.3))
	if vantage_zone:
		draw_circle(vantage_zone.position, 40.0, Color(0.3, 0.7, 0.4, 0.3))
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
