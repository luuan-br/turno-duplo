extends Node2D
## Ato 3, Fase 6 — "A Ligação Impossível" (docs/ROTEIRO.md). Fecha o
## Movimento 2: cruzando o registro de chamadas do caso com o horário do
## Incidente (Ato 2, Turno 6), Mark acha uma ligação que não devia
## existir — o número do Doyle, minutos antes da emboscada.
##
## Antes da escolha, o Mark vai ver o Doyle (de licença) e o confronto é
## um interrogatório (`ui/interrogation.gd`, GDD Seção 8). A paciência do
## Doyle vem da relação construída no Ato 2 (`doyle_relationship`). Ler
## certo faz ele admitir a dívida que o encurralou (`GameState.
## doyle_confessed`), o que muda o tom da escolha e uma fala do Epílogo.
## A escolha de 3 vias (`GameState.doyle_fate`) não ramifica a missão — o
## peso aparece no Ato 4 e no Epílogo.

const EVIDENCE := [
	{"id": "registro", "label": "Registro de chamadas com o número dele"},
	{"id": "fotos", "label": "Fotos da cena do Incidente"},
	{"id": "roteador", "label": "Roteador do apartamento"},
]

const DOYLE_DATA := {
	"suspect": "Sgt. Ray Doyle",
	"shut_line": "Doyle levanta e abre a porta. \"Vai embora, Reyes. Antes que um de nós diga o que não tem volta.\"",
	"rounds": [
		{
			"line": "Reyes. Não esperava visita.",
			"tell": "olha pela janela antes de abrir a porta toda, voz baixa.",
			"answer": "support",
			"success": "\"Desculpa. Ando... vendo gente na rua que não devia estar ali.\"",
			"fail": "Ele se encolhe na porta. \"Tô cansado, garoto. Fala logo o que quer.\"",
			"reveal": "medo",
		},
		{
			"line": "Aquele chamado? Foi azar. Acontece no ofício.",
			"tell": "recosta no sofá, tranquilo, como quem já ensaiou a frase.",
			"answer": "evidence",
			"evidence_id": "registro",
			"success": "O sorriso some quando ele vê o próprio número no papel. Fica um bom tempo em silêncio.",
			"fail": "\"Isso aí não quer dizer nada, Reyes.\" Ele nem olha direito.",
			"reveal": "ligacao",
		},
		{
			"line": "Eu liguei pra... um amigo. Coisa pessoal.",
			"tell": "esfrega a nuca e fala por cima da própria frase.",
			"answer": "press",
			"success": "\"Tá! Eu devia dinheiro. Muito. Pra gente que não cobra com carta.\"",
			"fail": "Ele respira fundo e se recompõe. \"Já disse. Pessoal.\"",
			"reveal": "divida",
		},
		{
			"line": "Você não sabe o que eles fazem com quem fala.",
			"tell": "a voz falha, e ele aperta o ombro que levou o tiro.",
			"answer": "support",
			"success": "\"Me deram um horário pra ligar. Eu liguei. Não sabia que era pra você entrar naquela porta, Mark. Juro que não sabia.\"",
			"fail": "Ele trava, olhando pro chão, e não fala mais nada.",
			"reveal": "confissao",
		},
	],
}

var choice: Control
var story: Control
var interrogation: Control
var next_btn: Button
var _phase := "intro"
## intro -> interrogation -> aftermath -> choice -> outcome -> done

const SCENE_PATH := "res://missions/ato3_fase6_ligacao.tscn"


func _ready() -> void:
	_build_hud()
	_build_story_box()
	_build_choice()
	_build_interrogation()

	story.say(
		[
			"Mark cruza o registro de chamadas da operação com o horário exato do Incidente. É rotina — ninguém pediu isso, mas ele pediu a si mesmo.",
			"Uma ligação não bate. Não devia nem existir: o número do Doyle, onze minutos antes de tudo dar errado naquele apartamento.",
			"Antes de decidir qualquer coisa, Mark vai até o apartamento do Doyle. Ele está de licença, ainda com o ombro enfaixado.",
			"O homem que ensinou a ele a ler gente na rua. Agora é a vez do Mark ler ele.",
		],
		["", "", "", ""]
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


## Por cima de tudo (inclusive do "< Menu", que roubaria o toque do
## "Continuar" do interrogatório).
func _build_interrogation() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	interrogation = Control.new()
	interrogation.set_script(load("res://ui/interrogation.gd"))
	layer.add_child(interrogation)
	interrogation.finished.connect(_on_interrogation_finished)


## Quanto mais o jogador investiu no Doyle no Ato 2, mais chance ele dá
## antes de se fechar (1 a 3 erros).
func _doyle_patience() -> int:
	return clampi(1 + GameState.doyle_relationship, 1, 3)


func _on_story_finished() -> void:
	match _phase:
		"intro":
			_phase = "interrogation"
			var data: Dictionary = DOYLE_DATA.duplicate(true)
			data["patience"] = _doyle_patience()
			data["evidence"] = EVIDENCE
			interrogation.setup(data)
		"aftermath":
			_phase = "choice"
			var prompt := "Doyle admitiu tudo — a dívida, a ligação. O FTO que te ensinou a rua. O que fazer?" if GameState.doyle_confessed else "Doyle não admitiu nada, mas o número dele está no papel. O FTO que te ensinou a rua. O que fazer?"
			choice.ask(prompt, ["Levar à Corregedoria", "Dar a chance de ele sumir sozinho", "Exigir que ele mesmo se entregue"])
		"outcome":
			_phase = "done"
			next_btn.visible = true


func _on_interrogation_finished(result: Dictionary) -> void:
	GameState.doyle_confessed = "divida" in result["revealed"]
	_phase = "aftermath"
	var lines: Array = []
	if GameState.doyle_confessed:
		lines.append("Doyle afunda no sofá. Pela primeira vez desde a Academia, Mark vê o FTO dele com medo de verdade.")
		lines.append("Não por maldade. Por estar encurralado. Isso não apaga o tiro — mas explica.")
	elif result["shut_down"]:
		lines.append("A porta se fecha na cara do Mark. O que quer que o Doyle saiba, vai ficar com ele por enquanto.")
	else:
		lines.append("Doyle diz o bastante pra confirmar que a ligação existiu. O porquê, ele guarda pra si.")
	story.say(lines, ["", ""])


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
			story.say(
				[
					"Mark não entrega nada. Na saída, só diz: \"Sei da ligação. Some antes que outra pessoa ache.\"",
					"Não é justiça. É a última lealdade que sobrou de um parceiro que já tomou um tiro ao lado dele.",
					"Fim da Fase 6 — A Ligação Impossível.",
				],
				["", "", ""]
			)
		_:
			GameState.doyle_fate = "confronto"
			GameState.add_doyle_relationship(-1)
			var reaction := "Doyle olha pro chão por um bom tempo. \"Amanhã cedo. Eu mesmo vou.\"" if GameState.doyle_confessed else "\"Você não entende o que tá mexendo\", ele diz — mas não nega. No dia seguinte, aparece na Corregedoria."
			story.say(
				[
					"Mark põe o registro na mesa. \"Você mesmo vai contar pra Corregedoria. Ou conto eu.\"",
					reaction,
					"Fim da Fase 6 — A Ligação Impossível.",
				],
				["", "Sgt. Doyle" if GameState.doyle_confessed else "", ""]
			)
