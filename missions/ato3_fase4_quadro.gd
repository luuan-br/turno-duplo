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
var _phase := "intro"
## intro -> board -> reveal -> done


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
			board.setup(pairs)
		"reveal":
			_phase = "done"


func _on_board_completed() -> void:
	_phase = "reveal"
	GameState.ghost_named = true
	story.say(
		[
			"Linha por linha, o quadro para de ser uma bagunça e vira um mapa: monitoramento, teste de acesso, logística, fuga.",
			"É a mesma operação se repetindo, testando a própria cidade como quem testa uma fechadura.",
			"E tem uma placa que aparece rápido demais pra ser coincidência — Mark já tinha visto aquele carro escapar impossível demais. Agora tem um rosto pra história: a cidade está chamando o motorista de 'Ghost'.",
			"Fim da Fase 4 — O Quadro de Evidências.",
		],
		["", "", "", ""]
	)

