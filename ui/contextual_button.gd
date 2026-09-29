extends Control
## Botão contextual — GDD Seção 8, revisado após o 1º teste no celular:
## em vez de um único botão "AÇÃO" ambíguo fazendo tudo por toque/segurar,
## cada ação tem seu próprio botão nomeado, que o sandbox mostra/esconde
## conforme o que está por perto (porta, alvo, etc.).

@export var action_name: String = "action"
@export var radius: float = 50.0
@export var label_text: String = ""
@export var idle_color: Color = Color(1, 1, 1, 0.25)
@export var pressed_color: Color = Color(1, 0.6, 0.2, 0.55)

var _touch_index: int = -1
var _pressed: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not visible:
		return

	var center := global_position + size * 0.5

	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _touch_index == -1 and center.distance_to(t.position) <= radius and InputBridge.try_claim_touch(t.index):
				_touch_index = t.index
				_set_pressed(true)
		elif t.index == _touch_index:
			InputBridge.release_touch(_touch_index)
			_touch_index = -1
			_set_pressed(false)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _touch_index == -1 and center.distance_to(mb.position) <= radius and InputBridge.try_claim_touch(0):
				_touch_index = 0
				_set_pressed(true)
			elif not mb.pressed and _touch_index == 0:
				InputBridge.release_touch(_touch_index)
				_touch_index = -1
				_set_pressed(false)


func _set_pressed(value: bool) -> void:
	_pressed = value
	if value:
		InputBridge.press(action_name)
	else:
		InputBridge.release(action_name)
	queue_redraw()


func _notification(what: int) -> void:
	# Se o botão some enquanto pressionado (mudou de contexto), solta a ação
	# e libera a reivindicação do toque (senão esse dedo fica "preso" pra
	# sempre, já que o evento normal de soltar nunca chega a um nó oculto).
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _pressed:
		InputBridge.release_touch(_touch_index)
		_touch_index = -1
		_set_pressed(false)


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, pressed_color if _pressed else idle_color)
	if label_text != "":
		var font := ThemeDB.fallback_font
		var font_size := 15
		var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - text_size * 0.5 + Vector2(0, font_size * 0.35), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
