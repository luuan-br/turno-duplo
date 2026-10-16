extends Node2D
## Ato 4, Fase 4 — "Luzes de Volta" (docs/ROTEIRO.md). Respiro deliberado
## entre a Extração e o Cofre — sem combate, reaproveita só movimento +
## interação por proximidade (padrão "examinar" generalizado). Paga o
## hobby de rádio amador da Emma (GDD Seção 10, plantado como
## caracterização desde a Fase 5 do Ato 3): ela é quem identifica, pelo
## scanner, qual painel reconectar primeiro — o pequeno momento de
## agência dela que o GDD prometia, em vez de ficar só como "a criança
## em perigo" passiva.

const YARD_SIZE := Vector2(780.0, 420.0)
const YARD_ORIGIN := Vector2(60.0, 60.0)
const WALL_THICK := 20.0
const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const INTERACT_DIST := 55.0

var player: CharacterBody2D
var panels: Array[Area2D] = []
var panel_done: Array[bool] = [false, false, false]
var _active_panel := -1

var reactivate_btn: Control
var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> radio -> work -> outro -> done

const SCENE_PATH := "res://missions/ato4_fase4_luzes.tscn"


func _ready() -> void:
	_build_yard()
	_build_player()
	_build_panels()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"Sem luz, sem câmera, sem rádio — Mark e Theo estão quase tão cegos quanto a cidade.",
			"O rádio pessoal de Mark crepita com um canal que ninguém devia estar usando: Emma, do quarto dela, no scanner que ganhou de aniversário.",
			"\"Pai? Pai, eu tô ouvindo os código de vocês — tem um painel de força perto do guindaste maior, o código que o despachante falou foi esse mesmo que vocês precisam!\"",
		],
		["", "", "Emma Reyes"]
	)


func _build_yard() -> void:
	var o := YARD_ORIGIN
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(YARD_SIZE.x, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + YARD_SIZE.y - WALL_THICK), Vector2(YARD_SIZE.x, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, YARD_SIZE.y)),
		Rect2(Vector2(o.x + YARD_SIZE.x - WALL_THICK, o.y), Vector2(WALL_THICK, YARD_SIZE.y)),
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
		poly.color = Color(0.12, 0.13, 0.16)
		poly.position = r.position
		add_child(poly)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = YARD_ORIGIN + Vector2(60, YARD_SIZE.y - 70)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_panels() -> void:
	var positions := [
		YARD_ORIGIN + Vector2(220, 100),
		YARD_ORIGIN + Vector2(YARD_SIZE.x - 150, 160),
		YARD_ORIGIN + Vector2(YARD_SIZE.x * 0.5, YARD_SIZE.y - 100),
	]
	for pos in positions:
		var panel := Area2D.new()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		shape.shape = circle
		panel.add_child(shape)
		panel.position = pos
		panel.monitorable = true
		add_child(panel)
		panels.append(panel)


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
	left_stick.anchor_right = 1.0
	left_stick.anchor_top = 0.0
	left_stick.anchor_bottom = 1.0
	layer.add_child(left_stick)

	reactivate_btn = Control.new()
	reactivate_btn.set_script(load("res://ui/contextual_button.gd"))
	reactivate_btn.action_name = "reactivate"
	reactivate_btn.label_text = tr("REATIVAR")
	reactivate_btn.layout_slot = "acao_principal"
	reactivate_btn.anchor_left = 1.0
	reactivate_btn.anchor_right = 1.0
	reactivate_btn.anchor_top = 1.0
	reactivate_btn.anchor_bottom = 1.0
	reactivate_btn.offset_right = -30.0
	reactivate_btn.offset_left = -130.0
	reactivate_btn.offset_bottom = -30.0
	reactivate_btn.offset_top = -130.0
	reactivate_btn.visible = false
	layer.add_child(reactivate_btn)


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
			_phase = "work"
			_controls_locked = false
		"panel_feedback":
			_phase = "work"
			_controls_locked = false
		"outro":
			_phase = "done"
			next_btn.visible = true


func _check_panels() -> void:
	if _phase != "work":
		reactivate_btn.visible = false
		return

	if _active_panel == -1:
		for i in panels.size():
			if panel_done[i]:
				continue
			if player.position.distance_to(panels[i].position) < INTERACT_DIST:
				_active_panel = i
				break

	if _active_panel == -1:
		reactivate_btn.visible = false
		return

	reactivate_btn.visible = true
	if player.position.distance_to(panels[_active_panel].position) >= INTERACT_DIST:
		_active_panel = -1
		reactivate_btn.visible = false
		return

	if InputBridge.consume_just_released("reactivate"):
		panel_done[_active_panel] = true
		var idx := _active_panel
		_active_panel = -1
		reactivate_btn.visible = false
		_report_panel(idx)


func _report_panel(idx: int) -> void:
	var done_count := panel_done.count(true)
	if done_count < 3:
		_controls_locked = true
		_phase = "panel_feedback"
		if done_count == 1:
			story.say(
				["Luz pisca, apaga, volta firme. Um de três.", "Theo, pelo rádio: \"Mais dois e a gente enxerga o Cofre de novo.\""],
				["", "Theo Marsh"]
			)
		else:
			story.say([tr("Painel %d reconectado. Faltam %d.") % [idx + 1, 3 - done_count]], [""])
	else:
		_controls_locked = true
		_phase = "outro"
		story.say(
			[
				"O terceiro painel sobe com um estrondo de transformador religado — e o Cais inteiro pisca de volta à vida, luz por luz.",
				"\"BOA, PAI!\", Emma grita no rádio, longe de qualquer protocolo policial, e ninguém no canal reclama dessa vez.",
				"Com câmera e comunicação de volta, o caminho pro Cofre finalmente está limpo.",
				"Fim da Fase 4 — Luzes de Volta.",
			],
			["", "Emma Reyes", "", ""]
		)


func _process(_delta: float) -> void:
	if not _controls_locked:
		_move_player()
	_check_panels()
	_update_hud()
	queue_redraw()


func _move_player() -> void:
	player.velocity = InputBridge.move_vector * SPEED_CAUTIOUS
	player.move_and_slide()


func _update_hud() -> void:
	match _phase:
		"work":
			status_label.text = tr("Objetivo: reative os 3 painéis de força. (%d/3)") % panel_done.count(true)
		"done":
			status_label.text = tr("Fase 4 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
	for i in panels.size():
		draw_circle(panels[i].position, 16.0, Color(0.3, 0.8, 0.4) if panel_done[i] else Color(0.8, 0.7, 0.2))
