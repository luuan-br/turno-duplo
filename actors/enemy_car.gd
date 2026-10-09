class_name EnemyCar
extends CharacterBody2D
## Carro inimigo compartilhado (GDD Seção 8, "Risco real nas
## perseguições"). FLEE segue uma rota em volta; PURSUE vai pra cima do
## jogador. Opcional: passageiro que atira (mostra a mira antes, como os
## guardas a pé) e freada brusca quando o jogador cola atrás. Roda/para
## quando a lataria (`hp`) acaba ou leva PIT — emite `disabled`.

signal disabled
signal fired(from: Vector2, to: Vector2, hit: bool)

enum Mode { FLEE, PURSUE }

const SIZE := Vector2(28, 16)

var mode := Mode.FLEE
var waypoints: Array[Vector2] = []
var speed := 140.0
var target: PlayerCar
var max_hp := 3.0
var hp := 3.0
var body_color := Color(0.9, 0.3, 0.3)

var shooter := false
var shoot_range := 260.0
var aim_time := 0.8
var fire_cooldown := 1.8
var shot_damage := 20.0

var brake_check := false
var brake_check_cooldown := 4.0

var is_disabled := false

var _shape: CollisionShape2D
var _wp_index := 0
var _spin_timer := 0.0
var _aim_timer := -1.0
var _cooldown := 1.0
var _brake_timer := 0.0
var _brake_cd := 2.0
var _recoil := 0.0
var _flash := 0.0


func _ready() -> void:
	add_to_group("enemy_cars")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# Pausado (esperando o diálogo/a largada) continua sólido — o padrão do
	# Godot tiraria o carro da física e ele viraria fantasma.
	disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	_shape.shape = rect
	add_child(_shape)
	hp = max_hp
	if waypoints.size() > 1:
		rotation = (waypoints[1] - waypoints[0]).angle()


func take_damage(amount: float) -> void:
	if is_disabled:
		return
	hp -= amount
	_flash = 0.15
	if hp <= 0.0:
		spin_out()


func spin_out() -> void:
	if is_disabled:
		return
	is_disabled = true
	_spin_timer = 1.2
	_aim_timer = -1.0
	velocity = Vector2.ZERO
	disabled.emit()
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	if is_disabled:
		if _spin_timer > 0.0:
			_spin_timer -= delta
			rotation += 6.0 * delta
		queue_redraw()
		return
	match mode:
		Mode.FLEE:
			_flee(delta)
		Mode.PURSUE:
			_pursue(delta)
	if shooter:
		_update_shooting(delta)
	queue_redraw()


func _flee(delta: float) -> void:
	if waypoints.is_empty():
		return
	var to := waypoints[_wp_index] - global_position
	if to.length() < 14.0:
		_wp_index = (_wp_index + 1) % waypoints.size()
		to = waypoints[_wp_index] - global_position
	var spd := speed
	if brake_check:
		_update_brake_check(delta)
		if _brake_timer > 0.0:
			spd *= 0.35
	_steer_and_move(to, spd, delta)


func _pursue(delta: float) -> void:
	if not target or target.is_wrecked:
		velocity = Vector2.ZERO
		return
	# Depois de bater, recua um instante — sem isso ficava grudado no
	# jogador causando dano a cada contato.
	var spd := speed
	if _recoil > 0.0:
		_recoil -= delta
		spd *= 0.2
	_steer_and_move(target.global_position - global_position, spd, delta)


## Freada brusca: com o jogador colado atrás, o carro freia de repente pra
## ele bater na traseira (truque de motorista de fuga — a batida machuca o
## jogador também).
func _update_brake_check(delta: float) -> void:
	_brake_cd -= delta
	_brake_timer -= delta
	if _brake_cd > 0.0 or not target:
		return
	var rel := target.global_position - global_position
	var fwd := Vector2.RIGHT.rotated(rotation)
	if rel.length() < 90.0 and fwd.dot(rel.normalized()) < -0.7:
		_brake_timer = 0.6
		_brake_cd = brake_check_cooldown


func _steer_and_move(to: Vector2, spd: float, delta: float) -> void:
	if to.length() < 0.01:
		return
	rotation = lerp_angle(rotation, to.angle(), clampf(8.0 * delta, 0.0, 1.0))
	velocity = to.normalized() * spd
	var pre := velocity
	move_and_slide()
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider()
		if col is PlayerCar:
			col.register_impact(self, maxf(0.0, -(pre - col.velocity).dot(c.get_normal())))
			_recoil = 0.8


func _clear_line_to_target() -> bool:
	var q := PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude = [get_rid()]
	var r := get_world_2d().direct_space_state.intersect_ray(q)
	return not r.is_empty() and r.collider == target


func _update_shooting(delta: float) -> void:
	if not target or target.is_wrecked:
		_aim_timer = -1.0
		return
	var in_range := global_position.distance_to(target.global_position) <= shoot_range
	var can_see := in_range and _clear_line_to_target()
	if _aim_timer >= 0.0:
		if not can_see:
			_aim_timer = -1.0
			_cooldown = 0.6
		else:
			_aim_timer -= delta
			if _aim_timer <= 0.0:
				_aim_timer = -1.0
				_cooldown = fire_cooldown
				fired.emit(global_position, target.global_position, _clear_line_to_target())
	else:
		_cooldown -= delta
		if _cooldown <= 0.0 and can_see:
			_aim_timer = aim_time


func _draw() -> void:
	var half := SIZE * 0.5
	var c := Color(0.35, 0.35, 0.35) if is_disabled else body_color.lerp(Color(0.25, 0.25, 0.25), (1.0 - hp / max_hp) * 0.6)
	if _flash > 0.0:
		c = Color.WHITE
	draw_rect(Rect2(-half, SIZE), c)
	draw_line(Vector2.ZERO, Vector2(20, 0), Color.WHITE, 2.0)
	if _brake_timer > 0.0 and not is_disabled:
		draw_rect(Rect2(Vector2(-half.x - 3, -half.y), Vector2(3, SIZE.y)), Color(1.0, 0.1, 0.1))
	if _aim_timer >= 0.0 and target:
		draw_line(Vector2.ZERO, to_local(target.global_position), Color(1.0, 0.1, 0.1, 0.8), 1.5)
