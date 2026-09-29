extends Node
## Camada única de input, abstraída por ação (GDD Seção 8).
## Manches/botões escrevem aqui; qualquer sandbox lê daqui.

var move_vector: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.ZERO
var aim_touching: bool = false

var _held: Dictionary = {}
var _just_pressed: Dictionary = {}
var _just_released: Dictionary = {}
var _hold_start_ms: Dictionary = {}

## Reivindicação de toque: quando duas zonas de toque se sobrepõem (ex.:
## manche direito e um botão perto do canto onde ele fica), sem isso os
## dois processam o MESMO toque ao mesmo tempo — o manche recebia um
## toque interrompido/reiniciado toda vez que o dedo passava perto do
## botão ATIRAR, o que parecia "menos suave" e "às vezes não aparece".
## Cada dedo (índice de toque) só pode pertencer a um controle por vez.
var _claimed_touches: Dictionary = {}


func try_claim_touch(index: int) -> bool:
	if _claimed_touches.get(index, false):
		return false
	_claimed_touches[index] = true
	return true


func release_touch(index: int) -> void:
	_claimed_touches.erase(index)


func _process(_delta: float) -> void:
	# Teclado, só para testar rápido no editor (PC) sem os manches na tela.
	var kb := Vector2.ZERO
	kb.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	kb.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	if kb != Vector2.ZERO:
		move_vector = kb.limit_length(1.0)


func set_move_vector(v: Vector2) -> void:
	move_vector = v.limit_length(1.0)


func set_aim(active: bool, v: Vector2) -> void:
	aim_touching = active
	aim_vector = v


func press(action: String) -> void:
	if not _held.get(action, false):
		_just_pressed[action] = true
		_hold_start_ms[action] = Time.get_ticks_msec()
	_held[action] = true


func release(action: String) -> void:
	if _held.get(action, false):
		_just_released[action] = true
	_held[action] = false


func is_held(action: String) -> bool:
	return _held.get(action, false)


func hold_time(action: String) -> float:
	if not _held.get(action, false):
		return 0.0
	return (Time.get_ticks_msec() - _hold_start_ms.get(action, Time.get_ticks_msec())) / 1000.0


func consume_just_pressed(action: String) -> bool:
	var v: bool = _just_pressed.get(action, false)
	_just_pressed[action] = false
	return v


func consume_just_released(action: String) -> bool:
	var v: bool = _just_released.get(action, false)
	_just_released[action] = false
	return v
