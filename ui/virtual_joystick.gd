extends Control
## Manche virtual preso a uma origem (aparece onde o dedo toca, volta a
## sumir ao soltar). Usado pro manche esquerdo (movimento/direção) e pro
## manche direito de mira no tático (`right_stick = true`) — o usuário
## pediu de volta o manche preso depois de testar a variante "arrastar
## livre" estilo shooter mobile; a referência aos jogos mobile era só
## sobre a disposição dos botões na tela, não sobre copiar esse
## comportamento específico de mira.

@export var right_stick: bool = false
@export var max_radius: float = 70.0
@export var base_color: Color = Color(1, 1, 1, 0.18)
@export var knob_color: Color = Color(1, 1, 1, 0.45)
## Ação disparada por toque duplo no manche (ex.: "shoot"). Vazio = desligado.
@export var double_tap_action: String = ""

const TAP_MAX_MS := 250
const TAP_MAX_DRAG := 20.0
const DOUBLE_TAP_MS := 300
const DOUBLE_TAP_MAX_DIST := 90.0

var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO
var _active: bool = false

var _start_ms := 0
var _max_drag := 0.0
var _touch_fired := false
var _last_was_tap := false
var _last_end_ms := -100000
var _last_end_pos := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _zone() -> Rect2:
	return Rect2(global_position, size)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _touch_index == -1 and _zone().has_point(t.position) and InputBridge.try_claim_touch(t.index):
				_start(t.index, t.position)
		elif t.index == _touch_index:
			_end_touch()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			_drag_to(d.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _touch_index == -1 and _zone().has_point(mb.position) and InputBridge.try_claim_touch(0):
				_start(0, mb.position)
			elif not mb.pressed and _touch_index == 0:
				_end_touch()
	elif event is InputEventMouseMotion and _touch_index == 0:
		_drag_to((event as InputEventMouseMotion).position)


func _start(index: int, pos: Vector2) -> void:
	var now := Time.get_ticks_msec()
	_touch_fired = double_tap_action != "" and _last_was_tap and now - _last_end_ms <= DOUBLE_TAP_MS and pos.distance_to(_last_end_pos) <= DOUBLE_TAP_MAX_DIST
	if _touch_fired:
		InputBridge.press(double_tap_action)
		InputBridge.release(double_tap_action)
	_start_ms = now
	_max_drag = 0.0
	_touch_index = index
	_origin = pos
	_knob = pos
	_active = true
	queue_redraw()


func _drag_to(pos: Vector2) -> void:
	var offset := pos - _origin
	_max_drag = maxf(_max_drag, offset.length())
	_knob = _origin + offset.limit_length(max_radius)
	queue_redraw()


func _end_touch() -> void:
	var now := Time.get_ticks_msec()
	# Toque que já disparou não abre outro toque duplo — senão pegar o
	# manche logo depois pra mirar soltava um tiro a mais sem querer.
	_last_was_tap = not _touch_fired and now - _start_ms <= TAP_MAX_MS and _max_drag <= TAP_MAX_DRAG
	_last_end_ms = now
	_last_end_pos = _origin
	InputBridge.release_touch(_touch_index)
	_touch_index = -1
	_active = false
	if right_stick:
		InputBridge.set_aim(false, Vector2.ZERO)
	else:
		InputBridge.set_move_vector(Vector2.ZERO)
	queue_redraw()


func _process(_delta: float) -> void:
	if _active:
		var offset := (_knob - _origin) / max_radius
		if right_stick:
			InputBridge.set_aim(true, offset)
		else:
			InputBridge.set_move_vector(offset)


func _draw() -> void:
	if not _active:
		return
	var local_origin := _origin - global_position
	var local_knob := _knob - global_position
	draw_circle(local_origin, max_radius, base_color)
	draw_circle(local_knob, max_radius * 0.4, knob_color)
