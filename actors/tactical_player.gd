class_name TacticalPlayer
extends CharacterBody2D
## Jogador tático compartilhado (GDD Seção 8, "Risco e consequência no
## combate tático") — junta o que estava copiado em cada missão:
## movimento + sprint (com barulho), mira com suavização exponencial, tiro
## por raio de física, colete e queda. A missão decide O QUE o tiro
## acertou significa (sinal `fired`); guarda acertado cai sozinho.
## Quem trava/libera é a missão (`controls_locked`, `can_shoot`).

signal fired(collider: Object, from: Vector2, to: Vector2)
signal hit_taken(vest_left: int)
signal downed

const RADIUS := 14.0
const NOISE_GUNSHOT := 550.0
const NOISE_SPRINT_STEP := 170.0
const SPRINT_STEP_INTERVAL := 0.35

var speed_cautious := 90.0
var speed_sprint := 170.0
var sprint_charge_time := 2.0
var sprint_deflect_threshold := 0.75
var sprint_charge_decay := 2.0
var aim_responsiveness := 16.0
var fire_range := 900.0
var body_color := Color(0.3, 0.6, 0.9)

var controls_locked := true
var can_shoot := false
var combat: CombatLayer
var extra_exclude: Array[RID] = []
var camera: Camera2D

var facing := Vector2.RIGHT
var vest_hits := 0
var vest_hp := 0
var is_down := false

var aim_end := Vector2.ZERO
var aim_on_target := false
var _sprint_charge := 0.0
var _step_timer := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)


## Equipamento é fixo por ato (GDD Seção 11): a missão diz se o Mark está
## de colete e quantos tiros ele segura. 0 = sem colete, um tiro derruba.
func set_vest(hits: int) -> void:
	vest_hits = hits
	vest_hp = hits


func is_sprinting() -> bool:
	return _sprint_charge >= sprint_charge_time


func take_shot() -> void:
	if is_down:
		return
	if vest_hp > 0:
		vest_hp -= 1
		hit_taken.emit(vest_hp)
		return
	is_down = true
	controls_locked = true
	velocity = Vector2.ZERO
	downed.emit()


func _process(delta: float) -> void:
	# Consome sempre, mesmo travado — senão um toque durante o diálogo
	# dispara sozinho no instante em que o controle volta.
	var pressed_shoot := InputBridge.consume_just_pressed("shoot")
	if is_down or controls_locked:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	_move(delta)
	_update_facing(delta)
	if can_shoot:
		_update_aim()
		if pressed_shoot:
			_fire()
	queue_redraw()


func _move(delta: float) -> void:
	var move := InputBridge.move_vector
	if move.length() >= sprint_deflect_threshold:
		_sprint_charge += delta
	else:
		_sprint_charge = maxf(0.0, _sprint_charge - sprint_charge_decay * delta)
	velocity = move * (speed_sprint if is_sprinting() else speed_cautious)
	move_and_slide()

	if is_sprinting() and move.length() > 0.1:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = SPRINT_STEP_INTERVAL
			if combat:
				combat.noise(global_position, NOISE_SPRINT_STEP)
	else:
		_step_timer = 0.0


## Exponencial em vez de taxa fixa: giro grande vai rápido, ajuste fino
## suaviza (a taxa fixa antiga era o "mira travada" relatado).
func _update_facing(delta: float) -> void:
	if InputBridge.aim_touching and InputBridge.aim_vector.length() > 0.15:
		var t := 1.0 - exp(-aim_responsiveness * delta)
		facing = Vector2.from_angle(lerp_angle(facing.angle(), InputBridge.aim_vector.angle(), t))


func _cast() -> Dictionary:
	var start := global_position + facing * (RADIUS + 2.0)
	var q := PhysicsRayQueryParameters2D.create(start, start + facing * fire_range)
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var ex: Array[RID] = [get_rid()]
	ex.append_array(extra_exclude)
	q.exclude = ex
	return get_world_2d().direct_space_state.intersect_ray(q)


func _update_aim() -> void:
	var r := _cast()
	if r.is_empty():
		aim_end = global_position + facing * fire_range
		aim_on_target = false
	else:
		aim_end = r.position
		aim_on_target = r.collider is EnemyGuard and not r.collider.is_dead()


func _fire() -> void:
	var r := _cast()
	var end: Vector2 = r.position if not r.is_empty() else global_position + facing * fire_range
	# Barulho do tiro sai antes do impacto: se a missão fizer barulho no
	# ponto atingido (caixa quebrando), esse é o mais recente e puxa os
	# guardas pra lá — é o que faz distração funcionar.
	if combat:
		combat.shot_line(global_position, end, false)
		combat.noise(global_position, NOISE_GUNSHOT)
	var col: Object = null if r.is_empty() else r.collider
	if col is EnemyGuard and not col.is_dead():
		col.take_hit()
	fired.emit(col, global_position, end)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.3, 0.1, 0.1) if is_down else body_color)
	if is_down:
		return
	if vest_hp > 0:
		draw_arc(Vector2.ZERO, RADIUS + 3.0, 0.0, TAU, 24, Color(0.4, 0.7, 1.0), 3.0)
	if can_shoot and not controls_locked:
		var c := Color(0.3, 1.0, 0.4, 0.8) if aim_on_target else Color(1.0, 1.0, 1.0, 0.35)
		var local_end := aim_end - global_position
		draw_dashed_line(Vector2.ZERO, local_end, c, 2.0, 10.0)
		draw_circle(local_end, 5.0, c)
	else:
		draw_line(Vector2.ZERO, facing * (RADIUS + 24.0), Color.WHITE, 3.0)
	if _sprint_charge > 0.05 and _sprint_charge < sprint_charge_time:
		var frac := _sprint_charge / sprint_charge_time
		draw_arc(Vector2.ZERO, RADIUS + 7.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 24, Color.YELLOW, 3.0)
