class_name EnemyGuard
extends CharacterBody2D
## Guarda inimigo reutilizável — primeira peça do componente de combate
## compartilhado (GDD Seção 8, "Risco e consequência no combate tático").
## Visão em cone fixo, perde o jogador atrás de parede, ouve barulho e vai
## investigar, enxerga menos no escuro, e mostra a mira antes de atirar.

signal fired(from: Vector2, to: Vector2, hit: bool)
signal died

enum State { PATROL, INVESTIGATE, COMBAT, SEARCH, DEAD }

const RADIUS := 14.0

var target: Node2D
var patrol_points: Array[Vector2] = []
var dark := false

var vision_range_lit := 280.0
var vision_range_dark := 110.0
var vision_half_angle := deg_to_rad(35.0)
var combat_angle_mult := 1.6
var patrol_speed := 45.0
var investigate_speed := 75.0
var turn_speed := 4.0
var detect_time := 0.6
var aim_time := 0.7
var fire_cooldown := 1.0
var lose_sight_time := 0.8
var look_around_time := 3.5
var wait_at_point := 1.0

var state := State.PATROL
var facing := Vector2.RIGHT
var detection := 0.0
var last_known := Vector2.ZERO

var _shape: CollisionShape2D
var _patrol_index := 0
var _wait_timer := 0.0
var _investigate_pos := Vector2.ZERO
var _look_timer := 0.0
var _stuck_timer := 0.0
var _unseen_timer := 0.0
var _aim_timer := -1.0
var _cooldown := 0.0
var _sees_target := false
var _spawn_pos := Vector2.ZERO
var _spawn_facing := Vector2.RIGHT


func _ready() -> void:
	add_to_group("enemies")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	_shape.shape = circle
	add_child(_shape)
	if patrol_points.size() > 1:
		facing = (patrol_points[1] - patrol_points[0]).normalized()
		_patrol_index = 1
	_spawn_pos = position
	_spawn_facing = facing


func reset() -> void:
	position = _spawn_pos
	facing = _spawn_facing
	velocity = Vector2.ZERO
	state = State.PATROL
	detection = 0.0
	_patrol_index = 1 if patrol_points.size() > 1 else 0
	_wait_timer = 0.0
	_aim_timer = -1.0
	_cooldown = 0.0
	_unseen_timer = 0.0
	_shape.set_deferred("disabled", false)
	queue_redraw()


func is_dead() -> bool:
	return state == State.DEAD


func take_hit() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	_aim_timer = -1.0
	_shape.set_deferred("disabled", true)
	died.emit()
	queue_redraw()


## Som atravessa parede, mas abafado: com parede no caminho o raio de
## alcance cai pra 60%. Em combate o guarda ignora barulho — já sabe onde
## o jogador está.
func hear_noise(pos: Vector2, radius: float) -> void:
	if state == State.DEAD or state == State.COMBAT:
		return
	var r := _ray(pos)
	var muffled: bool = not r.is_empty() and r.collider is StaticBody2D
	var effective := radius * (0.6 if muffled else 1.0)
	if global_position.distance_to(pos) > effective:
		return
	_start_investigate(pos, State.INVESTIGATE)


func vision_range() -> float:
	return vision_range_dark if dark else vision_range_lit


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_sees_target = _can_see_target()
	_update_detection(delta)
	match state:
		State.PATROL:
			_do_patrol(delta)
		State.INVESTIGATE, State.SEARCH:
			_do_investigate(delta)
		State.COMBAT:
			_do_combat(delta)
	queue_redraw()


func _ray(to_point: Vector2) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(global_position, to_point)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(q)


func _can_see_target() -> bool:
	if not target:
		return false
	var to := target.global_position - global_position
	var dist := to.length()
	if dist < 1.0:
		return true
	if dist > vision_range():
		return false
	var half := vision_half_angle * (combat_angle_mult if state == State.COMBAT else 1.0)
	if absf(facing.angle_to(to)) > half:
		return false
	var r := _ray(target.global_position)
	return not r.is_empty() and r.collider == target


func _update_detection(delta: float) -> void:
	if state == State.COMBAT:
		return
	if _sees_target:
		last_known = target.global_position
		var closeness := 1.0 - clampf(global_position.distance_to(last_known) / vision_range(), 0.0, 1.0)
		detection += (0.35 + 0.65 * closeness) / detect_time * delta
		if detection >= 1.0:
			_enter_combat()
	else:
		if detection > 0.4 and state == State.PATROL:
			_start_investigate(last_known, State.INVESTIGATE)
		detection = maxf(0.0, detection - 0.5 * delta)


func _enter_combat() -> void:
	state = State.COMBAT
	detection = 1.0
	_aim_timer = -1.0
	_cooldown = 0.3
	_unseen_timer = 0.0


func _start_investigate(pos: Vector2, new_state: State) -> void:
	_investigate_pos = pos
	_look_timer = 0.0
	_stuck_timer = 0.0
	state = new_state


func _do_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return
	if _sees_target and detection > 0.0:
		_turn_toward(last_known - global_position, delta)
		return
	if _wait_timer > 0.0:
		_wait_timer -= delta
		_turn_toward(patrol_points[_patrol_index] - global_position, delta)
		return
	var dest := patrol_points[_patrol_index]
	if global_position.distance_to(dest) < 6.0:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		_wait_timer = wait_at_point
		return
	_move_toward_point(dest, patrol_speed, delta)


func _do_investigate(delta: float) -> void:
	if _sees_target and detection > 0.0:
		_turn_toward(last_known - global_position, delta)
		return
	if global_position.distance_to(_investigate_pos) > 12.0 and _stuck_timer < 1.5:
		var before := global_position
		_move_toward_point(_investigate_pos, investigate_speed, delta)
		if global_position.distance_to(before) < investigate_speed * delta * 0.3:
			_stuck_timer += delta
		else:
			_stuck_timer = 0.0
		return
	_look_timer += delta
	facing = facing.rotated(cos(_look_timer * 1.5) * 1.6 * delta)
	if _look_timer >= look_around_time:
		state = State.PATROL
		detection = 0.0
		_patrol_index = _nearest_patrol_index()


func _do_combat(delta: float) -> void:
	if _sees_target:
		last_known = target.global_position
		_unseen_timer = 0.0
	else:
		_unseen_timer += delta
	_turn_toward(last_known - global_position, delta)

	if _aim_timer >= 0.0:
		if not _sees_target:
			_aim_timer = -1.0
			_cooldown = 0.4
		else:
			_aim_timer -= delta
			if _aim_timer <= 0.0:
				_fire()
				_aim_timer = -1.0
				_cooldown = fire_cooldown
	else:
		_cooldown -= delta
		if _cooldown <= 0.0 and _sees_target:
			_aim_timer = aim_time

	if _unseen_timer >= lose_sight_time:
		detection = 0.5
		_start_investigate(last_known, State.SEARCH)


func _fire() -> void:
	var r := _ray(target.global_position)
	var hit: bool = not r.is_empty() and r.collider == target
	var end: Vector2 = r.position if not r.is_empty() else target.global_position
	fired.emit(global_position, end, hit)


func _move_toward_point(dest: Vector2, speed: float, delta: float) -> void:
	var dir := (dest - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	_turn_toward(dir, delta)


func _turn_toward(dir: Vector2, delta: float) -> void:
	if dir.length() < 0.01:
		return
	var diff := wrapf(dir.angle() - facing.angle(), -PI, PI)
	var step := turn_speed * delta
	facing = facing.rotated(clampf(diff, -step, step))


func _nearest_patrol_index() -> int:
	var best := 0
	var best_d := INF
	for i in patrol_points.size():
		var d := global_position.distance_to(patrol_points[i])
		if d < best_d:
			best_d = d
			best = i
	return best


func _draw() -> void:
	if state == State.DEAD:
		draw_circle(Vector2.ZERO, RADIUS, Color(0.2, 0.2, 0.2))
		return

	var half := vision_half_angle * (combat_angle_mult if state == State.COMBAT else 1.0)
	var rng := vision_range()
	var pts := PackedVector2Array([Vector2.ZERO])
	var steps := 12
	for i in steps + 1:
		var a := facing.angle() - half + (2.0 * half) * i / steps
		pts.append(Vector2.RIGHT.rotated(a) * rng)
	var cone_color := Color(1.0, 1.0, 1.0, 0.08)
	if state == State.COMBAT:
		cone_color = Color(1.0, 0.2, 0.2, 0.18)
	elif detection > 0.0 or state != State.PATROL:
		cone_color = Color(1.0, 0.8, 0.2, 0.15)
	draw_colored_polygon(pts, cone_color)

	var body_color := Color(0.85, 0.25, 0.25) if state == State.COMBAT else Color(0.6, 0.5, 0.2)
	draw_circle(Vector2.ZERO, RADIUS, body_color)
	draw_line(Vector2.ZERO, facing * (RADIUS + 10.0), Color.WHITE, 2.0)

	if _aim_timer >= 0.0 and target:
		draw_line(Vector2.ZERO, target.global_position - global_position, Color(1.0, 0.1, 0.1, 0.8), 1.5)

	var icon := ""
	if state == State.COMBAT:
		icon = "!"
	elif state == State.INVESTIGATE or state == State.SEARCH or detection > 0.0:
		icon = "?"
	if icon != "":
		draw_string(ThemeDB.fallback_font, Vector2(-5, -RADIUS - 10), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.9, 0.3))
	if detection > 0.0 and state != State.COMBAT:
		draw_rect(Rect2(Vector2(-14, -RADIUS - 6), Vector2(28.0 * clampf(detection, 0.0, 1.0), 3)), Color(1.0, 0.85, 0.2))
