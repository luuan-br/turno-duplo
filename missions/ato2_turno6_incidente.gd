extends Node2D
## Ato 2, Turno 6 — "O Incidente" (docs/ROTEIRO.md). Fecha o Ato 2 e abre
## o gancho pro Ato 3: um chamado de rotina dá errado, o Doyle é ferido
## em serviço (evento roteirizado, não falha do jogador), e o Mark enfrenta
## a primeira emboscada de verdade da história com o combate de risco real
## (`actors/`): o atirador já sabe que eles entraram (começa em combate) e
## um cúmplice nos fundos vem atrás do barulho dos tiros. Colete de
## patrulha segura um tiro. Depois, **examinar a cena** revela o detalhe
## que só vai fazer sentido no Ato 3.

const ROOM_SIZE := Vector2(460.0, 380.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const ROOM2_WIDTH := 380.0
const WALL_THICK := 20.0
const DOOR_GAP := 90.0

const PARTNER_FOLLOW_SPEED := 85.0
const PARTNER_FOLLOW_DIST := 50.0
const INTERACT_DIST := 55.0
const VEST_HITS := 1
const WALL_COLOR := Color(0.3, 0.28, 0.3)
const FURNITURE_COLOR := Color(0.38, 0.3, 0.26)

var player: TacticalPlayer
var combat: CombatLayer
var shooter: EnemyGuard
var doyle_marker: Node2D
var _doyle_down := false

var door_body: StaticBody2D
var door_open := false

var clue_obj: Area2D
var _clue_examined := false

var fire_btn: Control
var breach_btn: Control
var examine_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> approach -> ambush -> fight -> aftermath -> examine -> outro -> done (ou down -> recomeça)

const SCENE_PATH := "res://missions/ato2_turno6_incidente.tscn"


func _ready() -> void:
	_build_room()
	_build_door()
	_build_clue()
	combat = CombatLayer.new()
	add_child(combat)
	_build_player()
	_build_doyle()
	_build_guards()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"\"Desentendimento familiar, sem feridos reportados.\" Chamado número duzentos e tantos da semana — o tipo que ninguém mais presta atenção.",
			"Doyle nem checa o colete direito antes de descer da viatura. \"Esses são sempre rápidos\", ele diz. Vai ser a última coisa tranquila que ele diz hoje.",
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
	var gap := o.y + h * 0.5 - DOOR_GAP * 0.5
	_add_block(Rect2(Vector2(o.x + w - WALL_THICK, o.y), Vector2(WALL_THICK, gap - o.y)), WALL_COLOR)
	_add_block(Rect2(Vector2(o.x + w - WALL_THICK, gap + DOOR_GAP), Vector2(WALL_THICK, o.y + h - (gap + DOOR_GAP))), WALL_COLOR)

	var o2 := o + Vector2(w, 0)
	var w2 := ROOM2_WIDTH
	_add_block(Rect2(o2, Vector2(w2, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(Vector2(o2.x, o2.y + h - WALL_THICK), Vector2(w2, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(Vector2(o2.x + w2 - WALL_THICK, o2.y), Vector2(WALL_THICK, h)), WALL_COLOR)

	var floor2 := Polygon2D.new()
	floor2.polygon = PackedVector2Array([Vector2.ZERO, Vector2(w2 - WALL_THICK * 2, 0), Vector2(w2 - WALL_THICK * 2, h - WALL_THICK * 2), Vector2(0, h - WALL_THICK * 2)])
	floor2.color = Color(0.2, 0.16, 0.18)
	floor2.position = o2 + Vector2(WALL_THICK, WALL_THICK)
	floor2.z_index = -1
	add_child(floor2)

	# Mesa e sofá no cômodo da emboscada — cobertura pra quem entra pela
	# porta e pra quem vem dos fundos.
	_add_block(Rect2(o2 + Vector2(110, 90), Vector2(60, 40)), FURNITURE_COLOR)
	_add_block(Rect2(o2 + Vector2(110, 290), Vector2(60, 40)), FURNITURE_COLOR)


func _build_door() -> void:
	door_body = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WALL_THICK, DOOR_GAP)
	shape.shape = rect
	door_body.add_child(shape)
	var gap := ROOM_ORIGIN.y + ROOM_SIZE.y * 0.5 - DOOR_GAP * 0.5
	door_body.position = Vector2(ROOM_ORIGIN.x + ROOM_SIZE.x - WALL_THICK * 0.5, gap + DOOR_GAP * 0.5)
	# Sólida até arrombar — antes dava pra atravessar a porta fechada.
	add_child(door_body)


func _build_clue() -> void:
	clue_obj = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	clue_obj.add_child(shape)
	clue_obj.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x + 260, ROOM_SIZE.y * 0.3)
	clue_obj.monitorable = true
	add_child(clue_obj)


func _build_player() -> void:
	player = TacticalPlayer.new()
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 80)
	player.set_vest(VEST_HITS)
	player.extra_exclude = [clue_obj.get_rid()]
	add_child(player)
	combat.setup(player)
	combat.player_downed.connect(_on_player_downed)
	combat.all_guards_down.connect(_on_all_guards_down)


func _build_doyle() -> void:
	doyle_marker = Node2D.new()
	doyle_marker.position = player.position + Vector2(-30, 0)
	add_child(doyle_marker)


func _build_guards() -> void:
	var o2 := ROOM_ORIGIN + Vector2(ROOM_SIZE.x, 0)
	var h := ROOM_SIZE.y
	shooter = combat.add_guard([o2 + Vector2(160, h * 0.5)], Vector2.LEFT)
	combat.add_guard([o2 + Vector2(300, 80), o2 + Vector2(300, h - 80)])


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

	examine_btn = _action_button("examine", tr("EXAMINAR"), 30.0, 180.0, 100.0, 100.0)
	examine_btn.visible = false
	layer.add_child(examine_btn)


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
		"ambush":
			_phase = "fight"
			_controls_locked = false
			combat.set_active(true)
			shooter.force_combat(player.position)
		"aftermath":
			_phase = "examine"
			_controls_locked = false
		"outro":
			_phase = "done"
			next_btn.visible = true


func _update_door() -> void:
	if _phase != "approach":
		breach_btn.visible = false
		return
	var near := player.position.distance_to(door_body.position) < 60.0
	breach_btn.visible = near and not door_open
	if not breach_btn.visible:
		return
	if InputBridge.consume_just_released("breach"):
		door_open = true
		door_body.set_collision_layer_value(1, false)
		_phase = "ambush"
		_controls_locked = true
		_doyle_down = true
		story.say(
			[
				"A porta cede. Lá dentro, não tem casal brigando — tem um homem armado, e ele vira rápido demais pro Doyle reagir primeiro.",
				"Um tiro. Doyle cai contra a parede, mão no ombro, ainda tentando gritar um aviso que já chegou tarde.",
				"Tem mais alguém nos fundos — passos. Mark não tem tempo de ter medo.",
			],
			["", "", ""]
		)


func _on_all_guards_down() -> void:
	if _phase != "fight":
		return
	_phase = "aftermath"
	_controls_locked = true
	story.say(
		[
			"Os dois caem. Mark já está correndo pro Doyle antes mesmo de guardar a arma.",
			"\"Tô bem, tô bem\" — ele não está, mas a voz ainda sai firme. Mark pede reforço e ambulância antes de pensar em respirar de novo.",
			"Enquanto espera, alguma coisa na sala continua incomodando o Mark. Fora de lugar.",
		],
		["", "Sgt. Doyle", ""]
	)


func _on_player_downed() -> void:
	_phase = "down"
	_controls_locked = true
	combat.restart_mission()


func _check_examine() -> void:
	if _clue_examined or _phase != "examine":
		examine_btn.visible = false
		return
	var near := player.position.distance_to(clue_obj.position) < INTERACT_DIST
	examine_btn.visible = near
	if near and InputBridge.consume_just_pressed("examine"):
		_clue_examined = true
		examine_btn.visible = false
		_phase = "outro"
		_controls_locked = true
		story.say(
			[
				"Um roteador pequeno, escondido atrás do que devia ser só uma briga de família. Não combina com nada no resto do apartamento.",
				"Mark fotografa antes de mexer em qualquer coisa. Não sabe o que é — só sabe que não devia estar ali.",
				"Dias depois, Okafor lê o relatório duas vezes. \"Isso é faro de detetive, Reyes. Vem comigo.\"",
				"Doyle vai ficar bem — semanas de afastamento, não mais que isso. Mas o turno que era dos dois agora é só do Mark.",
				"Fim do Turno 6 — O Incidente. Fim do Ato 2 — Novato nas Ruas.",
			],
			["", "", "Capitã Okafor", "", ""]
		)


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	player.controls_locked = _controls_locked
	player.can_shoot = _phase == "fight"
	fire_btn.visible = _phase == "fight" and not _controls_locked
	_update_door()
	_check_examine()
	if not _doyle_down:
		_update_doyle_follow(delta)
	_update_hud()
	queue_redraw()


func _update_doyle_follow(delta: float) -> void:
	var to_player := player.position - doyle_marker.position
	if to_player.length() > PARTNER_FOLLOW_DIST:
		doyle_marker.position = doyle_marker.position.move_toward(player.position, PARTNER_FOLLOW_SPEED * delta)


func _update_hud() -> void:
	match _phase:
		"approach":
			status_label.text = tr("Objetivo: chegue na porta e arrombe.")
		"fight":
			status_label.text = tr("Emboscada! Saia da linha de tiro e neutralize as ameaças: %d restantes.") % combat.alive_count() + "   " + tr("Colete: %d/%d") % [player.vest_hp, player.vest_hits]
		"examine":
			status_label.text = tr("Objetivo: examine a cena antes de ir embora.")
		"down":
			status_label.text = tr("Mark foi abatido — recomeçando a missão...")
		"done":
			status_label.text = tr("Turno 6 concluído. Fim do Ato 2.")
		_:
			status_label.text = ""


func _draw() -> void:
	if doyle_marker:
		draw_circle(doyle_marker.position, 15.0, Color(0.3, 0.3, 0.3) if _doyle_down else Color(0.5, 0.35, 0.15))
		_draw_name_tag(doyle_marker.position, "Doyle")

	if door_body:
		if not door_open:
			draw_rect(Rect2(door_body.position - Vector2(WALL_THICK, DOOR_GAP) * 0.5, Vector2(WALL_THICK, DOOR_GAP)), Color(0.45, 0.3, 0.2))
		draw_circle(door_body.position, 8.0, Color.GREEN if door_open else Color(0.7, 0.15, 0.15))

	if clue_obj and _phase in ["examine", "outro", "done"]:
		draw_circle(clue_obj.position, 10.0, Color(0.2, 0.2, 0.2) if _clue_examined else Color(0.9, 0.8, 0.3))


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
