extends Node2D
## Ato 3, Fase 8 — "Descoberto" (docs/ROTEIRO.md). Fecha o Ato 3: o aviso
## da Fase 7 deixa de ser hipotético — alguém tentou entrar em casa de
## verdade. Mark corre pra lá (reaproveita o sprint do Ato 2, Turno 3 —
## já bateu a "regra dos três" do GDD junto com o resto do tático/carro,
## mas esse é movimento puro, sem mira, então é reaproveito de valor
## calibrado, não duplicação de controlador). O Theo chega primeiro —
## pagando o touchpoint plantado no Ato 2 — e fecha o ato com a família
## seguro mas abalada, abrindo gancho direto pro Ato 4.

const STREET_SIZE := Vector2(820.0, 260.0)
const STREET_ORIGIN := Vector2(60.0, 120.0)
const WALL_THICK := 20.0
const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const SPEED_SPRINT := 170.0
const SPRINT_CHARGE_TIME := 2.0
const SPRINT_DEFLECT_THRESHOLD := 0.75
const SPRINT_CHARGE_DECAY := 2.0
const ARRIVE_DIST := 50.0

var player: CharacterBody2D
var home_marker: Node2D
var _sprint_charge := 0.0
var _arrived := false

var story: Control
var status_label: Label
var _controls_locked := true
var _phase := "intro"
## intro -> run -> arrived -> done


func _ready() -> void:
	_build_street()
	_build_player()
	_build_home()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O rádio pessoal de Mark vibra no meio do turno — Sarah, ligando direto, não mandando mensagem. Ela nunca liga no meio do turno.",
			"\"Tem alguém tentando abrir a porta dos fundos. Já chamei a emergência, mas Mark, por favor — vem.\"",
			"Ele já está correndo antes de desligar.",
		],
		["", "Sarah", ""]
	)


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
		poly.color = Color(0.3, 0.3, 0.32)
		poly.position = r.position
		add_child(poly)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = STREET_ORIGIN + Vector2(60, STREET_SIZE.y * 0.5)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_home() -> void:
	home_marker = Node2D.new()
	home_marker.position = STREET_ORIGIN + Vector2(STREET_SIZE.x - 70, STREET_SIZE.y * 0.5)
	add_child(home_marker)


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
			_phase = "run"
			_controls_locked = false
		"arrived":
			_phase = "done"


func _process(delta: float) -> void:
	if _phase == "run" and not _controls_locked:
		_move_player(delta)
		_check_arrival()
	_update_hud()
	queue_redraw()


func _move_player(delta: float) -> void:
	var deflect := InputBridge.move_vector.length()
	if deflect >= SPRINT_DEFLECT_THRESHOLD:
		_sprint_charge = min(SPRINT_CHARGE_TIME, _sprint_charge + delta)
	else:
		_sprint_charge = max(0.0, _sprint_charge - SPRINT_CHARGE_DECAY * delta)
	var sprinting := _sprint_charge >= SPRINT_CHARGE_TIME
	var speed := SPEED_SPRINT if sprinting else SPEED_CAUTIOUS
	player.velocity = InputBridge.move_vector * speed
	player.move_and_slide()


func _check_arrival() -> void:
	if _arrived:
		return
	if player.position.distance_to(home_marker.position) < ARRIVE_DIST:
		_arrived = true
		_phase = "arrived"
		_controls_locked = true
		story.say(
			[
				"Mark vira a esquina de casa sem fôlego — e já vê uma figura conhecida parada na calçada, de luzes do carro ainda piscando.",
				"Theo Marsh. \"Relaxa, já verifiquei tudo. Fugiu assim que eu encostei o carro. Sarah e Emma estão bem, só assustadas.\"",
				"\"Você mora perto?\", Mark pergunta, sem fôlego pra mais nada. \"Não\", Theo responde. \"Mas você ligou pro Doyle, o Doyle me ligou. Rival não significa inimigo, Reyes.\"",
				"Dentro, Sarah abraça Mark mais apertado do que de costume. Emma não solta a mão dele.",
				"Isso parou de ser um caso de arquivo. Alguém decidiu que a família de Mark é um jeito de chegar nele — e isso muda tudo o que vem a seguir.",
				"Fim da Fase 8 — Descoberto. Fim do Ato 3.",
			],
			["", "Theo Marsh", "", "", "", ""]
		)


func _update_hud() -> void:
	match _phase:
		"run":
			var sprinting := _sprint_charge >= SPRINT_CHARGE_TIME
			status_label.text = tr("Corra pra casa — segure o manche no máximo.%s") % (tr(" SPRINT!") if sprinting else "")
		"done":
			status_label.text = tr("Fase 8 concluída. Ato 3 completo.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
	if home_marker:
		draw_circle(home_marker.position, 18.0, Color(0.6, 0.5, 0.3))
	if _sprint_charge > 0.05 and _sprint_charge < SPRINT_CHARGE_TIME and player:
		var frac := _sprint_charge / SPRINT_CHARGE_TIME
		draw_arc(player.position, 22.0, 0.0, TAU * frac, 24, Color(1.0, 0.8, 0.3), 3.0)
