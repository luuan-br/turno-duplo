extends Node2D
## Ato 3, Fase 4 — "O Quadro de Evidências" (docs/ROTEIRO.md). Primeiro
## uso real do `ui/evidence_board.gd`: Mark junta o que já tem — a cena
## revisitada (Fase 1), o informante (Fase 2) e a vigilância (Fase 3) — e
## conecta os pontos. Os pares mudam um pouco conforme qual informante o
## jogador escolheu (`GameState.informant_chosen`), prêmio por ter
## explorado a fase anterior do jeito que explorou, sem travar ninguém
## que pulou a escolha. Fecha o Movimento 2 do Ato 3 nomeando o Ghost.

var board: Control
var story: Control
var next_btn: Button
var _phase := "intro"
## intro -> board -> reveal -> done

const SCENE_PATH := "res://missions/ato3_fase4_quadro.tscn"


func _ready() -> void:
	_build_hud()
	_build_story_box()
	_build_board()

	story.say(
		[
			"De volta à delegacia, Mark espalha tudo que tem na mesa: o roteador, a palavra do informante, as placas trocadas no beco.",
			"Sozinho, cada pedaço é nada. Juntos, talvez signifiquem alguma coisa.",
		],
		["", ""]
	)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
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


func _build_story_box() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	story = Control.new()
	story.set_script(load("res://ui/story_box.gd"))
	layer.add_child(story)
	story.finished.connect(_on_story_finished)


func _build_board() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	board = Control.new()
	board.set_script(load("res://ui/evidence_board.gd"))
	layer.add_child(board)
	board.completed.connect(_on_board_completed)


func _informant_pair() -> Array:
	if GameState.informant_chosen == "miko":
		return ["Falha de semáforo testada", "Reconhecimento técnico, não vandalismo"]
	return ["Caixa eletrônico testado", "Grupo treinado, não desesperado"]


## Par a mais que só existe se o interrogatório da Fase 2 arrancou a
## "pista_extra" — e é a peça que mostra que eles estudam a própria
## polícia (GDD Seção 5: teste de tempo de resposta).
func _extra_pair() -> Array:
	if not ("pista_extra" in GameState.leads):
		return []
	if GameState.informant_chosen == "miko":
		return ["Roteador escuta o rádio da polícia", "Eles sabem a rota das viaturas"]
	return ["Caixas testados sem roubar nada", "Cronometravam a resposta da polícia"]


func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "board"
			var pairs: Array = [
				["Roteador profissional no apê do Incidente", "Alguém monitorava o quarteirão"],
				_informant_pair(),
				["Placas trocadas na troca do beco", "Logística organizada, não crime de ocasião"],
				["Carro visto fugindo no Turno 4", "Mesmo wheelman em todos os casos"],
			]
			var extra := _extra_pair()
			if not extra.is_empty():
				pairs.append(extra)
			board.setup(pairs)
		"reveal":
			_phase = "done"
			next_btn.visible = true


func _on_board_completed() -> void:
	_phase = "reveal"
	GameState.ghost_named = true
	var lines: Array = [
		"Linha por linha, o quadro para de ser uma bagunça e vira um mapa: monitoramento, teste de acesso, logística, fuga.",
		"É a mesma operação se repetindo, testando a própria cidade como quem testa uma fechadura.",
	]
	if not _extra_pair().is_empty():
		lines.append("E a peça que o informante entregou fecha o pior: eles não estão só testando a cidade. Estão estudando a polícia — o tempo que ela leva, o caminho que ela faz.")
	lines.append("E tem uma placa que aparece rápido demais pra ser coincidência — Mark já tinha visto aquele carro escapar impossível demais. Agora tem um rosto pra história: a cidade está chamando o motorista de 'Ghost'.")
	lines.append("Fim da Fase 4 — O Quadro de Evidências.")
	var speakers: Array = []
	for _l in lines:
		speakers.append("")
	story.say(lines, speakers)

