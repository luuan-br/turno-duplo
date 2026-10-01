extends Control
## Prompt de escolha simples — duas (ou mais) opções, sem ramificação de
## missão de verdade (a Seção 9 do GDD já decidiu isso: o peso da escolha
## aparece em diálogo/medidor/epílogo, não em estrutura de missão
## diferente). Não é o Modo Diálogo/Quadro de Evidências completo (esse
## ainda não foi prototipado) — é só o suficiente pra uma decisão binária
## tipo "força vs. de-escalação" alimentar um medidor.

signal chosen(index: int)

var _spawned: Array[Node] = []


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

	visible = false


## `prompt`: pergunta/contexto. `options`: textos dos botões (2 a 3).
func ask(prompt: String, options: Array) -> void:
	for n in _spawned:
		n.queue_free()
	_spawned.clear()

	var label := Label.new()
	label.text = tr(prompt)
	label.position = Vector2(18, 10)
	label.size = Vector2(600, 40)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	_spawned.append(label)

	var btn_width := 280.0
	var start_x := 20.0
	for i in options.size():
		var btn := Button.new()
		btn.text = tr(str(options[i]))
		btn.position = Vector2(start_x + i * (btn_width + 16.0), 60)
		btn.custom_minimum_size = Vector2(btn_width, 60)
		btn.pressed.connect(_on_chosen.bind(i))
		add_child(btn)
		_spawned.append(btn)

	visible = true


func _on_chosen(index: int) -> void:
	visible = false
	chosen.emit(index)


func is_active() -> bool:
	return visible
