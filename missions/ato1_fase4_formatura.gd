extends Node2D
## Ato 1, Fase 4 — "Avaliação Final / Formatura" (docs/ROTEIRO.md).
## Fecha o Ato 1 (Academia) e prepara o gancho pro Ato 2.
##
## Decisão de escopo: o ROTEIRO descreve "prova combinando tiro,
## abordagem e direção" — mas essas três mecânicas já foram testadas
## de verdade, com peso narrativo próprio, nas Fases 1/2/3. Sem sistema
## de save entre cenas, não dá pra referenciar o desempenho específico
## do jogador nelas de qualquer forma; repetir os mesmos mini-jogos aqui
## seria exatamente o "conteúdo genérico" que a regra de ouro do GDD
## (Seção 9) pede pra evitar. Por isso essa fase é majoritariamente
## narrativa: a prova é resumida, não repetida — o peso real está na
## cerimônia, que é onde o Mark recebe a lotação pra Ironside sob o
## Sgt. Ray Doyle (GDD Seção 10), fechando o Ato 1 de verdade.
##
## Só tem movimento (sem mira/tiro/direção) + `ui/story_box.gd`. Sem
## novos sistemas — só o padrão de câmera + NPC parado até o jogador
## chegar perto, já estabelecido nas Fases 1/2/3.

const YARD_SIZE := Vector2(500.0, 400.0)
const YARD_ORIGIN := Vector2(80.0, 60.0)
const WALL_THICK := 20.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0

var player: CharacterBody2D
var okafor_marker: Node2D
var theo_marker: Node2D

var ceremony_zone: Area2D
var _ceremony_started := false

var story: Control
var status_label: Label
var _controls_locked := true
var _phase := "intro"
## intro -> walk_to_ceremony -> ceremony -> done


func _ready() -> void:
	_build_yard()
	_build_player()
	_build_npcs()
	_build_ceremony_zone()
	_build_hud()
	_build_controls()
	_build_story_box()

	story.say(
		[
			"Última semana de instrução. Mira, abordagem, direção — cada prova arrancou um pedaço do recruta ansioso que desceu do ônibus há um mês.",
			"Hoje é dia de formatura.",
		],
		["", ""]
	)


# ---------- construção da cena (caixa cinza) ----------

func _build_yard() -> void:
	var y := YARD_ORIGIN
	var rects: Array[Rect2] = [
		Rect2(y, Vector2(YARD_SIZE.x, WALL_THICK)),
		Rect2(Vector2(y.x, y.y + YARD_SIZE.y - WALL_THICK), Vector2(YARD_SIZE.x, WALL_THICK)),
		Rect2(y, Vector2(WALL_THICK, YARD_SIZE.y)),
		Rect2(Vector2(y.x + YARD_SIZE.x - WALL_THICK, y.y), Vector2(WALL_THICK, YARD_SIZE.y)),
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
		poly.color = Color(0.35, 0.35, 0.4)
		poly.position = r.position
		add_child(poly)

	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([Vector2.ZERO, Vector2(YARD_SIZE.x - WALL_THICK * 2, 0), Vector2(YARD_SIZE.x - WALL_THICK * 2, YARD_SIZE.y - WALL_THICK * 2), Vector2(0, YARD_SIZE.y - WALL_THICK * 2)])
	floor_poly.color = Color(0.22, 0.22, 0.2)
	floor_poly.position = y + Vector2(WALL_THICK, WALL_THICK)
	floor_poly.z_index = -1
	add_child(floor_poly)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player.position = YARD_ORIGIN + Vector2(60, YARD_SIZE.y - 80)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)


func _build_npcs() -> void:
	okafor_marker = Node2D.new()
	okafor_marker.position = YARD_ORIGIN + Vector2(280, 100)
	add_child(okafor_marker)

	theo_marker = Node2D.new()
	theo_marker.position = YARD_ORIGIN + Vector2(340, 100)
	add_child(theo_marker)


func _build_ceremony_zone() -> void:
	ceremony_zone = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(170.0, 150.0)
	shape.shape = rect
	ceremony_zone.add_child(shape)
	ceremony_zone.position = YARD_ORIGIN + Vector2(310, 130)
	ceremony_zone.monitorable = true
	ceremony_zone.body_entered.connect(_on_ceremony_zone_entered)
	add_child(ceremony_zone)


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


# ---------- fluxo da fase ----------

func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "walk_to_ceremony"
			_controls_locked = false
		"ceremony":
			_phase = "done"


func _on_ceremony_zone_entered(body: Node) -> void:
	if body != player or _ceremony_started or _phase != "walk_to_ceremony":
		return
	_ceremony_started = true
	_phase = "ceremony"
	_controls_locked = true
	story.say(
		[
			"Três provas, Reyes: pontaria, decisão, controle. Você levou as três a sério — até demais, às vezes.",
			"\"Até demais\" é elogio vindo dela. Aproveita enquanto dura.",
			"Marsh, você tem talento de sobra e paciência de menos. Reyes tem o oposto. A rua vai exigir os dois de vocês — e nenhum dos dois tem os dois sozinho.",
			"Lotações: Marsh, distrito Norte. Reyes — Ironside, sob o Sargento Ray Doyle. Bom sujeito, cansado. Vai te ensinar mais do que qualquer manual.",
			"Ironside. Aquilo ali come novato no café da manhã. Boa sorte, Reyes.",
			"O pai de Mark também começou num bairro difícil. Talvez fosse por isso que nunca falava sobre o primeiro ano.",
			"Fim da Fase 4 — Avaliação Final / Formatura. Fim do Ato 1 — Academia.",
			"Ato 2 (Novato nas Ruas) ainda não foi construído.",
		],
		["Capitã Okafor", "Theo Marsh", "Capitã Okafor", "Capitã Okafor", "Theo Marsh", "", "", ""]
	)


# ---------- lógica de jogo ----------

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
		"walk_to_ceremony":
			status_label.text = tr("Objetivo: vá até a formatura.")
		"done":
			status_label.text = tr("Fase 4 concluída — fim do Ato 1.")
		_:
			status_label.text = ""


func _draw() -> void:
	if player:
		draw_circle(player.position, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))

	if okafor_marker:
		draw_circle(okafor_marker.position, 15.0, Color(0.6, 0.2, 0.2))
		_draw_name_tag(okafor_marker.position, "Okafor")
	if theo_marker:
		draw_circle(theo_marker.position, 15.0, Color(0.2, 0.4, 0.6))
		_draw_name_tag(theo_marker.position, "Theo")


func _draw_name_tag(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, -24), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
