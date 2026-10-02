extends Node2D
## Ato 4, Fase 6 — "O Arquiteto" (docs/ROTEIRO.md). Confronto final:
## primeira vez que **Adrian Kessler** aparece em pessoa e é chamado
## pelo nome — até aqui ele só existia como motivação e rastro (GDD
## Seção 5). Ele não é lutador, é planejador encurralado pela primeira
## vez (Seção 3, Pilar "momento McClane"): não tem um "threat" pra
## atirar nele — o confronto termina com Mark o alcançando e o detendo
## fisicamente, não com um tiro, coerente com o tom do jogo (polícia
## realista, não execução). Os guardas finais, esses sim, reaproveitam o
## padrão tático de tiro já validado.

const ROOM_SIZE := Vector2(460.0, 360.0)
const ROOM_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0
const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const FIRE_RANGE := 900.0
const INTERACT_DIST := 55.0

const CORRIDOR_SIZE := Vector2(480.0, 140.0)

var player: CharacterBody2D
var threat_a: Area2D
var threat_a_hit := false
var threat_b: Area2D
var threat_b_hit := false
var kessler_marker: Node2D
var _kessler_fleeing := false
var _kessler_caught := false
var kessler_target: Vector2

var _facing := Vector2.RIGHT
const FACING_TURN_SPEED_AIMING := 9.0

var fire_btn: Control
var detain_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> fight_a -> between -> fight_b -> corridor -> catch -> outro -> done

var _aim_end := Vector2.ZERO
var _aim_hit_threat := false
var _aim_valid := false

const SCENE_PATH := "res://missions/ato4_fase6_arquiteto.tscn"


func _ready() -> void:
	_build_rooms()
	_build_player()
	_build_threats()
	_build_kessler()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"O escritório de controle fica no andar de cima do Cofre — câmeras, planilhas, um mapa do Cais com alfinetes demais pra ser coisa de amador.",
			"É dali que tudo foi comandado. E quem está lá dentro, pela primeira vez, não é um nome num arquivo.",
		],
		["", ""]
	)


func _build_rooms() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(w, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + h - WALL_THICK), Vector2(w, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, h)),
	]

	var c_origin := o + Vector2(w, (h - CORRIDOR_SIZE.y) * 0.5)
	var cw := CORRIDOR_SIZE.x
	var ch := CORRIDOR_SIZE.y
	rects.append(Rect2(c_origin, Vector2(cw, WALL_THICK)))
	rects.append(Rect2(Vector2(c_origin.x, c_origin.y + ch - WALL_THICK), Vector2(cw, WALL_THICK)))
	rects.append(Rect2(Vector2(c_origin.x + cw - WALL_THICK, c_origin.y), Vector2(WALL_THICK, ch)))

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
		poly.color = Color(0.18, 0.16, 0.22)
		poly.position = r.position
		add_child(poly)

	var floor2 := Polygon2D.new()
	floor2.polygon = PackedVector2Array([Vector2.ZERO, Vector2(cw - WALL_THICK, 0), Vector2(cw - WALL_THICK, ch - WALL_THICK * 2), Vector2(0, ch - WALL_THICK * 2)])
	floor2.color = Color(0.12, 0.1, 0.15)
	floor2.position = c_origin + Vector2(0, WALL_THICK)
	floor2.z_index = -1
	add_child(floor2)

	kessler_target = c_origin + Vector2(cw - 70, ch * 0.5)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 70)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_threats() -> void:
	threat_a = Area2D.new()
	var s1 := CollisionShape2D.new()
	var c1 := CircleShape2D.new()
	c1.radius = 15.0
	s1.shape = c1
	threat_a.add_child(s1)
	threat_a.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.4, ROOM_SIZE.y * 0.25)
	threat_a.monitorable = true
	add_child(threat_a)

	threat_b = Area2D.new()
	var s2 := CollisionShape2D.new()
	var c2 := CircleShape2D.new()
	c2.radius = 15.0
	s2.shape = c2
	threat_b.add_child(s2)
	threat_b.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.7, ROOM_SIZE.y * 0.65)
	threat_b.monitorable = true
	add_child(threat_b)


func _build_kessler() -> void:
	kessler_marker = Node2D.new()
	kessler_marker.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x + 100, ROOM_SIZE.y * 0.5)
	add_child(kessler_marker)


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
	right_stick.anchor_left = 0.5
	right_stick.anchor_right = 1.0
	right_stick.anchor_top = 0.0
	right_stick.anchor_bottom = 1.0
	layer.add_child(right_stick)

	fire_btn = _action_button("shoot", tr("ATIRAR"), 30.0, 180.0, 100.0, 100.0)
	fire_btn.visible = false
	layer.add_child(fire_btn)

	detain_btn = _action_button("detain", tr("DETER"), 30.0, 180.0, 100.0, 100.0)
	detain_btn.show_hold_progress = true
	detain_btn.visible = false
	layer.add_child(detain_btn)


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


func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "fight_a"
			_controls_locked = false
		"between":
			_phase = "fight_b"
			_controls_locked = false
		"aftermath":
			_phase = "corridor"
			_controls_locked = false
			_kessler_fleeing = true
		"catch":
			_phase = "outro"
		"outro":
			_phase = "done"
			next_btn.visible = true


func _check_fire() -> void:
	if _phase != "fight_a" and _phase != "fight_b":
		fire_btn.visible = false
		return
	fire_btn.visible = true

	var active_threat: Area2D = threat_a if _phase == "fight_a" else threat_b

	var space_state := get_world_2d().direct_space_state
	var start := player.position + _facing * (PLAYER_RADIUS + 2.0)
	var query := PhysicsRayQueryParameters2D.create(start, start + _facing * FIRE_RANGE)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	var result := space_state.intersect_ray(query)

	_aim_valid = true
	if result.is_empty():
		_aim_end = start + _facing * FIRE_RANGE
		_aim_hit_threat = false
	else:
		_aim_end = result.position
		_aim_hit_threat = result.collider == active_threat

	if InputBridge.consume_just_pressed("shoot") and not result.is_empty() and result.collider == active_threat:
		if _phase == "fight_a":
			threat_a_hit = true
			_phase = "between"
			_controls_locked = true
			story.say(["O primeiro guarda cai. Do outro lado da sala, uma silhueta nem se vira pra olhar — só continua guardando arquivos numa pasta."], [""])
		else:
			threat_b_hit = true
			_phase = "aftermath"
			_controls_locked = true
			story.say(
				[
					"O segundo cai. A sala fica quieta — só o homem de terno, de costas, ainda arrumando a pasta como se tivesse todo o tempo do mundo.",
					"\"Oficial Reyes\", ele diz, sem se virar. \"Eu devia ter previsto um detetive teimoso. Erro meu.\"",
					"\"Adrian Kessler\", Mark responde — o nome que levou um ato inteiro pra existir, finalmente dito em voz alta.",
					"Kessler vira, pasta na mão, e caminha rápido demais pro corredor de saída.",
				],
				["", "Adrian Kessler", "", ""]
			)


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
			],
			["", "Adrian Kessler", "", ""]
		)


func _process(delta: float) -> void:
	if not _controls_locked:
		_move_player()
		_update_facing(delta)
	_check_fire()
	_check_catch()
	if _kessler_fleeing:
		_update_kessler_flee(delta)
	_update_hud()
	queue_redraw()


func _move_player() -> void:
	player.velocity = InputBridge.move_vector * SPEED_CAUTIOUS
	player.move_and_slide()


func _update_facing(delta: float) -> void:
	if InputBridge.aim_touching and InputBridge.aim_vector.length() > 0.15:
		var target_dir := InputBridge.aim_vector.normalized()
		var diff := wrapf(target_dir.angle() - _facing.angle(), -PI, PI)
		var max_step := FACING_TURN_SPEED_AIMING * delta
		_facing = _facing.rotated(clamp(diff, -max_step, max_step))


func _update_kessler_flee(delta: float) -> void:
	if _kessler_caught:
		return
	var to_target := kessler_target - kessler_marker.position
	if to_target.length() > 4.0:
		kessler_marker.position = kessler_marker.position.move_toward(kessler_target, 55.0 * delta)


func _update_hud() -> void:
	match _phase:
		"fight_a", "fight_b":
			status_label.text = tr("Neutralize a ameaça.")
		"corridor":
			status_label.text = tr("Objetivo: alcance o Kessler antes que ele chegue na saída.")
		"done":
			status_label.text = tr("Fase 6 concluída. Fim do Ato 4.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
		if (_phase == "fight_a" or _phase == "fight_b") and _aim_valid:
			var line_color := Color(0.3, 1.0, 0.4, 0.8) if _aim_hit_threat else Color(1.0, 1.0, 1.0, 0.35)
			draw_dashed_line(player.position, _aim_end, line_color, 2.0, 10.0)
			draw_circle(_aim_end, 5.0, line_color)
		else:
			draw_line(player.position, player.position + _facing * (PLAYER_RADIUS + 24.0), Color.WHITE, 3.0)

	if threat_a:
		draw_circle(threat_a.position, 15.0, Color(0.2, 0.2, 0.2) if threat_a_hit else Color(0.8, 0.2, 0.2))
	if threat_b and threat_a_hit:
		draw_circle(threat_b.position, 15.0, Color(0.2, 0.2, 0.2) if threat_b_hit else Color(0.8, 0.2, 0.2))

	if kessler_marker and threat_b_hit:
		draw_circle(kessler_marker.position, 15.0, Color(0.5, 0.15, 0.15))
		_draw_name_tag(kessler_marker.position, "Kessler")


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
