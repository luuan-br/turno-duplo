extends Node2D
## Ato 4, Fase 1 — "Infiltrar o Cais" (docs/ROTEIRO.md). Abre o Ato 4: o
## Theo Marsh assume como parceiro de ação (o Doyle está fora de combate).
## Primeiro combate de verdade contra gente do Kessler, com o sistema de
## risco real (`actors/`): três guardas patrulhando entre contêineres, um
## tiro derruba (o colete do Ato 4 segura dois), cair recomeça a missão.
## Arrombar o portão devagar entra em silêncio; rápido avisa todo mundo.

const YARD_SIZE := Vector2(480.0, 380.0)
const YARD_ORIGIN := Vector2(80.0, 60.0)
const YARD2_WIDTH := 420.0
const WALL_THICK := 20.0
const GATE_GAP := 90.0

const PARTNER_FOLLOW_SPEED := 85.0
const PARTNER_FOLLOW_DIST := 50.0
const VEST_HITS := 2
const NOISE_BREACH_LOUD := 450.0
const CRATE_COLOR := Color(0.42, 0.3, 0.18)

var player: TacticalPlayer
var combat: CombatLayer
var theo_marker: Node2D
var _theo_hold_pos := Vector2.ZERO
var _theo_holding := false

var gate_body: StaticBody2D
var gate_open := false

var fire_btn: Control
var breach_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> approach -> breach -> fight -> outro -> done (ou down -> recomeça)

const SCENE_PATH := "res://missions/ato4_fase1_infiltrar.tscn"


func _ready() -> void:
	_build_yard()
	combat = CombatLayer.new()
	add_child(combat)
	_build_player()
	_build_theo()
	_build_gate()
	_build_guards()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O Cais à noite não devia estar tão quieto. Sem guindaste rodando, sem rádio de trabalhador, só o som do próprio mar.",
			"Theo checa a arma pela terceira vez. \"Doyle não tá aqui. Hoje sou eu.\" Não é brincadeira — é um FTO de novo, só que invertido.",
			"\"Kessler isolou o quarteirão inteiro — câmera, semáforo, rádio. Então a gente é o único reforço que existe agora.\"",
		],
		["", "Theo Marsh", "Theo Marsh"]
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


func _build_yard() -> void:
	var o := YARD_ORIGIN
	var w := YARD_SIZE.x
	var h := YARD_SIZE.y
	var wall := Color(0.16, 0.18, 0.22)
	_add_block(Rect2(o, Vector2(w, WALL_THICK)), wall)
	_add_block(Rect2(Vector2(o.x, o.y + h - WALL_THICK), Vector2(w, WALL_THICK)), wall)
	_add_block(Rect2(o, Vector2(WALL_THICK, h)), wall)
	var gap := o.y + h * 0.5 - GATE_GAP * 0.5
	_add_block(Rect2(Vector2(o.x + w - WALL_THICK, o.y), Vector2(WALL_THICK, gap - o.y)), wall)
	_add_block(Rect2(Vector2(o.x + w - WALL_THICK, gap + GATE_GAP), Vector2(WALL_THICK, o.y + h - (gap + GATE_GAP))), wall)

	var o2 := o + Vector2(w, 0)
	var w2 := YARD2_WIDTH
	_add_block(Rect2(o2, Vector2(w2, WALL_THICK)), wall)
	_add_block(Rect2(Vector2(o2.x, o2.y + h - WALL_THICK), Vector2(w2, WALL_THICK)), wall)
	_add_block(Rect2(Vector2(o2.x + w2 - WALL_THICK, o2.y), Vector2(WALL_THICK, h)), wall)

	var floor2 := Polygon2D.new()
	floor2.polygon = PackedVector2Array([Vector2.ZERO, Vector2(w2 - WALL_THICK * 2, 0), Vector2(w2 - WALL_THICK * 2, h - WALL_THICK * 2), Vector2(0, h - WALL_THICK * 2)])
	floor2.color = Color(0.1, 0.11, 0.14)
	floor2.position = o2 + Vector2(WALL_THICK, WALL_THICK)
	floor2.z_index = -1
	add_child(floor2)

	# Contêineres: o do meio corta a linha de visão do vigia parado até o
	# portão — dá pra entrar sem ser visto se não fizer barulho.
	_add_block(Rect2(o2 + Vector2(200, 170), Vector2(50, 80)), CRATE_COLOR)
	_add_block(Rect2(o2 + Vector2(80, 290), Vector2(70, 40)), CRATE_COLOR)
	_add_block(Rect2(o2 + Vector2(290, 80), Vector2(40, 60)), CRATE_COLOR)


func _build_player() -> void:
	player = TacticalPlayer.new()
	player.position = YARD_ORIGIN + Vector2(60, YARD_SIZE.y - 70)
	player.set_vest(VEST_HITS)
	add_child(player)
	combat.setup(player)
	combat.player_downed.connect(_on_player_downed)
	combat.all_guards_down.connect(_on_all_guards_down)


func _build_theo() -> void:
	theo_marker = Node2D.new()
	theo_marker.position = player.position + Vector2(-30, 0)
	add_child(theo_marker)


func _build_gate() -> void:
	gate_body = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WALL_THICK, GATE_GAP)
	shape.shape = rect
	gate_body.add_child(shape)
	var gap := YARD_ORIGIN.y + YARD_SIZE.y * 0.5 - GATE_GAP * 0.5
	gate_body.position = Vector2(YARD_ORIGIN.x + YARD_SIZE.x - WALL_THICK * 0.5, gap + GATE_GAP * 0.5)
	gate_body.set_collision_layer_value(1, false)
	add_child(gate_body)
	_theo_hold_pos = gate_body.position + Vector2(-50, 40)


func _build_guards() -> void:
	var o2 := YARD_ORIGIN + Vector2(YARD_SIZE.x, 0)
	combat.add_guard([o2 + Vector2(360, 190)], Vector2.LEFT)
	combat.add_guard([o2 + Vector2(140, 100), o2 + Vector2(140, 270)])
	combat.add_guard([o2 + Vector2(60, 50), o2 + Vector2(260, 50)])


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
	left_stick.anchor_right = 0.5
	left_stick.anchor_top = 0.0
	left_stick.anchor_bottom = 1.0
	layer.add_child(left_stick)

	var right_stick := Control.new()
	right_stick.set_script(load("res://ui/virtual_joystick.gd"))
	right_stick.right_stick = true
	right_stick.double_tap_action = "shoot"
	right_stick.anchor_left = 0.5
	right_stick.anchor_right = 1.0
	right_stick.anchor_top = 0.0
	right_stick.anchor_bottom = 1.0
	layer.add_child(right_stick)

	breach_btn = _action_button("breach", tr("ARROMBAR"), 30.0, 180.0, 100.0, 100.0)
	breach_btn.show_hold_progress = true
	breach_btn.visible = false
	layer.add_child(breach_btn)

	fire_btn = _action_button("shoot", tr("ATIRAR"), 30.0, 180.0, 100.0, 100.0)
	fire_btn.visible = false
	layer.add_child(fire_btn)


func _action_button(action: String, label: String, right: float, bottom: float, w: float, h: float) -> Control:
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
			_phase = "approach"
			_controls_locked = false
		"breach":
			_phase = "fight"
			_controls_locked = false
			combat.set_active(true)
		"outro":
			_phase = "done"
			next_btn.visible = true


func _update_gate() -> void:
	if _phase != "approach":
		breach_btn.visible = false
		return
	var near := player.position.distance_to(gate_body.position) < 60.0
	breach_btn.visible = near and not gate_open
	if not breach_btn.visible:
		return
	if InputBridge.consume_just_released("breach"):
		gate_open = true
		_theo_holding = true
		_phase = "breach"
		_controls_locked = true
		if InputBridge.last_hold_time("breach") > 0.5:
			story.say(
				[
					"O portão cede devagar, sem barulho. Do outro lado, três homens de colete tático andam entre os contêineres — não são seguranças, são gente do Kessler.",
					"\"Eu seguro o portão\", Theo sussurra. \"Vai pela sombra dos contêineres. Eles ainda não sabem que a gente tá aqui.\"",
				],
				["", "Theo Marsh"]
			)
		else:
			combat.noise(gate_body.position, NOISE_BREACH_LOUD)
			story.say(
				[
					"O portão cede de uma vez, num estrondo de metal. Três homens de colete tático se viram pro barulho ao mesmo tempo.",
					"\"Pronto, agora eles sabem\", Theo resmunga, encostando no muro. \"Usa os contêineres de cobertura!\"",
				],
				["", "Theo Marsh"]
			)


func _on_all_guards_down() -> void:
	if _phase != "fight":
		return
	_phase = "outro"
	_controls_locked = true
	story.say(
		[
			"O último cai perto da cerca. Theo atravessa o portão e confirma: equipamento caro, treino de verdade, nada de amador.",
			"\"Isso não é golpe de rua\", Theo diz, baixo. \"Isso é operação militar paga.\"",
			"Mark já sabia. Mas ouvir alguém mais dizer em voz alta torna real.",
			"Fim da Fase 1 — Infiltrar o Cais.",
		],
		["", "Theo Marsh", "", ""]
	)


func _on_player_downed() -> void:
	_phase = "down"
	_controls_locked = true
	combat.restart_mission()


func _process(delta: float) -> void:
	player.controls_locked = _controls_locked
	player.can_shoot = _phase == "fight"
	fire_btn.visible = _phase == "fight" and not _controls_locked
	_update_gate()
	_update_theo(delta)
	_update_hud()
	queue_redraw()


func _update_theo(delta: float) -> void:
	var dest := _theo_hold_pos if _theo_holding else player.position
	var to := dest - theo_marker.position
	var stop_dist := 2.0 if _theo_holding else PARTNER_FOLLOW_DIST
	if to.length() > stop_dist:
		theo_marker.position = theo_marker.position.move_toward(dest, PARTNER_FOLLOW_SPEED * delta)


func _vest_text() -> String:
	return tr("Colete: %d/%d") % [player.vest_hp, player.vest_hits]


func _update_hud() -> void:
	match _phase:
		"approach":
			status_label.text = tr("Objetivo: chegue no portão. Segure ARROMBAR até fechar o anel pra entrar em silêncio.")
		"fight":
			status_label.text = tr("Neutralize os guardas: %d restantes. Use os contêineres de cobertura.") % combat.alive_count() + "   " + _vest_text()
		"down":
			status_label.text = tr("Mark foi abatido — recomeçando a missão...")
		"done":
			status_label.text = tr("Fase 1 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if theo_marker:
		draw_circle(theo_marker.position, 15.0, Color(0.2, 0.45, 0.3))
		_draw_name_tag(theo_marker.position, "Theo")
	if gate_body:
		draw_circle(gate_body.position, 8.0, Color.GREEN if gate_open else Color(0.7, 0.15, 0.15))


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
