extends Node2D
## Ato 4, Fase 3 — "Extração" (docs/ROTEIRO.md). Desvio pessoal: Sarah e
## Emma estão em perigo direto, e Mark interrompe a caçada a Kessler pra
## tirá-las de risco — o clímax pessoal do jogo. Combate com risco real
## (`actors/`): três sequestradores dentro de casa — um patrulha o
## corredor, um ronda o cômodo dos fundos, um vigia a família parado de
## frente pra passagem. Theo ficou segurando o Cais: aqui o Mark está
## sozinho. Fecha com "LIBERTAR" (segurar), no padrão de "ARROMBAR".

const ROOM_SIZE := Vector2(620.0, 400.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0
const INTERACT_DIST := 55.0
const VEST_HITS := 2
## Munição — Ato 4: equipamento de ação (GDD Seção 8).
const MAG_SIZE := 10
const SPARE_AMMO := 10
const DROP_AMMO := 8
const WALL_COLOR := Color(0.26, 0.22, 0.24)
const FURNITURE_COLOR := Color(0.36, 0.28, 0.3)

var player: TacticalPlayer
var combat: CombatLayer

var family_obj: Area2D
var _rescued := false

var fire_btn: Control
var reload_btn: Control
var rescue_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> fight -> aftermath -> rescue -> outro -> done (ou down -> recomeça)

const SCENE_PATH := "res://missions/ato4_fase3_extracao.tscn"


func _ready() -> void:
	_build_room()
	_build_family()
	combat = CombatLayer.new()
	add_child(combat)
	_build_player()
	_build_guards()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O rádio de Mark cospe estática e, no meio dela, a voz de um dos homens de Kessler — um erro de canal, não mensagem pra ele.",
			"\"A casa dos Reyes, segundo grupo. Mantém elas aí até a gente confirmar o Cofre.\"",
			"Mark já está correndo antes do Theo terminar de processar a frase. \"Vai\", Theo diz. \"Eu seguro o Cais sozinho.\"",
			"Na porta da própria casa, Mark ouve vozes que não são da família. Três, talvez. Ele entra sozinho.",
		],
		["", "", "Theo Marsh", ""]
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
	# Divisória entre o corredor e os fundos — a passagem fica embaixo.
	_add_block(Rect2(Vector2(o.x + w * 0.45, o.y), Vector2(WALL_THICK, h * 0.6)), WALL_COLOR)
	# Sofá no cômodo dos fundos: cobertura no meio do caminho até a família.
	_add_block(Rect2(o + Vector2(w * 0.7, h * 0.35), Vector2(70, 40)), FURNITURE_COLOR)


func _build_family() -> void:
	family_obj = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	family_obj.add_child(shape)
	family_obj.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x - 70, ROOM_SIZE.y - 70)
	family_obj.monitorable = true
	add_child(family_obj)


func _build_player() -> void:
	player = TacticalPlayer.new()
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 70)
	player.set_vest(VEST_HITS)
	player.set_ammo(MAG_SIZE, SPARE_AMMO)
	# Tiro que passa do sequestrador não "acerta" a família — gray box, sem
	# sistema de dano a civil aqui.
	player.extra_exclude = [family_obj.get_rid()]
	add_child(player)
	combat.setup(player)
	combat.drop_ammo = DROP_AMMO
	combat.player_downed.connect(_on_player_downed)
	combat.all_guards_down.connect(_on_all_guards_down)


func _build_guards() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	combat.add_guard([o + Vector2(60, 70), o + Vector2(w * 0.38, 70)])
	combat.add_guard([o + Vector2(w - 160, h - 100)], Vector2.LEFT)
	combat.add_guard([o + Vector2(w * 0.62, 60), o + Vector2(w * 0.62, h * 0.5)])


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

	fire_btn = _action_button("shoot", tr("ATIRAR"), 30.0, 180.0, 100.0, 100.0)
	fire_btn.visible = false
	layer.add_child(fire_btn)

	# Abaixo do ATIRAR, menor e com vão: a área de toque é o círculo
	# inteiro — encostados, os dois disputariam o mesmo dedo.
	reload_btn = _action_button("reload", tr("RECARGA"), 44.0, 74.0, 72.0, 72.0)
	reload_btn.radius = 36.0
	reload_btn.visible = false
	layer.add_child(reload_btn)

	rescue_btn = _action_button("rescue", tr("LIBERTAR"), 30.0, 180.0, 100.0, 100.0)
	rescue_btn.show_hold_progress = true
	rescue_btn.visible = false
	layer.add_child(rescue_btn)


func _action_button(action: String, label: String, right: float, bottom: float, w: float, h: float) -> Control:
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
			_phase = "rescue"
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
			"O último cai. A casa fica num silêncio que não parece a casa dele.",
			"Do fundo, uma voz abafada, tentando não gritar e falhando: \"Mark?! MARK?!\"",
		],
		["", "Sarah Reyes"]
	)


func _check_rescue() -> void:
	if _rescued or _phase != "rescue":
		rescue_btn.visible = false
		return
	var near := player.position.distance_to(family_obj.position) < INTERACT_DIST
	rescue_btn.visible = near
	if near and InputBridge.consume_just_released("rescue"):
		_rescued = true
		rescue_btn.visible = false
		_phase = "outro"
		_controls_locked = true
		story.say(
			[
				"A corda cede fácil — amadores, pressa, não crueldade específica. Sarah abraça Mark antes mesmo de ele guardar a arma.",
				"Emma não solta a camisa dele. Não chora. Só segura, com a força de quem decidiu não deixar ir de novo.",
				"\"Vocês estão seguras agora\", Mark diz — e pela primeira vez em muito tempo, acredita na própria frase.",
				"Mas o trabalho não acabou. Em algum lugar do Cais, o Cofre ainda está aberto.",
				"Fim da Fase 3 — Extração.",
			],
			["", "", "", "", ""]
		)


func _on_player_downed() -> void:
	_phase = "down"
	_controls_locked = true
	combat.restart_mission()


func _process(_delta: float) -> void:
	player.controls_locked = _controls_locked
	player.can_shoot = _phase == "fight"
	fire_btn.visible = _phase == "fight" and not _controls_locked
	reload_btn.visible = fire_btn.visible and player.can_reload()
	_check_rescue()
	_update_hud()
	queue_redraw()


func _update_hud() -> void:
	match _phase:
		"fight":
			status_label.text = tr("Tire os sequestradores de casa: %d restantes. O do fundo vigia a passagem.") % combat.alive_count() + "   " + tr("Colete: %d/%d") % [player.vest_hp, player.vest_hits] + "\n" + player.ammo_text()
		"rescue":
			status_label.text = tr("Objetivo: chegue até a Sarah e a Emma e segure LIBERTAR.")
		"down":
			status_label.text = tr("Mark foi abatido — recomeçando a missão...")
		"done":
			status_label.text = tr("Fase 3 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if family_obj:
		draw_circle(family_obj.position, 18.0, Color(0.3, 0.7, 0.4) if _rescued else Color(0.85, 0.75, 0.3))
