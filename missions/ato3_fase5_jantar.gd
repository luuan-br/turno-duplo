extends Node2D
## Ato 3, Fase 5 — "Jantar Perdido" (docs/ROTEIRO.md). Vinheta doméstica
## entre Sarah e Emma — a mesma função do Turno 5 do Ato 2 (fase sem
## mecânica nova, majoritariamente narrativa), agora com peso direto no
## `GameState.family_meter`: ficar pro jantar ou voltar pro caso. Nenhuma
## opção é "certa" — é o mesmo tipo de escolha sem-vilão-nem-mocinho que
## "O Aviso" e o touchpoint do Theo já validaram como o que rende de
## verdade (aprofunda personagem central, não preenche espaço).

var choice: Control
var story: Control
var next_btn: Button
var _phase := "intro"
## intro -> choice -> outcome -> done

const SCENE_PATH := "res://missions/ato3_fase5_jantar.tscn"


func _ready() -> void:
	_build_hud()
	_build_story_box()
	_build_choice()

	story.say(
		[
			"A mesa está posta há quarenta minutos. Emma já perguntou duas vezes se o pai vem.",
			"Sarah não cobra nada — só olha pro celular de Mark toda vez que ele vibra com mais uma atualização do caso.",
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
				"O celular vibra de novo — mais uma peça do caso. Mark fica ou volta pro trabalho?",
				["Ficar pro jantar", "Voltar pro caso"]
			)
		"outcome":
			_phase = "done"
			next_btn.visible = true


func _on_choice_made(index: int) -> void:
	_phase = "outcome"
	if index == 0:
		GameState.add_family_meter(1)
		story.say(
			[
				"Mark guarda o celular na gaveta, sem olhar a tela de novo. Emma conta uma história longa demais sobre a aula de hoje, e ele escuta cada palavra.",
				"Sarah não diz nada sobre isso — só sorri um pouco diferente do que sorria há uma hora.",
				"O caso vai estar lá amanhã. Hoje não é sobre o caso.",
				"Fim da Fase 5 — Jantar Perdido.",
			],
			["", "", "", ""]
		)
	else:
		GameState.add_family_meter(-1)
		story.say(
			[
				"\"Só mais essa\", Mark diz, já de pé. Emma não discute — só para de contar a história no meio.",
				"Sarah leva o prato dele pra geladeira sem comentário. É o silêncio dela que pesa mais que qualquer bronca seria.",
				"Mark sabe que vai lembrar dessa mesa mais tarde do que vai lembrar do que encontrou hoje.",
				"Fim da Fase 5 — Jantar Perdido.",
			],
			["", "", "", ""]
		)
