extends Control
## Tela "Configurar controles" (GDD Seção 8, "Layout de controles
## configurável"): o jogador arrasta os botões pra onde quiser e muda o
## tamanho; vale pra todas as fases. Não deixa salvar botões encostados
## (disputariam o mesmo dedo — bug real no celular) nem em cima do
## "< Menu". Os manches são flutuantes e não aparecem aqui como botão.

const TOOLBAR_H := 140.0
const SIZE_STEP := 8.0
const BG := Color(0.2, 0.2, 0.23)

var mode := "pe"
var selected := ""
var _dragging := false
var _drag_offset := Vector2.ZERO

var canvas: Control
var tab_pe: Button
var tab_carro: Button
var size_label: Label
var msg_label: Label


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Área de arrastar por baixo da barra de cima (a barra ganha o toque).
	canvas = Control.new()
	canvas.anchor_right = 1.0
	canvas.anchor_bottom = 1.0
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.gui_input.connect(_on_canvas_input)
	add_child(canvas)

	var title := Label.new()
	title.text = tr("Controles — arraste os botões pra onde quiser")
	title.position = Vector2(16, 12)
	title.add_theme_font_size_override("font_size", 20)
	add_child(title)

	tab_pe = _button(tr("A pé"), Vector2(16, 52), 110, func(): _set_mode("pe"))
	tab_carro = _button(tr("Carro"), Vector2(132, 52), 110, func(): _set_mode("carro"))
	tab_pe.toggle_mode = true
	tab_carro.toggle_mode = true

	var size_title := Label.new()
	size_title.text = tr("Tamanho:")
	size_title.position = Vector2(268, 62)
	add_child(size_title)
	_button("−", Vector2(350, 52), 50, func(): _resize(-SIZE_STEP))
	size_label = Label.new()
	size_label.position = Vector2(408, 62)
	size_label.size = Vector2(44, 30)
	size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(size_label)
	_button("+", Vector2(456, 52), 50, func(): _resize(SIZE_STEP))

	var right := Control.new()
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	add_child(right)
	_button(tr("Restaurar padrão"), Vector2(-430, 52), 150, _on_reset, right)
	_button(tr("Salvar"), Vector2(-272, 52), 110, _on_save, right)
	_button(tr("< Voltar"), Vector2(-154, 52), 138, _on_back, right)

	msg_label = Label.new()
	msg_label.position = Vector2(16, 102)
	msg_label.add_theme_font_size_override("font_size", 15)
	add_child(msg_label)

	_set_mode("pe")


func _button(text: String, pos: Vector2, w: float, cb: Callable, parent: Control = self) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(w, 44)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _screen() -> Vector2:
	return get_viewport_rect().size


## Centro do lugar em coordenadas de tela (o ControlLayout mede a partir
## do canto inferior direito).
func screen_pos(slot: String) -> Vector2:
	return _screen() - ControlLayout.center_of(slot)


func _set_mode(m: String) -> void:
	mode = m
	tab_pe.button_pressed = m == "pe"
	tab_carro.button_pressed = m == "carro"
	selected = ControlLayout.slots_for_mode(m)[0]
	_dragging = false
	_refresh("")


func _resize(delta: float) -> void:
	if selected == "":
		return
	ControlLayout.set_placement(selected, ControlLayout.center_of(selected), ControlLayout.size_of(selected) + delta)
	_move_to(screen_pos(selected))
	_refresh("")


func _on_reset() -> void:
	ControlLayout.reset_defaults()
	_refresh(tr("Disposição padrão restaurada — toque Salvar pra manter."))


func _on_save() -> void:
	for m in ["pe", "carro"]:
		var p := ControlLayout.problems(m, _screen())
		if not p.is_empty():
			_set_mode(m)
			_refresh(p[0] + " " + tr("Afaste antes de salvar."))
			return
	ControlLayout.save_layout()
	_refresh(tr("Salvo! Vale pra todas as fases."))


func _on_back() -> void:
	# Sai sem salvar: volta pro que estava gravado.
	ControlLayout.load_layout()
	get_tree().change_scene_to_file("res://sandbox/menu.tscn")


func _slot_at(p: Vector2) -> String:
	for s in ControlLayout.slots_for_mode(mode):
		if screen_pos(s).distance_to(p) <= ControlLayout.size_of(s) * 0.5:
			return s
	return ""


func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var s := _slot_at(event.position)
			if s != "":
				selected = s
				_dragging = true
				_drag_offset = screen_pos(s) - event.position
				_refresh("")
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		_move_to(event.position + _drag_offset)
		_refresh("")


## Move o selecionado, sem deixar sair da tela nem subir na barra de cima.
func _move_to(p: Vector2) -> void:
	var r := ControlLayout.size_of(selected) * 0.5
	var scr := _screen()
	var c := Vector2(clampf(p.x, r, scr.x - r), clampf(p.y, TOOLBAR_H + r, scr.y - r))
	ControlLayout.set_placement(selected, scr - c, ControlLayout.size_of(selected))


func _refresh(msg: String) -> void:
	size_label.text = str(int(ControlLayout.size_of(selected))) if selected != "" else "-"
	if msg != "":
		msg_label.text = msg
	else:
		var p := ControlLayout.problems(mode, _screen())
		msg_label.text = p[0] if not p.is_empty() else tr("Toque num botão pra escolher, arraste pra mover. Os manches aparecem onde você tocar.")
	queue_redraw()


func _draw() -> void:
	var scr := _screen()
	draw_rect(Rect2(Vector2.ZERO, scr), BG)
	var font := ThemeDB.fallback_font

	# Onde ficam os manches (flutuantes, não se arrastam).
	var split := scr.x * (0.5 if mode == "pe" else 0.55)
	draw_dashed_line(Vector2(split, TOOLBAR_H), Vector2(split, scr.y), Color(1, 1, 1, 0.2), 2.0, 12.0)
	var left_hint := tr("Manche de movimento") if mode == "pe" else tr("Manche de direção")
	draw_string(font, Vector2(24, TOOLBAR_H + 30), left_hint + " " + tr("(aparece onde você tocar)"), HORIZONTAL_ALIGNMENT_LEFT, split - 40, 14, Color(1, 1, 1, 0.45))
	if mode == "pe":
		draw_string(font, Vector2(split + 24, TOOLBAR_H + 30), tr("Manche de mira (aparece onde você tocar)"), HORIZONTAL_ALIGNMENT_LEFT, scr.x - split - 40, 14, Color(1, 1, 1, 0.45))

	# "< Menu": fixo, nada pode ficar em cima.
	var menu := Rect2(Vector2(ControlLayout.MENU_RECT.position.x, scr.y - ControlLayout.MENU_RECT.position.y - ControlLayout.MENU_RECT.size.y), ControlLayout.MENU_RECT.size)
	draw_rect(menu, Color(0.1, 0.1, 0.12))
	draw_string(font, menu.position + Vector2(30, 32), "< Menu", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.6))

	var bad := ControlLayout.conflicting_slots(mode, scr)
	for s in ControlLayout.slots_for_mode(mode):
		var c := screen_pos(s)
		var r := ControlLayout.size_of(s) * 0.5
		var fill := Color(1, 1, 1, 0.25)
		if s in bad:
			fill = Color(0.9, 0.2, 0.2, 0.55)
		elif s == selected:
			fill = Color(1, 0.6, 0.2, 0.5)
		draw_circle(c, r, fill)
		if s == selected:
			draw_arc(c, r + 4.0, 0.0, TAU, 32, Color(1, 0.75, 0.3), 3.0)
		var text := tr(ControlLayout.SLOTS[s]["label"])
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(font, c - Vector2(ts.x * 0.5, -5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
