extends Control
## Sandbox do interrogatório (`ui/interrogation.gd`) — piloto do Modo
## Diálogo com leitura de deixas, antes de aplicar no Ato 3 (GDD Seção 8).
## Suspeito de teste com as três deixas (nervoso, assustado, calmo demais)
## e uma prova falsa no meio das verdadeiras.

const LEGEND := "COMO LER A DEIXA\n\nNERVOSO (mexe nas mãos, fala rápido, sua) → está mentindo sob pressão → PRESSIONAR.\nASSUSTADO (encolhe, olha pra porta, voz baixa) → está com medo, não mentindo → APOIAR.\nCALMO DEMAIS (sorri, resposta pronta) → mentira ensaiada → só a PROVA certa quebra.\n\nErrar gasta paciência. Sem paciência ele se fecha — você sai com o que conseguiu até ali."

const DATA := {
	"suspect": "Dono da oficina (teste)",
	"patience": 2,
	"shut_line": "Ele cruza os braços. \"Acabou. Quer mais, volta com advogado.\"",
	"evidence": [
		{"id": "foto", "label": "Foto do carro na câmera da rua"},
		{"id": "nota", "label": "Nota fiscal fria"},
		{"id": "recibo", "label": "Recibo do posto"},
	],
	"rounds": [
		{
			"line": "Nunca vi esse carro na vida.",
			"tell": "esfrega as mãos na calça e fala rápido demais.",
			"answer": "press",
			"success": "\"Tá, tá! Ele passou aqui semana passada, pediu placa nova.\"",
			"fail": "Ele relaxa, aliviado. \"Viu? Nada a ver comigo.\"",
			"reveal": "placa",
		},
		{
			"line": "Olha, eu tenho família, não quero problema.",
			"tell": "encolhe na cadeira e olha toda hora pra porta.",
			"answer": "support",
			"success": "\"O cara disse que volta se eu falar... Mas chamava o motorista de Ghost.\"",
			"fail": "Ele se encolhe mais. \"Não sei de nada. Nada.\"",
			"reveal": "apelido",
		},
		{
			"line": "Faço placa pra todo mundo, é meu trabalho. Tudo com nota.",
			"tell": "sorri, encosta na cadeira, resposta pronta demais.",
			"answer": "evidence",
			"evidence_id": "nota",
			"success": "O sorriso some. \"Tá... a nota é fria. Pagou em dinheiro vivo, adiantado.\"",
			"fail": "\"Isso aí não prova nada, detetive.\" Ele continua sorrindo.",
			"reveal": "pagamento",
		},
		{
			"line": "Não sei pra onde eles foram depois.",
			"tell": "olha pro relógio duas vezes e a perna não para.",
			"answer": "press",
			"success": "\"Cais! Falaram do Cais, de uma noite que já tá tudo combinado.\"",
			"fail": "Ele respira fundo e se recompõe. \"Já disse que não sei.\"",
			"reveal": "cais",
		},
		{
			"line": "Se eu falar mais, eles me acham.",
			"tell": "a voz falha, e ele aperta as próprias mãos.",
			"answer": "support",
			"success": "\"...Tem um galpão no fim da Rua 9. É onde guardam os carros.\"",
			"fail": "Ele trava de medo e fica em silêncio.",
			"reveal": "galpao",
		},
	],
}

var interrogation: Control
var legend_panel: Control
var result_panel: Control
var result_label: Label


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	interrogation = Control.new()
	interrogation.set_script(load("res://ui/interrogation.gd"))
	add_child(interrogation)
	interrogation.finished.connect(_on_finished)

	legend_panel = _screen(LEGEND, "Começar interrogatório", _start)
	result_panel = _screen("", "Recomeçar", _start)
	result_label = result_panel.get_meta("label")
	result_panel.visible = false


func _screen(text: String, button_text: String, callback: Callable) -> Control:
	var panel := Panel.new()
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	add_child(panel)
	var col := VBoxContainer.new()
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 40
	col.offset_right = -40
	col.offset_top = 30
	col.offset_bottom = -80
	col.add_theme_constant_override("separation", 20)
	panel.add_child(col)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 19)
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(label)
	var btn := Button.new()
	btn.text = button_text
	btn.custom_minimum_size = Vector2(0, 76)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(callback)
	col.add_child(btn)
	# "< Menu" só nas telas de legenda/resultado — durante o interrogatório
	# ele ficaria por cima do "Continuar" e roubaria o toque.
	var back := Button.new()
	back.text = "< Menu"
	back.custom_minimum_size = Vector2(0, 56)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://sandbox/menu.tscn"))
	col.add_child(back)
	panel.set_meta("label", label)
	return panel


func _start() -> void:
	legend_panel.visible = false
	result_panel.visible = false
	interrogation.setup(DATA)


func _on_finished(result: Dictionary) -> void:
	var revealed: Array = result["revealed"]
	var head := "Ele se fechou antes do fim." if result["shut_down"] else "Interrogatório completo."
	result_label.text = "%s\n\nLeituras certas: %d de %d\nInformações conseguidas: %s\n\nNas missões, cada informação vai valer algo depois (uma pista a mais no quadro, um vigia a menos, uma fala diferente)." % [head, result["correct"], result["total"], ", ".join(revealed) if not revealed.is_empty() else "nenhuma"]
	result_panel.visible = true
