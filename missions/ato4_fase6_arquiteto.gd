extends Node2D
## Ato 4, Fase 6 — "O Arquiteto" (docs/ROTEIRO.md). Confronto final:
## primeira vez que **Adrian Kessler** aparece em pessoa e é chamado
## pelo nome. Ele não é lutador, é planejador encurralado pela primeira
## vez: o confronto com ele termina com Mark o alcançando e o detendo
## fisicamente (DETER), não com um tiro — polícia realista, não execução.
## Quem atira são os quatro guardas da escolta final, com o combate de
## risco real (`actors/`): dois parados protegendo o Kessler, dois
## patrulhando entre os consoles.

const ROOM_SIZE := Vector2(560.0, 400.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0
const INTERACT_DIST := 55.0
const VEST_HITS := 2
## Munição — Ato 4: equipamento de ação (GDD Seção 8).
const MAG_SIZE := 10
const SPARE_AMMO := 10
const DROP_AMMO := 8
const CORRIDOR_SIZE := Vector2(480.0, 140.0)
const KESSLER_FLEE_SPEED := 55.0
const WALL_COLOR := Color(0.18, 0.16, 0.22)
const CONSOLE_COLOR := Color(0.25, 0.27, 0.33)

var player: TacticalPlayer
var combat: CombatLayer
var kessler_marker: Node2D
var _kessler_fleeing := false
var _kessler_caught := false
var kessler_target: Vector2

var fire_btn: Control
var reload_btn: Control
var detain_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> fight -> aftermath -> corridor -> catch -> outro -> done (ou down -> recomeça)

const SCENE_PATH := "res://missions/ato4_fase6_arquiteto.tscn"


func _ready() -> void:
	_build_rooms()
	combat = CombatLayer.new()
	add_child(combat)
	_build_player()
	_build_kessler()
	_build_guards()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O escritório de controle fica no andar de cima do Cofre — câmeras, planilhas, um mapa do Cais com alfinetes demais pra ser coisa de amador.",
			"É dali que tudo foi comandado. Um homem de terno, de costas, guarda arquivos numa pasta sem pressa. Quatro seguranças entre ele e a porta.",
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


func _build_rooms() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	var cw := CORRIDOR_SIZE.x
	var ch := CORRIDOR_SIZE.y
	var c_origin := o + Vector2(w, (h - ch) * 0.5)

	_add_block(Rect2(o, Vector2(w, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(Vector2(o.x, o.y + h - WALL_THICK), Vector2(w, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(o, Vector2(WALL_THICK, h)), WALL_COLOR)
	# Parede direita com a passagem pro corredor (antes ficava aberta pro
	# vazio acima e abaixo do corredor).
	var right_x := o.x + w - WALL_THICK
	_add_block(Rect2(Vector2(right_x, o.y), Vector2(WALL_THICK, c_origin.y + WALL_THICK - o.y)), WALL_COLOR)
	_add_block(Rect2(Vector2(right_x, c_origin.y + ch - WALL_THICK), Vector2(WALL_THICK, o.y + h - (c_origin.y + ch - WALL_THICK))), WALL_COLOR)

	_add_block(Rect2(c_origin, Vector2(cw, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(Vector2(c_origin.x, c_origin.y + ch - WALL_THICK), Vector2(cw, WALL_THICK)), WALL_COLOR)
	_add_block(Rect2(Vector2(c_origin.x + cw - WALL_THICK, c_origin.y), Vector2(WALL_THICK, ch)), WALL_COLOR)

	var floor2 := Polygon2D.new()
	floor2.polygon = PackedVector2Array([Vector2.ZERO, Vector2(cw - WALL_THICK, 0), Vector2(cw - WALL_THICK, ch - WALL_THICK * 2), Vector2(0, ch - WALL_THICK * 2)])
	floor2.color = Color(0.12, 0.1, 0.15)
	floor2.position = c_origin + Vector2(0, WALL_THICK)
	floor2.z_index = -1
	add_child(floor2)

	# Consoles: cobertura pra cruzar a sala até a escolta do Kessler.
	_add_block(Rect2(o + Vector2(160, 90), Vector2(30, 100)), CONSOLE_COLOR)
	_add_block(Rect2(o + Vector2(300, 240), Vector2(100, 30)), CONSOLE_COLOR)
	_add_block(Rect2(o + Vector2(140, 300), Vector2(60, 30)), CONSOLE_COLOR)

	kessler_target = c_origin + Vector2(cw - 70, ch * 0.5)


func _build_player() -> void:
	player = TacticalPlayer.new()
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 60)
	player.set_vest(VEST_HITS)
	player.set_ammo(MAG_SIZE, SPARE_AMMO)
	add_child(player)
	combat.setup(player)
	combat.drop_ammo = DROP_AMMO
	combat.player_downed.connect(_on_player_downed)
	combat.all_guards_down.connect(_on_all_guards_down)


func _build_kessler() -> void:
	kessler_marker = Node2D.new()
	kessler_marker.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x - 60, ROOM_SIZE.y * 0.5)
	add_child(kessler_marker)


func _build_guards() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	combat.add_guard([o + Vector2(w - 120, 110)], Vector2(-1.0, 0.4))
	combat.add_guard([o + Vector2(w - 120, h - 110)], Vector2(-1.0, -0.4))
	combat.add_guard([o + Vector2(340, 50), o + Vector2(340, 210)])
	combat.add_guard([o + Vector2(60, 50), o + Vector2(220, 50)])


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

	detain_btn = _action_button("detain", tr("DETER"), 30.0, 180.0, 100.0, 100.0)
	detain_btn.show_hold_progress = true
	detain_btn.visible = false
	layer.add_child(detain_btn)


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
			_phase = "corridor"
			_controls_locked = false
			_kessler_fleeing = true
		"catch", "outro":
			_phase = "done"
			next_btn.visible = true


func _on_all_guards_down() -> void:
	if _phase != "fight":
		return
	_phase = "aftermath"
	_controls_locked = true
	story.say(
		[
			"O último segurança cai. A sala fica quieta — só o homem de terno, ainda arrumando a pasta como se tivesse todo o tempo do mundo.",
			"\"Oficial Reyes\", ele diz, sem se virar. \"Eu devia ter previsto um detetive teimoso. Erro meu.\"",
			"\"Adrian Kessler\", Mark responde — o nome que levou um ato inteiro pra existir, finalmente dito em voz alta.",
			"Kessler vira, pasta na mão, e caminha rápido demais pro corredor de saída.",
		],
		["", "Adrian Kessler", "", ""]
	)


func _on_player_downed() -> void:
	_phase = "down"
	_controls_locked = true
	combat.restart_mission()


func _check_catch() -> void:
	if _phase != "corridor" or _kessler_caught:
		detain_btn.visible = false
		return
	var near := player.position.distance_to(kessler_marker.position) < INTERACT_DIST
	detain_btn.visible = near
	if near and InputBridge.consume_just_released("detain"):
		_kessler_caught = true
		_kessler_fleeing = false
		detain_btn.visible = false
		_phase = "catch"
		_controls_locked = true
		story.say(
			[
				"Mark não puxa a arma. Larga o manual por um segundo e simplesmente corre — alcança Kessler antes da porta do fim do corredor, derruba a pasta, imobiliza.",
				"\"Isso não muda nada\", Kessler diz, sem fôlego, sem o controle de antes. \"Vão substituir cada parte do que eu construí.\"",
				"\"Hoje não\", Mark responde. E pela primeira vez na carreira, não estava seguindo ordem de ninguém pra dizer isso.",
				"Theo chega logo atrás, algema em punho, sem perguntar como o Mark chegou primeiro.",
				"Fim da Fase 6 — O Arquiteto.",
			],
			["", "Adrian Kessler", "", "", ""]
		)


func _process(delta: float) -> void:
	player.controls_locked = _controls_locked
	player.can_shoot = _phase == "fight"
	fire_btn.visible = _phase == "fight" and not _controls_locked
	reload_btn.visible = fire_btn.visible and player.can_reload()
	_check_catch()
	if _kessler_fleeing and not _kessler_caught:
		kessler_marker.position = kessler_marker.position.move_toward(kessler_target, KESSLER_FLEE_SPEED * delta)
	_update_hud()
	queue_redraw()


func _update_hud() -> void:
	match _phase:
		"fight":
			status_label.text = tr("Derrube a escolta do Kessler: %d restantes. Os dois do fundo não saem do lado dele.") % combat.alive_count() + "   " + tr("Colete: %d/%d") % [player.vest_hp, player.vest_hits] + "\n" + player.ammo_text()
		"corridor":
			status_label.text = tr("Objetivo: alcance o Kessler antes que ele chegue na saída e segure DETER.")
		"down":
			status_label.text = tr("Mark foi abatido — recomeçando a missão...")
		"done":
			status_label.text = tr("Fase 6 concluída. Fim do Ato 4.")
		_:
			status_label.text = ""


func _draw() -> void:
	if kessler_marker:
		draw_circle(kessler_marker.position, 15.0, Color(0.5, 0.15, 0.15))
		_draw_name_tag(kessler_marker.position, "Kessler" if _phase != "intro" and _phase != "fight" else "?")


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
