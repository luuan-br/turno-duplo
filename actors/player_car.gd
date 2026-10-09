class_name PlayerCar
extends CharacterBody2D
## Carro do jogador compartilhado (GDD Seção 8, "Risco real nas
## perseguições"). Direção relativa à tela + ACELERAR/FREAR/FREIO DE MÃO
## em botões — exatamente o controle validado no celular — mais lataria:
## batida forte machuca e derruba a velocidade, carro destruído = missão
## recomeça. A força da batida é a velocidade relativa contra o que foi
## atingido (parede parada, ou outro carro vindo na sua direção).

signal damaged(hp: float)
signal wrecked
signal bumped(collider: Object, impact: float)

const SIZE := Vector2(28, 16)
const BUMP_COOLDOWN := 0.35

var max_speed := 185.0
var accel := 220.0
var brake_decel := 420.0
var reverse_speed := 100.0
var coast_decel := 90.0
var turn_rate := 2.6
var handbrake_turn_bonus := 1.2
var handbrake_speed_penalty := 0.55
var steer_deadzone := 0.2

var max_hp := 100.0
var hp := 100.0
var impact_threshold := 60.0
var impact_damage_mult := 0.2
var car_impact_mult := 0.5
var body_color := Color(0.3, 0.6, 0.9)

var controls_locked := true
var speed := 0.0
var is_wrecked := false
var camera: Camera2D

var _bump_cooldown: Dictionary = {}
var _flash := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	add_child(shape)

	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)


func forward() -> Vector2:
	return Vector2.RIGHT.rotated(rotation)


func take_damage(amount: float) -> void:
	if is_wrecked or amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	_flash = 0.15
	damaged.emit(hp)
	if hp <= 0.0:
		is_wrecked = true
		controls_locked = true
		speed = 0.0
		velocity = Vector2.ZERO
		wrecked.emit()


## Chamado pelos dois lados de uma batida (este carro e o carro inimigo
## que bateu nele) — o cooldown por objeto evita contar a mesma batida
## duas vezes.
func register_impact(collider: Object, impact: float) -> void:
	if collider == null:
		return
	var id := collider.get_instance_id()
	if _bump_cooldown.has(id):
		return
	_bump_cooldown[id] = BUMP_COOLDOWN
	bumped.emit(collider, impact)
	if impact > impact_threshold and not is_wrecked:
		var mult := car_impact_mult if collider is CharacterBody2D else 1.0
		take_damage((impact - impact_threshold) * impact_damage_mult * mult)
		speed *= 0.5


func _process(delta: float) -> void:
	for id in _bump_cooldown.keys():
		_bump_cooldown[id] -= delta
		if _bump_cooldown[id] <= 0.0:
			_bump_cooldown.erase(id)
	_flash = maxf(0.0, _flash - delta)
	if is_wrecked or controls_locked:
		speed = 0.0
		velocity = Vector2.ZERO
		queue_redraw()
		return
	_drive(delta)
	queue_redraw()


func _drive(delta: float) -> void:
	var accelerating := InputBridge.is_held("accelerate")
	var braking := InputBridge.is_held("brake")
	var handbraking := InputBridge.is_held("handbrake")

	if accelerating and not braking:
		speed = move_toward(speed, max_speed, accel * delta)
	elif braking:
		if speed > 0.0:
			speed = move_toward(speed, 0.0, brake_decel * delta)
		else:
			speed = move_toward(speed, -reverse_speed, accel * delta)
	else:
		speed = move_toward(speed, 0.0, coast_decel * delta)

	var turn_mult: float = turn_rate + (handbrake_turn_bonus if handbraking else 0.0)
	var speed_cap: float = max_speed * (handbrake_speed_penalty if handbraking else 1.0)
	speed = clampf(speed, -reverse_speed, speed_cap)

	# Direção relativa à TELA: o manche aponta pra onde ir, o carro gira o
	# nariz até lá numa taxa limitada (validado no 3º teste de controles).
	if InputBridge.move_vector.length() >= steer_deadzone and absf(speed) > 5.0:
		var diff := wrapf(InputBridge.move_vector.angle() - rotation, -PI, PI)
		var speed_factor: float = clampf(absf(speed) / max_speed, 0.35, 1.0)
		var max_step: float = turn_mult * speed_factor * delta
		rotation += clampf(diff, -max_step, max_step)

	velocity = forward() * speed
	var pre := velocity
	move_and_slide()
	# A velocidade "interna" não pode passar do que o carro andou de verdade
	# — senão, prensado na parede segurando ACELERAR, ela subia até o
	# máximo e cada contato contava como batida a toda velocidade.
	var actual := get_real_velocity().dot(forward())
	if absf(actual) < absf(speed):
		speed = actual
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider()
		var other_vel := Vector2.ZERO
		if col is CharacterBody2D:
			other_vel = col.velocity
		register_impact(col, maxf(0.0, -(pre - other_vel).dot(c.get_normal())))


func _draw() -> void:
	var half := SIZE * 0.5
	var dmg := 1.0 - hp / max_hp
	var c := body_color.lerp(Color(0.25, 0.25, 0.25), dmg * 0.8)
	if _flash > 0.0:
		c = Color.WHITE
	draw_rect(Rect2(-half, SIZE), c)
	draw_line(Vector2.ZERO, Vector2(20, 0), Color.WHITE, 2.0)
	if hp / max_hp < 0.4:
		draw_circle(Vector2(-6, 0), 5.0 + 3.0 * dmg, Color(0.4, 0.4, 0.4, 0.6))
