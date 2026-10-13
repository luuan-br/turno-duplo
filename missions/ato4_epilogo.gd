extends Node2D
## Epílogo (docs/ROTEIRO.md, fechamento do Ato 4). Puramente narrativo —
## sem mecânica nova, de propósito: depois de 24 missões de ação, o
## fechamento da campanha é sobre pagar os medidores acumulados, não
## sobre mais um desafio. Contraste direto com o recruta ingênuo da
## Fase 1 do Ato 1. O tom da cena final com Sarah/Emma varia com
## `GameState.family_meter`; o destino do Doyle ecoa a escolha da Fase 6
## do Ato 3 (`GameState.doyle_fate`) — "capital narrativo" pagando de
## volta (GDD Seção 11), não dano extra nem vida extra.

var story: Control
var status_label: Label
var _phase := "running"


func _ready() -> void:
	_build_hud()
	_build_story_box()

	var lines: Array[String] = []
	var speakers: Array[String] = []

	lines.append("Bellmont acorda devagar, do jeito que sempre acorda depois de uma noite ruim — como se nada tivesse acontecido, quando quase tudo aconteceu.")
	speakers.append("")

	lines.append("Adrian Kessler está sob custódia. A operação que ele levou anos construindo agora é uma pilha de caixas de evidência numa sala da Corregedoria.")
	speakers.append("")

	_append_doyle_lines(lines, speakers)
	_append_family_lines(lines, speakers)

	lines.append("Mark lembra do recruta atrasado que mal sabia segurar a própria arma direito, lá na Fase 1 da Academia. Não virou um super-herói. Virou alguém que finalmente confia no próprio julgamento.")
	speakers.append("")
	lines.append("Fim de Turno Duplo — Ato 4. Fim da campanha. (Gancho em aberto pra uma possível continuação.)")
	speakers.append("")

	story.say(lines, speakers)


func _append_doyle_lines(lines: Array[String], speakers: Array[String]) -> void:
	match GameState.doyle_fate:
		"entregue":
			lines.append("O processo contra o Doyle segue na Corregedoria. Mark não se arrepende de ter entregado a ligação — só queria que doesse menos.")
			speakers.append("")
		"saida":
			lines.append("Ninguém mais viu o Doyle desde aquela conversa no apartamento. Em algum lugar, um ex-parceiro está vivo por causa de uma lealdade que a lei não reconheceria.")
			speakers.append("")
		"confronto":
			lines.append("O Doyle aceitou depor contra os homens de Kessler em troca de uma pena menor. Não é perdão. É o mais perto disso que os dois vão chegar.")
			speakers.append("")
		_:
			lines.append("O nome do Doyle ainda aparece nos relatórios do caso, de um jeito que Mark prefere não reler sozinho.")
			speakers.append("")
	# Paga o interrogatório da Fase 6 do Ato 3.
	if GameState.doyle_confessed:
		lines.append("Pelo menos Mark sabe o porquê: uma dívida com gente que não cobra com carta. Não absolve — mas explica.")
	else:
		lines.append("Mark nunca soube direito por que ele fez aquilo. Essa é a parte que mais pesa.")
	speakers.append("")


func _append_family_lines(lines: Array[String], speakers: Array[String]) -> void:
	if GameState.family_meter > 0:
		lines.append("Em casa, Sarah não solta a mão de Mark desde que ele voltou. Emma já está contando a história pra quem quiser ouvir — exagerada, claro, mas feliz.")
		speakers.append("")
		lines.append("O jantar que quase sempre esfriava sozinho, hoje, tem os três sentados à mesa ao mesmo tempo. Não resolve tudo. Mas é um começo de verdade.")
		speakers.append("")
	else:
		lines.append("Em casa, Sarah abraça Mark forte, mas o silêncio depois ainda pesa — meses de ausência não se desfazem numa noite, por mais que a noite tenha sido decisiva.")
		speakers.append("")
		lines.append("Emma pendura o scanner de rádio na cabeceira da cama, perto o bastante pra continuar ouvindo o pai, mesmo quando ele não está em casa.")
		speakers.append("")


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


func _build_story_box() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	story = Control.new()
	story.set_script(load("res://ui/story_box.gd"))
	layer.add_child(story)
	story.finished.connect(_on_story_finished)


func _on_story_finished() -> void:
	_phase = "done"


func _process(_delta: float) -> void:
	status_label.text = tr("Campanha concluída. Obrigado por jogar.") if _phase == "done" else ""
