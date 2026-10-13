extends Control
## Interrogatório (GDD Seção 8, "Modo Diálogo / Interrogatório") — toque
## direto, sem manches. Rodadas: o suspeito fala e deixa escapar uma
## DEIXA; o jogador escolhe PRESSIONAR, APOIAR ou MOSTRAR PROVA. A deixa
## segue uma regra fixa (nervoso → pressionar; assustado → apoiar; calmo
## demais → só a prova certa), então é leitura, não chute. Errar gasta
## paciência; sem paciência o suspeito se fecha — a história segue, só
## com menos informação (sem fail state).
##
## Uso: `setup(dados)` e esperar `finished(resultado)`.
##   dados = {
##     "suspect": "Lou", "patience": 2,
##     "evidence": [{"id": "roteador", "label": "Roteador do apartamento"}],
##     "shut_line": "fala de quando ele se fecha",
##     "rounds": [{
##       "line": "fala do suspeito", "tell": "a deixa",
##       "answer": "press" | "support" | "evidence", "evidence_id": "roteador",
##       "success": "reação ao acertar", "fail": "reação ao errar",
##       "reveal": "id da informação revelada" (opcional)
##     }, ...]
##   }
##   resultado = {"revealed": [ids], "shut_down": bool, "correct": n, "total": n}

signal finished(result: Dictionary)

const TELL_COLOR := Color(1.0, 0.85, 0.35)
const GOOD_COLOR := Color(0.5, 1.0, 0.6)
const BAD_COLOR := Color(1.0, 0.5, 0.45)

var _data: Dictionary = {}
var _rounds: Array = []
var _round := 0
var _patience := 0
var _revealed: Array = []
var _correct := 0
var _shut := false

var _name_label: Label
var _patience_label: Label
var _line_label: Label
var _tell_label: Label
var _reaction_label: Label
var _approach_box: HBoxContainer
var _evidence_box: HBoxContainer
var _continue_btn: Button


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Fundo opaco: translúcido, a cena e o "< Menu" apareciam por trás dos
	# botões.
	var bg := Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.23)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_name_label)
	_patience_label = Label.new()
	_patience_label.add_theme_font_size_override("font_size", 18)
	header.add_child(_patience_label)

	_line_label = _wrapped_label(20, Color.WHITE)
	col.add_child(_line_label)
	_tell_label = _wrapped_label(19, TELL_COLOR)
	col.add_child(_tell_label)
	_reaction_label = _wrapped_label(19, GOOD_COLOR)
	col.add_child(_reaction_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	_approach_box = HBoxContainer.new()
	_approach_box.add_theme_constant_override("separation", 16)
	col.add_child(_approach_box)
	_approach_box.add_child(_big_button(tr("PRESSIONAR"), _on_approach.bind("press")))
	_approach_box.add_child(_big_button(tr("APOIAR"), _on_approach.bind("support")))
	_approach_box.add_child(_big_button(tr("MOSTRAR PROVA"), _on_approach.bind("evidence")))

	_evidence_box = HBoxContainer.new()
	_evidence_box.add_theme_constant_override("separation", 12)
	col.add_child(_evidence_box)

	_continue_btn = _big_button(tr("Continuar >"), _on_continue)
	col.add_child(_continue_btn)

	visible = false


func _wrapped_label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _big_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 76)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(callback)
	return b


func setup(data: Dictionary) -> void:
	_data = data
	_rounds = data.get("rounds", [])
	_round = 0
	_patience = int(data.get("patience", 2))
	_revealed = []
	_correct = 0
	_shut = false
	_name_label.text = tr("Interrogatório — %s") % tr(str(data.get("suspect", "")))
	visible = true
	_show_round()


func is_active() -> bool:
	return visible


func _update_patience() -> void:
	_patience_label.text = tr("Paciência: %s") % ("●".repeat(maxi(_patience, 0)) + "○".repeat(maxi(int(_data.get("patience", 2)) - _patience, 0)))


func _show_round() -> void:
	var r: Dictionary = _rounds[_round]
	_update_patience()
	_line_label.text = "\"" + tr(str(r.get("line", ""))) + "\""
	_tell_label.text = tr("Deixa: %s") % tr(str(r.get("tell", "")))
	_tell_label.visible = true
	_reaction_label.visible = false
	_approach_box.visible = true
	_evidence_box.visible = false
	_continue_btn.visible = false


func _on_approach(kind: String) -> void:
	if kind == "evidence":
		_show_evidence_picker()
	else:
		_resolve(kind, "")


func _show_evidence_picker() -> void:
	for c in _evidence_box.get_children():
		c.queue_free()
	for ev in _data.get("evidence", []):
		_evidence_box.add_child(_big_button(tr(str(ev.get("label", ""))), _resolve.bind("evidence", str(ev.get("id", "")))))
	_evidence_box.add_child(_big_button(tr("< Voltar"), _show_round))
	_approach_box.visible = false
	_evidence_box.visible = true


func _resolve(kind: String, evidence_id: String) -> void:
	var r: Dictionary = _rounds[_round]
	var ok: bool = kind == str(r.get("answer", "")) and (kind != "evidence" or evidence_id == str(r.get("evidence_id", "")))
	var reaction := ""
	if ok:
		_correct += 1
		if r.has("reveal"):
			_revealed.append(r["reveal"])
		reaction = tr(str(r.get("success", "")))
		_reaction_label.add_theme_color_override("font_color", GOOD_COLOR)
	else:
		_patience -= 1
		reaction = tr(str(r.get("fail", "")))
		if _patience <= 0:
			_shut = true
			reaction += "\n" + tr(str(_data.get("shut_line", "")))
		_reaction_label.add_theme_color_override("font_color", BAD_COLOR)
	_update_patience()
	_reaction_label.text = reaction
	_reaction_label.visible = true
	_tell_label.visible = false
	_approach_box.visible = false
	_evidence_box.visible = false
	_continue_btn.visible = true


func _on_continue() -> void:
	_round += 1
	if _shut or _round >= _rounds.size():
		visible = false
		finished.emit({"revealed": _revealed, "shut_down": _shut, "correct": _correct, "total": _rounds.size()})
		return
	_show_round()
