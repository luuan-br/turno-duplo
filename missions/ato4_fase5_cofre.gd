extends Node2D
## Ato 4, Fase 5 — "O Cofre" (docs/ROTEIRO.md). Breach & clear final
## contra o músculo de apoio de Kessler, com o combate de risco real
## (`actors/`): três guardas na sala do cofre — um parado vigiando o
## cofre, dois patrulhando — e mesas de cobertura. Depois, a fuga de carro
## atirando pra trás (fusão tático+perseguição, mira automática por cone
## virada pra trás), agora com risco real (`actors/`): pista longa em
## zigue-zague, dois carros de reforço atrás — um tenta bater, o outro tem
## atirador — e lataria. Carro destruído = a missão recomeça do início.

const ROOM_SIZE := Vector2(560.0, 420.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0
const VEST_HITS := 2
## Munição — Ato 4: equipamento de ação (GDD Seção 8).
const MAG_SIZE := 10
const SPARE_AMMO := 10
const DROP_AMMO := 8
const WALL_COLOR := Color(0.2, 0.19, 0.16)
const DESK_COLOR := Color(0.33, 0.29, 0.22)

const TRACK_SIZE := Vector2(1600.0, 300.0)
const TRACK_ORIGIN := Vector2(80.0, 540.0)
const TRACK_WALL_COLOR := Color(0.14, 0.14, 0.18)
const BARRIER_COLOR := Color(0.45, 0.35, 0.15)
const REAR_SHOT_DAMAGE := 1.0
const PURSUIT_HEAD_START := 1.2

var player: TacticalPlayer
var combat: CombatLayer
var vault_obj: Area2D
var _vault_opened := false

var car: PlayerCar
var chase: ChaseLayer
var escape_finish: Node2D

var left_stick: Control
var right_stick: Control
var fire_btn: Control
var reload_btn: Control
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
	chase = ChaseLayer.new()
	add_child(chase)
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
	_add_block(Rect2(top, Vector2(w, WALL_THICK)), TRACK_WALL_COLOR)
	_add_block(Rect2(Vector2(top.x, top.y + h - WALL_THICK), Vector2(w, WALL_THICK)), TRACK_WALL_COLOR)
	_add_block(Rect2(top, Vector2(WALL_THICK, h)), TRACK_WALL_COLOR)
	_add_block(Rect2(Vector2(top.x + w - WALL_THICK, top.y), Vector2(WALL_THICK, h)), TRACK_WALL_COLOR)
	# Barreiras alternando em cima/embaixo: obriga zigue-zague (e frear),
	# que é quando os carros de trás encostam.
	var inner_h := h - WALL_THICK * 2.0
	var barrier_h := inner_h * 0.65
	for i in 4:
		var x := top.x + 380.0 + i * 300.0
		var y := top.y + WALL_THICK if i % 2 == 0 else top.y + h - WALL_THICK - barrier_h
		_add_block(Rect2(Vector2(x, y), Vector2(40, barrier_h)), BARRIER_COLOR)

	escape_finish = Node2D.new()
	escape_finish.position = top + Vector2(w - 70, h * 0.5)
	add_child(escape_finish)


func _build_player() -> void:
	player = TacticalPlayer.new()
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 70)
	player.set_vest(VEST_HITS)
	player.set_ammo(MAG_SIZE, SPARE_AMMO)
	player.extra_exclude = [vault_obj.get_rid()]
	add_child(player)
	combat.setup(player)
	combat.drop_ammo = DROP_AMMO
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

	# Abaixo do ATIRAR, menor e com vão: a área de toque é o círculo
	# inteiro — encostados, os dois disputariam o mesmo dedo.
	reload_btn = _corner_button("reload", tr("RECARGA"), 44.0, 74.0, 72.0, 72.0)
	reload_btn.radius = 36.0
	reload_btn.visible = false
	layer.add_child(reload_btn)

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


func _process(_delta: float) -> void:
	player.controls_locked = _controls_locked or car != null
	player.can_shoot = _phase == "fight"
	fire_btn.visible = _phase == "fight" and not _controls_locked
	reload_btn.visible = fire_btn.visible and player.can_reload()
	_check_vault()

	if _phase == "escape" and car == null:
		_spawn_cars()
	if car != null:
		var escaping := _phase == "escape" and not _controls_locked
		car.controls_locked = not escaping
		accel_btn.visible = escaping
		brake_btn.visible = escaping
		# O manche direito fica embaixo do mesmo canto dos botões de carro —
		# escondido na fuga pra não disputar toque com ACELERAR/FREAR/ATIRAR.
		right_stick.visible = not escaping
		rear_fire_btn.visible = escaping and chase.auto_target != null
		if escaping and InputBridge.consume_just_pressed("rear_shoot"):
			chase.fire_auto(REAR_SHOT_DAMAGE)
		_check_escape_finish()

	_update_hud()
	queue_redraw()


# ---------- trecho de fuga de carro ----------

func _spawn_cars() -> void:
	# Desativa a câmera tática explicitamente antes de ligar a do carro —
	# duas Camera2D com enabled=true ao mesmo tempo nem sempre trocam
	# sozinhas de forma confiável (bug relatado: câmera ficava presa no
	# player tático durante a fuga).
	player.camera.enabled = false
	player.visible = false

	car = PlayerCar.new()
	car.position = TRACK_ORIGIN + Vector2(160, TRACK_SIZE.y * 0.5)
	car.max_speed = 190.0
	add_child(car)
	chase.setup(car)
	chase.aim_mode = -1
	chase.ram_damage = 1.0
	chase.player_wrecked.connect(_on_car_wrecked)

	# Reforços nascem dentro da pista, atrás do jogador (fora da parede
	# esquerda eles ficavam presos do lado de fora do cenário).
	var rammer := EnemyCar.new()
	rammer.mode = EnemyCar.Mode.PURSUE
	rammer.position = TRACK_ORIGIN + Vector2(WALL_THICK + 25.0, TRACK_SIZE.y * 0.3)
	rammer.speed = 160.0
	rammer.max_hp = 2.0
	rammer.body_color = Color(0.45, 0.1, 0.1)
	chase.add_enemy(rammer)

	var gunner := EnemyCar.new()
	gunner.mode = EnemyCar.Mode.PURSUE
	gunner.position = TRACK_ORIGIN + Vector2(WALL_THICK + 25.0, TRACK_SIZE.y * 0.7)
	gunner.speed = 135.0
	gunner.max_hp = 2.0
	gunner.shooter = true
	gunner.shot_damage = 20.0
	gunner.body_color = Color(0.15, 0.15, 0.15)
	chase.add_enemy(gunner)

	# Um instante de vantagem antes dos reforços largarem.
	get_tree().create_timer(PURSUIT_HEAD_START).timeout.connect(_start_pursuit)


func _start_pursuit() -> void:
	if _phase == "escape":
		chase.set_active(true)


func _on_car_wrecked() -> void:
	if _phase != "escape":
		return
	_phase = "down"
	_controls_locked = true
	chase.restart_mission()


func _check_escape_finish() -> void:
	if _phase != "escape":
		return
	if car.global_position.distance_to(escape_finish.position) < 50.0:
		_phase = "outro"
		_controls_locked = true
		chase.set_active(false)
		if chase.active_count() == 0:
			story.say(
				[
					"Os dois carros de trás ficam pelo caminho — um na mureta, outro rodando no meio da pista.",
					"Theo, ofegante, bate na lateral do carro: \"Prova em mãos, reforço fora. Falta só o Kessler.\"",
					"Fim da Fase 5 — O Cofre.",
				],
				["", "Theo Marsh", ""]
			)
		else:
			story.say(
				[
					"Os carros de trás desistem perto da saída do Cais — viatura demais chegando, nem Kessler arriscaria tanto por uma pasta a menos.",
					"Theo, ofegante: \"A gente tirou a prova. Falta só o Kessler agora.\"",
					"Fim da Fase 5 — O Cofre.",
				],
				["", "Theo Marsh", ""]
			)


func _update_hud() -> void:
	match _phase:
		"fight":
			status_label.text = tr("Limpe a sala do cofre: %d guardas restantes. Avance de mesa em mesa.") % combat.alive_count() + "   " + tr("Colete: %d/%d") % [player.vest_hp, player.vest_hits] + "\n" + player.ammo_text()
		"open":
			status_label.text = tr("Objetivo: chegue no cofre e segure ABRIR COFRE.")
		"escape":
			status_label.text = tr("Fuja até a saída! Alinhe e ATIRE PRA TRÁS. Frear de repente faz quem vem atrás bater.") + "\n" + tr("Lataria: %d%%") % int(car.hp) + "   " + tr("Reforços: %d") % chase.active_count()
		"down":
			if car != null:
				status_label.text = tr("O carro não aguentou mais — recomeçando a missão...")
			else:
				status_label.text = tr("Mark foi abatido — recomeçando a missão...")
		"done":
			status_label.text = tr("Fase 5 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if vault_obj:
		draw_circle(vault_obj.position, 20.0, Color(0.3, 0.7, 0.4) if _vault_opened else Color(0.85, 0.7, 0.2))
	if escape_finish:
		draw_circle(escape_finish.position, 16.0, Color(0.3, 0.8, 0.4, 0.4))
