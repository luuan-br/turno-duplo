extends Node2D
## Ato 3, Fase 2 — "Ironside, de Novo" (docs/ROTEIRO.md). Mark volta ao
## bairro que patrulhava, agora como investigador. Escolha de quem
## pressionar — **Lou** (contatos de rua) ou **Miko** (ex-técnico ligado
## ao Kessler, ainda sem esse nome aparecer pro jogador) — rotas
## diferentes pra mesma pista. A escolha é por onde o jogador anda
## primeiro (zona de proximidade), não um prompt — combina melhor com o
## tom investigativo de "seguir uma pista" do que um menu de diálogo.
##
## Depois vem o interrogatório (`ui/interrogation.gd`, GDD Seção 8): falas
## e deixas próprias de cada um. O que ele revela vai pra
## `GameState.leads` e vale depois — "rotina_vigia" ajuda na Vigilância
## (Fase 3), "pista_extra" dá um par a mais no Quadro (Fase 4). Se ele se
## fechar, `GameState.informant_warned` deixa o vigia da Fase 3 mais
## atento. Sem fail state: a fase sempre termina.

const EVIDENCE := [
	{"id": "roteador", "label": "Roteador do apartamento do Incidente"},
	{"id": "fotos", "label": "Fotos da cena do Incidente"},
	{"id": "multa", "label": "Multa de estacionamento antiga"},
]

const LOU_DATA := {
	"suspect": "Lou",
	"patience": 2,
	"shut_line": "Lou joga o pano no balcão. \"Acabou a conversa. Quer mais, volta com mandado.\"",
	"rounds": [
		{
			"line": "Polícia de novo? Já contei tudo pro outro.",
			"tell": "sorri, oferece uma dose por conta da casa, resposta na ponta da língua.",
			"answer": "evidence",
			"evidence_id": "fotos",
			"success": "Lou olha a foto do homem armado e o sorriso some. \"Esse aí... alugou o quartinho dos fundos uns meses atrás.\"",
			"fail": "\"Bonito, detetive. Mas não me diz nada.\" Ele continua sorrindo.",
			"reveal": "quartinho",
		},
		{
			"line": "Olha, eu não me meto com gente pesada. Tenho alvará pra perder.",
			"tell": "passa o pano num balcão que já tá limpo e fala sem parar.",
			"answer": "press",
			"success": "\"Tá bom! Eles saem toda noite às dez. Um fica de vigia sozinho no depósito, e ele sempre para pra fumar virado pro muro.\"",
			"fail": "Lou se recompõe. \"Viu? Nada pra contar.\"",
			"reveal": "rotina_vigia",
		},
		{
			"line": "Se eles souberem que eu falei, quem paga é o meu sobrinho.",
			"tell": "baixa a voz e fica olhando pra porta da rua.",
			"answer": "support",
			"success": "\"...Eles testavam caixa eletrônico aqui no bairro. Não pra roubar. Pra cronometrar quanto a polícia demorava.\"",
			"fail": "Ele se encolhe atrás do balcão. \"Não sei de nada. Vai embora.\"",
			"reveal": "pista_extra",
		},
		{
			"line": "É tudo que eu sei, detetive. Juro.",
			"tell": "encosta no balcão, relaxado, e serve uma dose pra si mesmo.",
			"answer": "evidence",
			"evidence_id": "roteador",
			"success": "Ele engole seco. \"Instalaram um desses no quartinho. Disseram que era internet.\"",
			"fail": "\"Isso aí? Nunca vi.\" Ele bebe a dose devagar.",
			"reveal": "roteador_bar",
		},
	],
}

const MIKO_DATA := {
	"suspect": "Miko",
	"patience": 2,
	"shut_line": "Miko vira a placa da porta pra FECHADO. \"Não tenho mais nada pra dizer.\"",
	"rounds": [
		{
			"line": "Eu não fiz nada. Já não faço mais nada disso.",
			"tell": "encolhe atrás do balcão da loja, olhando pro fundo.",
			"answer": "support",
			"success": "\"...Eles me procuraram. Queriam alguém que entendesse de semáforo. Eu disse não.\"",
			"fail": "Ele se encolhe mais. \"Não sei de nada. Nada.\"",
			"reveal": "semaforo",
		},
		{
			"line": "Eu conserto celular, só isso. Pode olhar a loja inteira.",
			"tell": "sorri, abre os braços, resposta pronta demais.",
			"answer": "evidence",
			"evidence_id": "roteador",
			"success": "O sorriso cai. \"...Fui eu que configurei esse, antes de sair. Ele escuta o rádio da polícia de longe.\"",
			"fail": "\"Isso não prova nada.\" Ele continua sorrindo.",
			"reveal": "pista_extra",
		},
		{
			"line": "Não sei quem manda. Nunca vi o rosto.",
			"tell": "mexe no ferro de solda sem parar e a voz acelera.",
			"answer": "press",
			"success": "\"Um homem de terno! Nunca falava nome. Pagava adiantado e planejava tudo por horário.\"",
			"fail": "Ele respira fundo e larga o ferro. \"Já disse que não sei.\"",
			"reveal": "terno",
		},
		{
			"line": "Se eles souberem que eu falei com polícia, eu sumo.",
			"tell": "a mão treme e ele baixa as persianas da vitrine.",
			"answer": "support",
			"success": "\"O vigia do depósito... ele para pra fumar virado pro muro. Todo mundo sabe.\"",
			"fail": "Ele trava de medo e fica em silêncio.",
			"reveal": "rotina_vigia",
		},
	],
}

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
var interrogation: Control
var status_label: Label
var next_btn: Button
var _controls_locked := true
var _phase := "intro"
## intro -> free_roam -> opening -> interrogation -> talked -> done

const SCENE_PATH := "res://missions/ato3_fase2_ironside.tscn"


func _ready() -> void:
	_build_street()
	_build_player()
	_build_npcs()
	_build_hud()
	_build_controls()
	_build_story_box()
	_build_interrogation()

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


## Interrogatório fica por cima de tudo (inclusive do "< Menu" do HUD,
## que senão roubaria o toque do "Continuar").
func _build_interrogation() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	interrogation = Control.new()
	interrogation.set_script(load("res://ui/interrogation.gd"))
	layer.add_child(interrogation)
	interrogation.finished.connect(_on_interrogation_finished)


func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "free_roam"
			_controls_locked = false
		"opening":
			_phase = "interrogation"
			var data: Dictionary = (LOU_DATA if GameState.informant_chosen == "lou" else MIKO_DATA).duplicate(true)
			data["evidence"] = EVIDENCE
			interrogation.setup(data)
		"talked":
			_phase = "done"
			next_btn.visible = true


func _on_lou_entered(body: Node) -> void:
	if body != player or _chosen or _phase != "free_roam":
		return
	_start_with("lou", [
		"O bar do Lou ainda cheira a cerveja da noite anterior. Ele nem levanta os olhos do balcão.",
		"Mark repara nas mãos dele, no jeito de responder, no que ele olha. Detetive não ouve só a resposta — lê quem responde.",
	])


func _on_miko_entered(body: Node) -> void:
	if body != player or _chosen or _phase != "free_roam":
		return
	_start_with("miko", [
		"A loja do Miko é um corredor de celular desmontado. Ele empalidece quando vê o distintivo.",
		"Mark repara nas mãos dele, no jeito de responder, no que ele olha. Detetive não ouve só a resposta — lê quem responde.",
	])


## Primeiro interrogatório do jogo: a regra da deixa é ensinada aqui, como
## lição da Okafor que o Mark lembra (não como tutorial solto).
func _start_with(informant: String, lines: Array) -> void:
	_chosen = true
	GameState.informant_chosen = informant
	_phase = "opening"
	_controls_locked = true
	var all := lines.duplicate()
	all.append("A Okafor repetia na Academia: \"Nervoso — mexe as mãos, fala rápido — tá mentindo sob pressão: aperta. Assustado — encolhe, olha pra porta — tá com medo, não mentindo: dá apoio. Calmo demais — sorriso, resposta pronta — mentira ensaiada: só prova quebra.\"")
	story.say(all, ["", "", ""])


func _on_interrogation_finished(result: Dictionary) -> void:
	var who := "Lou" if GameState.informant_chosen == "lou" else "Miko"
	GameState.leads = result["revealed"].duplicate()
	GameState.informant_warned = result["shut_down"]
	_phase = "talked"

	var lines: Array = []
	if result["shut_down"]:
		lines.append(tr("%s fechou a boca — e Mark tem certeza de que, antes da noite acabar, alguém vai saber que a polícia andou perguntando.") % who)
	elif result["correct"] == result["total"]:
		lines.append(tr("%s contou mais do que queria. Mark sai com o caderno cheio.") % who)
	else:
		lines.append(tr("%s deu algumas coisas e guardou outras. Mas não se fechou.") % who)
	if "rotina_vigia" in GameState.leads:
		lines.append("Uma informação vale ouro: o vigia do depósito para pra fumar virado pro muro. Uma janela.")
	if "pista_extra" in GameState.leads:
		lines.append("E outra que muda o desenho do caso — vai direto pro quadro.")
	if result["revealed"].is_empty():
		lines.append("Mark sai quase de mãos vazias. Quase: agora ele sabe que o bairro inteiro tem medo de alguém.")
	lines.append("Fim da Fase 2 — Ironside, de Novo.")
	var speakers: Array = []
	for _l in lines:
		speakers.append("")
	story.say(lines, speakers)


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
			status_label.text = tr("Objetivo: escolha quem interrogar — Lou ou Miko. Leia a deixa antes de responder.")
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
