extends Node2D
## Ato 4, Fase 5 — "O Cofre" (docs/ROTEIRO.md). Breach & clear final
## contra o músculo de apoio de Kessler, com o combate de risco real
## (`actors/`): três guardas na sala do cofre — um parado vigiando o
## cofre, dois patrulhando — e mesas de cobertura. Depois, a fuga de carro
## atirando pra trás (fusão tático+perseguição, mira automática por cone
## virada pra trás) — esse trecho de carro não mudou, já tinha sido
## validado no celular.

const ROOM_SIZE := Vector2(560.0, 420.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0
const VEST_HITS := 2
const WALL_COLOR := Color(0.2, 0.19, 0.16)
const DESK_COLOR := Color(0.33, 0.29, 0.22)

const TRACK_SIZE := Vector2(820.0, 300.0)
const TRACK_ORIGIN := Vector2(80.0, 540.0)
const MAX_SPEED := 190.0
const ACCEL := 220.0
const BRAKE_DECEL := 400.0
const REVERSE_SPEED := 90.0
const COAST_DECEL := 90.0
const TURN_RATE := 2.6
const STEER_DEADZONE := 0.2
const PURSUER_SPEED := 150.0
const PURSUER_DAMAGE_MAX := 2
const REAR_CONE_RANGE := 220.0
const REAR_CONE_DOT := 0.9

var player: TacticalPlayer
var combat: CombatLayer
var vault_obj: Area2D
var _vault_opened := false

var player_car: CharacterBody2D
var player_speed := 0.0
var pursuer_car: CharacterBody2D
var pursuer_damage := 0
var pursuer_defeated := false
var escape_finish: Node2D
var _fire_target_valid := false

var left_stick: Control
var right_stick: Control
var fire_btn: Control
var open_btn: Control
var accel_btn: Control
var brake_btn: Control
var rear_fire_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> fight -> aftermath -> open -> to_car -> escape -> outro -> done (ou down -> recomeça)

const SCENE_PATH := "res://missions/ato4_fase5_cofre.tscn"


func _ready() -> void:
	_build_room()
	_build_vault()
	_build_track()
	combat = CombatLayer.new()
	add_child(combat)
	_build_player()
	_build_guards()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"A porta do cofre já está entreaberta — Kessler não veio buscar dinheiro, veio buscar tempo. Documentos, servidores, provas.",
			"Três homens cobrem a sala. Um deles não sai do lado do cofre. Essa é a última barreira antes do que quer que o Kessler esteja levando embora.",
		],
		["", ""]
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


func _build_room() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	_add_block(Rect2(o, Vector2(w, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(Vector2(o.x, o.y + h - WALL_THICK), Vector2(w, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(o, Vector2(WALL_THICK, h)), WALL_COLOR)
	_add_block(Rect2(Vector2(o.x + w - WALL_THICK, o.y), Vector2(WALL_THICK, h)), WALL_COLOR)
	# Mesas de escritório: cobertura pra avançar da entrada (canto de baixo
	# à esquerda) até o cofre (canto de cima à direita).
	_add_block(Rect2(o + Vector2(150, 120), Vector2(80, 30)), DESK_COLOR)
	_add_block(Rect2(o + Vector2(300, 250), Vector2(30, 90)), DESK_COLOR)
	_add_block(Rect2(o + Vector2(140, 300), Vector2(60, 30)), DESK_COLOR)


func _build_vault() -> void:
	vault_obj = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	vault_obj.add_child(shape)
	vault_obj.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x - 80, 80)
	vault_obj.monitorable = true
	add_child(vault_obj)


func _build_track() -> void:
	var top := TRACK_ORIGIN
	var w := TRACK_SIZE.x
	var h := TRACK_SIZE.y
	var wall := Color(0.14, 0.14, 0.18)
	_add_block(Rect2(top, Vector2(w, WALL_THICK)), wall)
	_add_block(Rect2(Vector2(top.x, top.y + h - WALL_THICK), Vector2(w, WALL_THICK)), wall)
	_add_block(Rect2(top, Vector2(WALL_THICK, h)), wall)
	_add_block(Rect2(Vector2(top.x + w - WALL_THICK, top.y), Vector2(WALL_THICK, h)), wall)

	escape_finish = Node2D.new()
	escape_finish.position = top + Vector2(w - 70, h * 0.5)
	add_child(escape_finish)


func _build_player() -> void:
	player = TacticalPlayer.new()
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 70)
	player.set_vest(VEST_HITS)
	player.extra_exclude = [vault_obj.get_rid()]
	add_child(player)
	combat.setup(player)
	combat.player_downed.connect(_on_player_downed)
	combat.all_guards_down.connect(_on_all_guards_down)


func _build_guards() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	combat.add_guard([o + Vector2(w - 140, 120)], Vector2(-1.0, 0.6))
	combat.add_guard([o + Vector2(200, 230), o + Vector2(420, 230)])
	combat.add_guard([o + Vector2(w - 60, 200), o + Vector2(w - 60, h - 60)])


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

	left_stick = Control.new()
	left_stick.set_script(load("res://ui/virtual_joystick.gd"))
	left_stick.anchor_left = 0.0
	left_stick.anchor_right = 0.5
	left_stick.anchor_top = 0.0
	left_stick.anchor_bottom = 1.0
	layer.add_child(left_stick)

	right_stick = Control.new()
	right_stick.set_script(load("res://ui/virtual_joystick.gd"))
	right_stick.right_stick = true
	right_stick.double_tap_action = "shoot"
	right_stick.anchor_left = 0.5
	right_stick.anchor_right = 1.0
	right_stick.anchor_top = 0.0
	right_stick.anchor_bottom = 1.0
	layer.add_child(right_stick)

	fire_btn = _corner_button("shoot", tr("ATIRAR"), 30.0, 180.0, 100.0, 100.0)
	fire_btn.visible = false
	layer.add_child(fire_btn)

	open_btn = _corner_button("open_vault", tr("ABRIR\nCOFRE"), 30.0, 180.0, 100.0, 100.0)
	open_btn.show_hold_progress = true
	open_btn.visible = false
	layer.add_child(open_btn)

	accel_btn = _corner_button("accelerate", tr("ACELERAR"), 30, 30, 110, 110)
	accel_btn.visible = false
	layer.add_child(accel_btn)

	brake_btn = _corner_button("brake", tr("FREAR"), 160, 40, 100, 100)
	brake_btn.visible = false
	layer.add_child(brake_btn)

	rear_fire_btn = _corner_button("rear_shoot", tr("ATIRAR\nPRA TRÁS"), 30, 160, 110, 110)
	rear_fire_btn.visible = false
	layer.add_child(rear_fire_btn)


func _corner_button(action: String, label: String, right: float, bottom: float, w: float, h: float) -> Control:
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


# ---------- fluxo ----------

func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "fight"
			_controls_locked = false
			combat.set_active(true)
		"aftermath":
			_phase = "open"
			_controls_locked = false
		"to_car":
			_phase = "escape"
			_controls_locked = false
		"outro":
			_phase = "done"
			next_btn.visible = true


func _on_all_guards_down() -> void:
	if _phase != "fight":
		return
	_phase = "aftermath"
	_controls_locked = true
	story.say(
		[
			"A sala fica quieta. Mas o cofre de verdade, o de dados e documentos, continua trancado.",
			"É agora ou nunca — Kessler não vai deixar essa prova esperando muito mais.",
		],
		["", ""]
	)


func _on_player_downed() -> void:
	_phase = "down"
	_controls_locked = true
	combat.restart_mission()


func _check_vault() -> void:
	if _phase != "open" or _vault_opened:
		open_btn.visible = false
		return
	var near := player.position.distance_to(vault_obj.position) < 60.0
	open_btn.visible = near
	if not open_btn.visible:
		return
	if InputBridge.consume_just_released("open_vault"):
		_vault_opened = true
		open_btn.visible = false
		_phase = "to_car"
		_controls_locked = true
		story.say(
			[
				"O cofre abre num estrondo de metal — servidor portátil, pastas, tudo que Kessler ia levar embora pra sumir de vez.",
				"Um alarme dispara em algum canto que ninguém tinha desarmado. Lá fora, motores ligam. Reforço.",
				"\"CORRE PRO CARRO!\", Theo grita de algum lugar atrás.",
			],
			["", "", "Theo Marsh"]
		)


func _process(delta: float) -> void:
	player.controls_locked = _controls_locked or player_car != null
	player.can_shoot = _phase == "fight"
	fire_btn.visible = _phase == "fight" and not _controls_locked
	_check_vault()

	if _phase == "escape":
		_update_drive_buttons()
		if not _controls_locked:
			_drive_player(delta)
		_drive_pursuer(delta)
		_check_rear_fire()
		_check_escape_finish()

	_update_hud()
	queue_redraw()


# ---------- trecho de fuga de carro ----------

func _spawn_cars() -> void:
	if player_car:
		return
	player_car = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 16)
	shape.shape = rect
	player_car.add_child(shape)
	player_car.position = TRACK_ORIGIN + Vector2(60, TRACK_SIZE.y * 0.5)
	add_child(player_car)

	# Desativa a câmera tática explicitamente antes de ligar a do carro —
	# duas Camera2D com enabled=true ao mesmo tempo nem sempre trocam
	# sozinhas de forma confiável (bug relatado: câmera ficava presa no
	# player tático durante a fuga).
	player.camera.enabled = false
	player.visible = false

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player_car.add_child(camera)

	pursuer_car = CharacterBody2D.new()
	var shape2 := CollisionShape2D.new()
	var rect2 := RectangleShape2D.new()
	rect2.size = Vector2(28, 16)
	shape2.shape = rect2
	pursuer_car.add_child(shape2)
	# Dentro da pista, atrás do carro do jogador — fora da parede esquerda
	# (parede ocupa até TRACK_ORIGIN.x + WALL_THICK) ele ficava preso fora
	# do cenário.
	pursuer_car.position = TRACK_ORIGIN + Vector2(WALL_THICK + 25.0, TRACK_SIZE.y * 0.5)
	add_child(pursuer_car)


func _update_drive_buttons() -> void:
	var escaping := _phase == "escape" and not _controls_locked
	accel_btn.visible = escaping
	brake_btn.visible = escaping
	# O manche direito fica embaixo do mesmo canto dos botões de carro —
	# escondido na fuga pra não disputar toque com ACELERAR/FREAR/ATIRAR.
	right_stick.visible = not escaping
	if not player_car:
		_spawn_cars()


func _drive_player(delta: float) -> void:
	if not player_car:
		return
	var accelerating := InputBridge.is_held("accelerate")
	var braking := InputBridge.is_held("brake")

	if accelerating and not braking:
		player_speed = move_toward(player_speed, MAX_SPEED, ACCEL * delta)
	elif braking:
		if player_speed > 0.0:
			player_speed = move_toward(player_speed, 0.0, BRAKE_DECEL * delta)
		else:
			player_speed = move_toward(player_speed, -REVERSE_SPEED, ACCEL * delta)
	else:
		player_speed = move_toward(player_speed, 0.0, COAST_DECEL * delta)

	player_speed = clamp(player_speed, -REVERSE_SPEED, MAX_SPEED)

	if InputBridge.move_vector.length() >= STEER_DEADZONE and absf(player_speed) > 5.0:
		var desired_angle := InputBridge.move_vector.angle()
		var diff := wrapf(desired_angle - player_car.rotation, -PI, PI)
		var speed_factor: float = clamp(absf(player_speed) / MAX_SPEED, 0.35, 1.0)
		var max_step: float = TURN_RATE * speed_factor * delta
		player_car.rotation += clamp(diff, -max_step, max_step)

	player_car.velocity = Vector2.RIGHT.rotated(player_car.rotation) * player_speed
	player_car.move_and_slide()


func _drive_pursuer(_delta: float) -> void:
	if not pursuer_car or pursuer_defeated or not player_car:
		return
	var to_player := player_car.position - pursuer_car.position
	pursuer_car.rotation = to_player.angle()
	pursuer_car.velocity = to_player.normalized() * PURSUER_SPEED
	pursuer_car.move_and_slide()


func _check_rear_fire() -> void:
	if pursuer_defeated or not player_car or not pursuer_car:
		rear_fire_btn.visible = false
		return

	var rear_facing := -Vector2.RIGHT.rotated(player_car.rotation)
	var to_pursuer := pursuer_car.position - player_car.position
	var dist := to_pursuer.length()
	var dot := rear_facing.dot(to_pursuer.normalized()) if dist > 0.01 else 0.0

	_fire_target_valid = dist <= REAR_CONE_RANGE and dot >= REAR_CONE_DOT
	rear_fire_btn.visible = _fire_target_valid

	if _fire_target_valid and InputBridge.consume_just_pressed("rear_shoot"):
		pursuer_damage += 1
		if pursuer_damage >= PURSUER_DAMAGE_MAX:
			pursuer_defeated = true
			rear_fire_btn.visible = false


func _check_escape_finish() -> void:
	if _phase != "escape" or not player_car:
		return
	if player_car.position.distance_to(escape_finish.position) < 50.0:
		_phase = "outro"
		_controls_locked = true
		accel_btn.visible = false
		brake_btn.visible = false
		rear_fire_btn.visible = false
		if pursuer_defeated:
			story.say(
				[
					"O carro atrás perde o controle e bate na mureta — um obstáculo a menos entre o Mark e o que vem a seguir.",
					"Theo, ofegante, bate na lateral do carro: \"Prova em mãos, perseguidor fora. Falta só o Kessler.\"",
					"Fim da Fase 5 — O Cofre.",
				],
				["", "Theo Marsh", ""]
			)
		else:
			story.say(
				[
					"O carro atrás desiste perto da saída do Cais — reforço demais visível na área, nem Kessler arriscaria tanto por um motorista a menos.",
					"Theo, ofegante: \"A gente tirou a prova. Falta só o Kessler agora.\"",
					"Fim da Fase 5 — O Cofre.",
				],
				["", "Theo Marsh", ""]
			)


func _update_hud() -> void:
	match _phase:
		"fight":
			status_label.text = tr("Limpe a sala do cofre: %d guardas restantes. Avance de mesa em mesa.") % combat.alive_count() + "   " + tr("Colete: %d/%d") % [player.vest_hp, player.vest_hits]
		"open":
			status_label.text = tr("Objetivo: chegue no cofre e segure ABRIR COFRE.")
		"escape":
			status_label.text = tr("Fuja! Alinhe o carro e ATIRE PRA TRÁS pra deter o perseguidor.")
		"down":
			status_label.text = tr("Mark foi abatido — recomeçando a missão...")
		"done":
			status_label.text = tr("Fase 5 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if vault_obj:
		draw_circle(vault_obj.position, 20.0, Color(0.3, 0.7, 0.4) if _vault_opened else Color(0.85, 0.7, 0.2))

	if player_car:
		_draw_car(player_car.position, player_car.rotation, Color(0.3, 0.6, 0.9))
		if _phase == "escape" and _fire_target_valid:
			var rear_facing := -Vector2.RIGHT.rotated(player_car.rotation)
			draw_dashed_line(player_car.position, player_car.position + rear_facing * REAR_CONE_RANGE, Color(1.0, 0.3, 0.3, 0.6), 2.0, 8.0)
	if pursuer_car and not pursuer_defeated:
		_draw_car(pursuer_car.position, pursuer_car.rotation, Color(0.15, 0.15, 0.15))
	if escape_finish:
		draw_circle(escape_finish.position, 16.0, Color(0.3, 0.8, 0.4, 0.4))


func _draw_car(pos: Vector2, rot: float, color: Color) -> void:
	var half := Vector2(14, 8)
	var points := PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)
	])
	for i in points.size():
		points[i] = pos + points[i].rotated(rot)
	draw_colored_polygon(points, color)
	draw_line(pos, pos + Vector2.RIGHT.rotated(rot) * 20.0, Color.WHITE, 2.0)
