extends Control
## Quadro de Evidências — primeira versão real do mecanismo que a Seção 8
## do GDD menciona desde o Ato 1 como pendência ("Modo Diálogo/Quadro de
## Evidências ainda não prototipado"). Escopo desta versão: conectar
## pares de pistas certas, tocando duas de cada vez — não é o Modo
## Diálogo com ramificação de conversa (isso continua pendente); é
## especificamente o quadro de conectar pistas que a Fase 4 do Ato 3
## precisa.
##
## Uso: `setup([["Furtos pequenos", "Testes de acesso"], [...]])` — cada
## item é um par que deve ser conectado. A ordem de cada par não importa
## (A-B conecta igual B-A). Emite `completed` quando todos os pares
## tiverem sido conectados corretamente.

signal completed

var _pairs: Array = []            ## Array de Array[String, String]
var _node_pair_index: Dictionary = {} ## nó -> índice do par que pertence
var _nodes: Array[Button] = []
var _connected_pairs: Dictionary = {} ## índice do par -> true quando já ligado
var _selected: Button = null
var _lines: Array[Dictionary] = []  ## {a: Vector2, b: Vector2} já conectadas, pra desenhar

var _canvas: Control


func _ready() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var title := Label.new()
	title.text = tr("Quadro de Evidências — toque duas pistas pra conectar")
	title.position = Vector2(20, 14)
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

	_canvas = Control.new()
	_canvas.anchor_right = 1.0
	_canvas.anchor_bottom = 1.0
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_lines)
	add_child(_canvas)

	visible = false


func setup(pairs: Array) -> void:
	for n in _nodes:
		n.queue_free()
	_nodes.clear()
	_node_pair_index.clear()
	_connected_pairs.clear()
	_lines.clear()
	_selected = null
	_pairs = pairs

	# Embaralha a ordem de exibição (não a dos pares) pra não ficar óbvio
	# que o item da esquerda sempre combina com o da direita.
	var flat: Array = []
	for i in pairs.size():
		flat.append({"text": pairs[i][0], "pair": i})
		flat.append({"text": pairs[i][1], "pair": i})
	flat.shuffle()

	var cols := 2
	var card_w := 320.0
	var card_h := 70.0
	var start_x := 40.0
	var start_y := 70.0
	var gap := 20.0

	for i in flat.size():
		var col := i % cols
		var row := i / cols
		var btn := Button.new()
		btn.text = tr(str(flat[i]["text"]))
		btn.position = Vector2(start_x + col * (card_w + gap), start_y + row * (card_h + gap))
		btn.custom_minimum_size = Vector2(card_w, card_h)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.pressed.connect(_on_node_pressed.bind(btn))
		add_child(btn)
		move_child(btn, get_child_count() - 1)
		_nodes.append(btn)
		_node_pair_index[btn] = int(flat[i]["pair"])

	visible = true


func _on_node_pressed(btn: Button) -> void:
	var pair_index: int = _node_pair_index[btn]
	if _connected_pairs.get(pair_index, false):
		return  # já ligado, ignora

	if _selected == null:
		_selected = btn
		btn.modulate = Color(1.0, 0.85, 0.4)
		return

	if _selected == btn:
		return

	var selected_pair: int = _node_pair_index[_selected]
	if selected_pair == pair_index and _selected != btn:
		# Par certo — mas só conta se forem os DOIS lados do mesmo par
		# (não o mesmo nó clicado duas vezes), o que já garantimos acima.
		_connected_pairs[pair_index] = true
		_lines.append({"a": _selected.position + _selected.size * 0.5, "b": btn.position + btn.size * 0.5})
		_selected.modulate = Color(0.5, 1.0, 0.6)
		btn.modulate = Color(0.5, 1.0, 0.6)
		_selected.disabled = true
		btn.disabled = true
		_selected = null
		_canvas.queue_redraw()
		if _connected_pairs.size() >= _pairs.size():
			await get_tree().create_timer(0.4).timeout
			visible = false
			completed.emit()
	else:
		# Par errado — pisca vermelho e desseleciona.
		btn.modulate = Color(1.0, 0.4, 0.4)
		_selected.modulate = Color(1.0, 0.4, 0.4)
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(btn):
			btn.modulate = Color.WHITE
		if is_instance_valid(_selected):
			_selected.modulate = Color.WHITE
		_selected = null


func _draw_lines() -> void:
	for line in _lines:
		_canvas.draw_line(line["a"], line["b"], Color(0.4, 0.9, 0.5), 3.0)


func is_active() -> bool:
	return visible
