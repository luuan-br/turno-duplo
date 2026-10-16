extends Node2D
## Ato 2, Turno 4 — "Semáforo Cego" (docs/ROTEIRO.md). Falha "isolada" de
## semáforo causa um acidente que vira perseguição de carro — primeiro
## PIT de verdade, fora do treino. No caos, um motorista sem rosto escapa
## com facilidade suspeita — a primeira aparição do Wade "Ghost" Calloway,
## ainda sem nome (beat visual rápido, não uma segunda perseguição).
##
## Risco real nas perseguições (`actors/`, GDD Seção 8): o motorista em
## pânico não atira — o risco é a lataria (batida forte machuca, carro
## destruído recomeça a missão), os obstáculos na pista e o suspeito
## escapando se o Mark ficar longe demais por tempo demais.

const TRACK_SIZE := Vector2(820.0, 460.0)
const TRACK_ORIGIN := Vector2(60.0, 40.0)
const WALL_THICK := 20.0
const FLEEING_SPEED := 140.0
const GHOST_TIME := 1.6
const WALL_COLOR := Color(0.3, 0.3, 0.35)
const BLOCK_COLOR := Color(0.4, 0.33, 0.25)
const PARKED_COLOR := Color(0.35, 0.4, 0.45)

var car: PlayerCar
var chase: ChaseLayer
var fleeing_car: EnemyCar

var ghost_car: CharacterBody2D
var ghost_active := false
var _ghost_timer := 0.0
var ghost_start: Vector2
var ghost_end: Vector2

var accel_btn: Control
var brake_btn: Control
var pit_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> chase -> ghost_glimpse -> outro -> done (ou down -> recomeça)

const SCENE_PATH := "res://missions/ato2_turno4_semaforo.tscn"


func _ready() -> void:
	_build_track()
	chase = ChaseLayer.new()
	add_child(chase)
	_build_cars()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O semáforo da Décima com Industrial pisca duas vezes e apaga. Ninguém percebe até ser tarde demais.",
			"Um carro corta o cruzamento, bate de leve num poste e sai em disparada — pânico, não maldade, mas foge do jeito que importa.",
			"Doyle, do rádio: \"Vai atrás, eu cuido do ferido aqui! E não me volta com a viatura amassada.\"",
		],
		["", "", "Sgt. Doyle"]
	)


# ---------- construção da cena ----------

func _add_block(r: Rect2, color: Color) -> void:
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
	poly.color = color
	poly.position = r.position
	add_child(poly)


func _build_track() -> void:
	var top := TRACK_ORIGIN
	var w := TRACK_SIZE.x
	var h := TRACK_SIZE.y
	_add_block(Rect2(top, Vector2(w, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(Vector2(top.x, top.y + h - WALL_THICK), Vector2(w, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(top, Vector2(WALL_THICK, h)), WALL_COLOR)
	_add_block(Rect2(Vector2(top.x + w - WALL_THICK, top.y), Vector2(WALL_THICK, h)), WALL_COLOR)
	# Quarteirão no meio (não dá pra cortar caminho), postes na parte de
	# dentro das curvas e carros estacionados na faixa de fora.
	_add_block(Rect2(top + Vector2(200, 190), Vector2(420, 80)), BLOCK_COLOR)
	_add_block(Rect2(top + Vector2(140, 140), Vector2(25, 25)), BLOCK_COLOR)
	_add_block(Rect2(top + Vector2(w - 145, h - 145), Vector2(25, 25)), BLOCK_COLOR)
	_add_block(Rect2(top + Vector2(360, 30), Vector2(50, 24)), PARKED_COLOR)
	_add_block(Rect2(top + Vector2(450, h - 54), Vector2(50, 24)), PARKED_COLOR)

	ghost_start = top + Vector2(-40, h * 0.5)
	ghost_end = top + Vector2(w + 40, h * 0.5)


func _build_cars() -> void:
	var top := TRACK_ORIGIN
	var w := TRACK_SIZE.x
	var h := TRACK_SIZE.y

	car = PlayerCar.new()
	car.position = top + Vector2(40, 100)
	add_child(car)
	chase.setup(car)
	chase.pit_enabled = true
	chase.player_wrecked.connect(_on_failed.bind("A viatura não aguentou mais. O suspeito sumiu no trânsito."))
	chase.suspect_escaped.connect(_on_failed.bind("Longe demais — o suspeito sumiu no trânsito."))
	chase.enemy_disabled.connect(_on_pit_landed)

	fleeing_car = EnemyCar.new()
	fleeing_car.waypoints = [
		top + Vector2(100, 100),
		top + Vector2(w - 100, 100),
		top + Vector2(w - 100, h - 100),
		top + Vector2(100, h - 100),
	]
	fleeing_car.position = fleeing_car.waypoints[0]
	fleeing_car.speed = FLEEING_SPEED
	fleeing_car.max_hp = 99.0
	chase.add_enemy(fleeing_car)
	chase.escape_target = fleeing_car


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

	var stick := Control.new()
	stick.set_script(load("res://ui/virtual_joystick.gd"))
	stick.anchor_left = 0.0
	stick.anchor_right = 0.55
	stick.anchor_top = 0.0
	stick.anchor_bottom = 1.0
	layer.add_child(stick)

	accel_btn = _corner_button("accelerate", tr("ACELERAR"), 30, 30, 110, 110)
	layer.add_child(accel_btn)
	brake_btn = _corner_button("brake", tr("FREAR"), 160, 40, 100, 100)
	layer.add_child(brake_btn)
	pit_btn = _corner_button("handbrake", tr("FREIO DE\nMÃO / PIT"), 30, 160, 110, 110)
	layer.add_child(pit_btn)


func _corner_button(action: String, label: String, right: float, bottom: float, w: float, h: float) -> Control:
	var btn := Control.new()
	btn.set_script(load("res://ui/contextual_button.gd"))
	btn.action_name = action
	btn.label_text = label
	btn.layout_slot = ControlLayout.slot_for_action(action)
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
			_phase = "chase"
			_controls_locked = false
			chase.set_active(true)
		"ghost_glimpse":
			_phase = "outro"
			story.say(
				[
					"Mark algema o motorista — assustado, não perigoso. Vai levar uma multa feia e uma baita história.",
					"Ninguém no bairro vai lembrar do susto. Mark, sim — do jeito que aquele outro carro sumiu sem nem acender o farol.",
					"Fim do Turno 4 — Semáforo Cego.",
				],
				["", "", ""]
			)
		"outro":
			_phase = "done"
			next_btn.visible = true


func _on_pit_landed(_c: EnemyCar) -> void:
	if _phase != "chase":
		return
	_phase = "ghost_glimpse"
	_controls_locked = true
	chase.set_active(false)
	ghost_active = true
	_ghost_timer = 0.0
	story.say(
		[
			"O carro perde o rumo e para de lado na calçada. No retrovisor, outro veículo passa reto pelo cruzamento quebrado — sem parar, sem hesitar, como quem já sabia que o sinal ia falhar.",
		],
		[""]
	)


func _on_failed(reason: String) -> void:
	if _phase != "chase":
		return
	_phase = "down"
	_controls_locked = true
	status_label.text = tr(reason) + "  " + tr("Recomeçando a missão...")
	chase.restart_mission()


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	car.controls_locked = _controls_locked
	var driving := not _controls_locked
	accel_btn.visible = driving
	brake_btn.visible = driving
	pit_btn.visible = driving
	if ghost_active:
		_update_ghost(delta)
	_update_hud()
	queue_redraw()


func _update_ghost(delta: float) -> void:
	if not ghost_car:
		ghost_car = CharacterBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(28, 16)
		shape.shape = rect
		ghost_car.add_child(shape)
		ghost_car.position = ghost_start
		ghost_car.rotation = (ghost_end - ghost_start).angle()
		# Só um beat visual: não colide com nada nem atrapalha a cena.
		ghost_car.collision_layer = 0
		ghost_car.collision_mask = 0
		add_child(ghost_car)

	_ghost_timer += delta
	ghost_car.position = ghost_start.lerp(ghost_end, clampf(_ghost_timer / GHOST_TIME, 0.0, 1.0))
	if _ghost_timer >= GHOST_TIME:
		ghost_active = false
		GameState.ghost_spotted = true


func _bar(frac: float) -> String:
	var n := int(round(clampf(frac, 0.0, 1.0) * 10.0))
	return "[" + "#".repeat(n) + "-".repeat(10 - n) + "]"


func _update_hud() -> void:
	match _phase:
		"chase":
			status_label.text = tr("Encoste atrás dele e segure FREIO DE MÃO/PIT. Não fique longe — ele some.") + "\n" + tr("Lataria: %d%%") % int(car.hp) + "   " + tr("Fugindo: %s") % _bar(chase.escape_progress)
		"done":
			status_label.text = tr("Turno 4 concluído.")
		"down":
			pass
		_:
			status_label.text = ""


func _draw() -> void:
	if ghost_car and ghost_active:
		var half := Vector2(14, 8)
		var points := PackedVector2Array([
			Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			Vector2(half.x, half.y), Vector2(-half.x, half.y)
		])
		for i in points.size():
			points[i] = ghost_car.position + points[i].rotated(ghost_car.rotation)
		draw_colored_polygon(points, Color(0.15, 0.15, 0.15))
