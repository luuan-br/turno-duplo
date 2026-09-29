extends Control
## Caixa de texto sequencial — narrativa linear, sem ramificação. Isso é
## um placeholder deliberadamente simples: o "Modo Diálogo/Quadro de
## Evidências" de verdade (GDD Seção 8, com escolhas) ainda não foi
## prototipado. Serve pra sustentar as missões lineares dos Atos 1/2
## enquanto isso não existe. Mostra uma linha por vez (com nome de quem
## fala, opcional); toque em "Continuar" avança. Emite `finished` quando
## a última linha passa.

signal finished
signal advanced(index: int)

var _lines: Array[String] = []
var _speakers: Array[String] = []
var _index: int = -1

var _label: Label
var _speaker_label: Label


func _ready() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_top = -170.0
	offset_bottom = -10.0
	offset_left = 20.0
	offset_right = -20.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := Panel.new()
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	add_child(panel)

	_speaker_label = Label.new()
	_speaker_label.position = Vector2(18, 8)
	_speaker_label.add_theme_font_size_override("font_size", 15)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	add_child(_speaker_label)

	_label = Label.new()
	_label.position = Vector2(18, 32)
	_label.size = Vector2(600, 95)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 17)
	add_child(_label)

	var continue_btn := Button.new()
	continue_btn.text = tr("Continuar >")
	continue_btn.anchor_left = 1.0
	continue_btn.anchor_right = 1.0
	continue_btn.anchor_top = 1.0
	continue_btn.anchor_bottom = 1.0
	continue_btn.offset_left = -170.0
	continue_btn.offset_right = -16.0
	continue_btn.offset_top = -46.0
	continue_btn.offset_bottom = -10.0
	continue_btn.pressed.connect(_advance)
	add_child(continue_btn)

	visible = false


## `lines`: falas em ordem. `speakers` (opcional, mesmo tamanho): quem
## fala cada linha ("" pra narração sem nome).
func say(lines: Array, speakers: Array = []) -> void:
	_lines.clear()
	_speakers.clear()
	for i in lines.size():
		_lines.append(str(lines[i]))
		_speakers.append(str(speakers[i]) if i < speakers.size() else "")
	_index = -1
	visible = true
	_advance()


func is_active() -> bool:
	return visible


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		visible = false
		finished.emit()
		return
	# tr() aplicado aqui, num lugar só — quem chama `say()` passa a frase em
	# português direto, sem precisar lembrar de embrulhar cada linha.
	_label.text = tr(_lines[_index])
	var speaker := _speakers[_index]
	_speaker_label.text = tr(speaker) if speaker != "" else ""
	advanced.emit(_index)
