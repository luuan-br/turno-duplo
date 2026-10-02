extends Node2D
## Ato 3, Fase 6 — "A Ligação Impossível" (docs/ROTEIRO.md). Fecha o
## Movimento 2: cruzando o registro de chamadas do caso com o horário do
## Incidente (Ato 2, Turno 6), Mark acha uma ligação que não devia
## existir — o número do Doyle, minutos antes da emboscada. A escolha de
## 3 vias (`GameState.doyle_fate`) não tem ramificação de missão (decisão
## já fechada na Seção 9 do GDD): o peso aparece no Ato 4, não numa
## estrutura de missão diferente aqui.

var choice: Control
var story: Control
var next_btn: Button
var _phase := "intro"
## intro -> choice -> outcome -> done

const SCENE_PATH := "res://missions/ato3_fase6_ligacao.tscn"


func _ready() -> void:
	_build_hud()
	_build_story_box()
	_build_choice()

	story.say(
		[
			"Mark cruza o registro de chamadas da operação com o horário exato do Incidente. É rotina — ninguém pediu isso, mas ele pediu a si mesmo.",
			"Uma ligação não bate. Não devia nem existir: o número do Doyle, onze minutos antes de tudo dar errado naquele apartamento.",
			"Pode ser nada. Pode ser o pior tipo de alguma coisa.",
		],
		["", "", ""]
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


func _build_choice() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	choice = Control.new()
	choice.set_script(load("res://ui/choice_prompt.gd"))
	layer.add_child(choice)
	choice.chosen.connect(_on_choice_made)


func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "choice"
			choice.ask(
				"O FTO de Mark. O homem que ensinou tudo que ele sabe de rua. O que fazer com a ligação?",
				["Levar à Corregedoria", "Dar a chance de ele sumir sozinho", "Confrontar o Doyle cara a cara"]
			)
		"outcome":
			_phase = "done"
			next_btn.visible = true


func _on_choice_made(index: int) -> void:
	_phase = "outcome"
	match index:
		0:
			GameState.doyle_fate = "entregue"
			GameState.add_doyle_relationship(-2)
			story.say(
				[
					"Mark leva a ligação pra Corregedoria sem avisar ninguém. É o procedimento certo. Não parece certo.",
					"Quando Doyle souber — e vai saber — vai saber também quem entregou.",
					"Fim da Fase 6 — A Ligação Impossível.",
				],
				["", "", ""]
			)
		1:
			GameState.doyle_fate = "saida"
			GameState.add_doyle_relationship(0)
			story.say(
				[
					"Mark não entrega nada. Em vez disso, manda uma mensagem só pro Doyle: \"Sei da ligação. Suma antes que outra pessoa ache.\"",
					"Não é justiça. É a última lealdade que sobrou de um parceiro que já tomou um tiro ao lado dele.",
					"Fim da Fase 6 — A Ligação Impossível.",
				],
				["", "", ""]
			)
		_:
			GameState.doyle_fate = "confronto"
			GameState.add_doyle_relationship(-1)
			story.say(
				[
					"Mark liga pro Doyle e pergunta direto, sem rodeio: \"Por que seu número tá na lista?\"",
					"O silêncio do outro lado dura segundos demais pra ser inocente. \"Você não entende o que tá mexendo\", Doyle finalmente diz — e desliga.",
					"Não é confissão. Mas também não é um \"não\".",
					"Fim da Fase 6 — A Ligação Impossível.",
				],
				["", "Sgt. Doyle", "", ""]
			)
