extends Node2D
## Ato 4, Fase 2 — "A Perseguição" (docs/ROTEIRO.md). Primeiro confronto
## direto com Wade "Ghost" Calloway — paga a rivalidade plantada sem
## rosto no Turno 4 do Ato 2 e nomeada no Ato 3. Termina batendo nele até
## quebrar ou atirando no pneu (mira automática por cone à frente).
##
## Risco real nas perseguições (`actors/`, GDD Seção 8): o Ghost não está
## sozinho — o parceiro atira pela janela de trás (com a linha de mira
## avisando antes), ele dá freada brusca quando o Mark cola atrás, a
## lataria do Mark aguenta só até certo ponto, e longe demais por tempo
## demais ele escapa. Carro destruído ou Ghost escapando = recomeça.

const TRACK_SIZE := Vector2(900.0, 500.0)
const TRACK_ORIGIN := Vector2(60.0, 40.0)
const WALL_THICK := 20.0
const TIRE_SHOT_DAMAGE := 2.0
const WALL_COLOR := Color(0.14, 0.14, 0.18)
const BLOCK_COLOR := Color(0.3, 0.27, 0.22)

var car: PlayerCar
var chase: ChaseLayer
var ghost: EnemyCar

var accel_btn: Control
var brake_btn: Control
var fire_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> chase -> outro -> done (ou down -> recomeça)

const SCENE_PATH := "res://missions/ato4_fase2_perseguicao.tscn"


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
			"Um carro sai em disparada do fim do Cais no instante em que o último guarda cai — alguém avisou alguém, em algum lugar.",
			"Theo reconhece o jeito de dirigir antes mesmo da placa. \"É ele. É o Ghost.\"",
			"Pela janela de trás, um braço com uma arma aparece. O Ghost não dirige sozinho.",
			"Pela primeira vez, Mark vai atrás de um nome, não de uma sombra.",
		],
		["", "Theo Marsh", "", ""]
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
	# Pátio de contêineres no meio: força a volta inteira e serve de
	# cobertura contra o tiro do parceiro do Ghost (quebra a linha de mira).
	_add_block(Rect2(top + Vector2(280, 180), Vector2(400, 140)), BLOCK_COLOR)
	_add_block(Rect2(top + Vector2(520, 24), Vector2(40, 26)), BLOCK_COLOR)
	_add_block(Rect2(top + Vector2(590, h - 60), Vector2(40, 26)), BLOCK_COLOR)


func _build_cars() -> void:
	var top := TRACK_ORIGIN
	var w := TRACK_SIZE.x
	var h := TRACK_SIZE.y

	car = PlayerCar.new()
	car.position = top + Vector2(60, 100)
	car.max_speed = 200.0
	car.accel = 230.0
	add_child(car)
	chase.setup(car)
	chase.ram_damage = 1.0
	chase.aim_mode = 1
	chase.escape_distance = 420.0
	chase.escape_time = 5.0
	chase.player_wrecked.connect(_on_failed.bind("O carro não aguentou mais — o Ghost sumiu na noite."))
	chase.suspect_escaped.connect(_on_failed.bind("Longe demais — o Ghost sumiu na noite."))
	chase.enemy_disabled.connect(_on_ghost_down)

	ghost = EnemyCar.new()
	ghost.waypoints = [
		top + Vector2(120, 100),
		top + Vector2(w - 120, 90),
		top + Vector2(w - 100, h - 110),
		top + Vector2(380, h - 90),
		top + Vector2(120, h - 250),
	]
	ghost.position = ghost.waypoints[0]
	ghost.speed = 175.0
	ghost.max_hp = 3.0
	ghost.body_color = Color(0.15, 0.15, 0.15)
	ghost.shooter = true
	ghost.shot_damage = 20.0
	ghost.fire_cooldown = 2.0
	ghost.brake_check = true
	chase.add_enemy(ghost)
	chase.escape_target = ghost


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
	fire_btn = _corner_button("shoot", tr("ATIRAR\nNO PNEU"), 30, 160, 110, 110)
	# Tiro dirigindo fica no lugar "extra" do carro, não no ATIRAR a pé.
	fire_btn.layout_slot = "carro_extra"
	fire_btn.visible = false
	layer.add_child(fire_btn)


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
		"outro":
			_phase = "done"
			next_btn.visible = true


func _on_ghost_down(_c: EnemyCar) -> void:
	if _phase != "chase":
		return
	_phase = "outro"
	_controls_locked = true
	chase.set_active(false)
	story.say(
		[
			"O carro do Ghost derrapa, bate de lado no guard-rail e para torto, fumaça saindo do capô.",
			"Ele sai mancando, mãos já no alto antes mesmo do Mark gritar pra parar — profissional até no jeito de se render.",
			"\"Bonito trabalho\", ele diz, sem ironia nenhuma. \"Faz tempo que ninguém me pega.\"",
			"Não é o fim da operação de Kessler. Mas é a primeira peça que sai do tabuleiro dele.",
			"Fim da Fase 2 — A Perseguição.",
		],
		["", "Wade \"Ghost\" Calloway", "Wade \"Ghost\" Calloway", "", ""]
	)


func _on_failed(reason: String) -> void:
	if _phase != "chase":
		return
	_phase = "down"
	_controls_locked = true
	status_label.text = tr(reason) + "  " + tr("Recomeçando a missão...")
	chase.restart_mission()


func _process(_delta: float) -> void:
	car.controls_locked = _controls_locked
	var driving := not _controls_locked
	accel_btn.visible = driving
	brake_btn.visible = driving
	fire_btn.visible = driving and chase.auto_target != null
	if InputBridge.consume_just_pressed("shoot") and driving:
		chase.fire_auto(TIRE_SHOT_DAMAGE)
	_update_hud()


func _bar(frac: float) -> String:
	var n := int(round(clampf(frac, 0.0, 1.0) * 10.0))
	return "[" + "#".repeat(n) + "-".repeat(10 - n) + "]"


func _update_hud() -> void:
	match _phase:
		"chase":
			status_label.text = tr("Bata forte nele ou alinhe à frente e ATIRE NO PNEU. Use os contêineres contra o tiro do parceiro.") + "\n" + tr("Lataria: %d%%") % int(car.hp) + "   " + tr("Ghost: %d/%d") % [int(maxf(ghost.hp, 0.0)), int(ghost.max_hp)] + "   " + tr("Fugindo: %s") % _bar(chase.escape_progress)
		"done":
			status_label.text = tr("Fase 2 concluída.")
		"down":
			pass
		_:
			status_label.text = ""
