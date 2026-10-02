extends Node2D
## Ato 3, Fase 2 — "Ironside, de Novo" (docs/ROTEIRO.md). Mark volta ao
## bairro que patrulhava, agora como investigador. Escolha de quem
## pressionar — **Lou** (contatos de rua) ou **Miko** (ex-técnico ligado
## ao Kessler, ainda sem esse nome aparecer pro jogador) — rotas
## diferentes pra mesma pista. A escolha é por onde o jogador anda
## primeiro (zona de proximidade), não um prompt — combina melhor com o
## tom investigativo de "seguir uma pista" do que um menu de diálogo.

const STREET_SIZE := Vector2(760.0, 360.0)
const STREET_ORIGIN := Vector2(60.0, 60.0)
const WALL_THICK := 20.0
const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0

var player: CharacterBody2D
var lou_marker: Node2D
var miko_marker: Node2D
var lou_zone: Area2D
var miko_zone: Area2D
var _chosen := false

var story: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> free_roam -> talked -> done

const SCENE_PATH := "res://missions/ato3_fase2_ironside.tscn"


func _ready() -> void:
	_build_street()
	_build_player()
	_build_npcs()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"Ironside de dia parece menor do que Mark lembrava — ou talvez seja ele que ficou maior, com o distintivo novo no bolso.",
			"Dois nomes na lista de contatos do caso: o Lou, do bar da esquina, e o Miko, que conserta eletrônico três quarteirões daqui.",
		],
		["", ""]
	)


func _build_street() -> void:
	var o := STREET_ORIGIN
	var rects: Array[Rect2] = [
		Rect2(o, Vector2(STREET_SIZE.x, WALL_THICK)),
		Rect2(Vector2(o.x, o.y + STREET_SIZE.y - WALL_THICK), Vector2(STREET_SIZE.x, WALL_THICK)),
		Rect2(o, Vector2(WALL_THICK, STREET_SIZE.y)),
		Rect2(Vector2(o.x + STREET_SIZE.x - WALL_THICK, o.y), Vector2(WALL_THICK, STREET_SIZE.y)),
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
		poly.color = Color(0.3, 0.3, 0.32)
		poly.position = r.position
		add_child(poly)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = STREET_ORIGIN + Vector2(STREET_SIZE.x * 0.5, STREET_SIZE.y - 80)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_npcs() -> void:
	lou_marker = Node2D.new()
	lou_marker.position = STREET_ORIGIN + Vector2(120, 100)
	add_child(lou_marker)

	miko_marker = Node2D.new()
	miko_marker.position = STREET_ORIGIN + Vector2(STREET_SIZE.x - 120, 100)
	add_child(miko_marker)

	lou_zone = Area2D.new()
	var s1 := CollisionShape2D.new()
	var r1 := RectangleShape2D.new()
	r1.size = Vector2(140.0, 130.0)
	s1.shape = r1
	lou_zone.add_child(s1)
	lou_zone.position = lou_marker.position
	lou_zone.monitorable = true
	lou_zone.body_entered.connect(_on_lou_entered)
	add_child(lou_zone)

	miko_zone = Area2D.new()
	var s2 := CollisionShape2D.new()
	var r2 := RectangleShape2D.new()
	r2.size = Vector2(140.0, 130.0)
	s2.shape = r2
	miko_zone.add_child(s2)
	miko_zone.position = miko_marker.position
	miko_zone.monitorable = true
	miko_zone.body_entered.connect(_on_miko_entered)
	add_child(miko_zone)


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
			_phase = "free_roam"
			_controls_locked = false
		"talked":
			_phase = "done"
			next_btn.visible = true


func _on_lou_entered(body: Node) -> void:
	if body != player or _chosen or _phase != "free_roam":
		return
	_chosen = true
	GameState.informant_chosen = "lou"
	_phase = "talked"
	_controls_locked = true
	story.say(
		[
			"Lou nem levanta os olhos do balcão. \"Polícia de novo. Já contei tudo pro outro.\"",
			"\"O outro não tinha distintivo de detetive\", Mark responde — e Lou, surpreso, finalmente presta atenção.",
			"\"Uns caras estranhos andaram testando caixa eletrônico por aqui. Não pareciam desesperados. Pareciam... treinados.\"",
			"É pouco, mas é um padrão — e padrão é a primeira coisa que Mark aprendeu a procurar.",
			"Fim da Fase 2 — Ironside, de Novo.",
		],
		["Lou", "", "Lou", "", ""]
	)


func _on_miko_entered(body: Node) -> void:
	if body != player or _chosen or _phase != "free_roam":
		return
	_chosen = true
	GameState.informant_chosen = "miko"
	_phase = "talked"
	_controls_locked = true
	story.say(
		[
			"Miko não esconde o nervosismo quando vê o distintivo. \"Eu não fiz nada. Já não faço mais nada disso.\"",
			"\"Ninguém disse que fez\", Mark responde, devagar. \"Só preciso entender um padrão.\"",
			"Miko hesita, depois fala baixo: \"Tem gente boa em eletrônica testando falha de semáforo por aqui. Profissional. Isso não é vandalismo, é reconhecimento.\"",
			"Mark anota a palavra. Reconhecimento.",
			"Fim da Fase 2 — Ironside, de Novo.",
		],
		["Miko", "", "Miko", ""]
	)


func _process(_delta: float) -> void:
	if not _controls_locked:
		_move_player()
	_update_hud()
	queue_redraw()


func _move_player() -> void:
	player.velocity = InputBridge.move_vector * SPEED_CAUTIOUS
	player.move_and_slide()


func _update_hud() -> void:
	match _phase:
		"free_roam":
			status_label.text = tr("Objetivo: escolha quem pressionar — Lou ou Miko.")
		"done":
			status_label.text = tr("Fase 2 concluída.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
	if lou_marker:
		draw_circle(lou_marker.position, 15.0, Color(0.5, 0.3, 0.2))
		_draw_name_tag(lou_marker.position, "Lou")
	if miko_marker:
		draw_circle(miko_marker.position, 15.0, Color(0.3, 0.4, 0.5))
		_draw_name_tag(miko_marker.position, "Miko")


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
