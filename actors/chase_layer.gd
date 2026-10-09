class_name ChaseLayer
extends Node2D
## Liga o carro do jogador e os carros inimigos numa missão (GDD Seção 8,
## "Risco real nas perseguições") — mesmo papel do `CombatLayer` a pé:
## PIT (freio de mão + contato + alinhado atrás), batida forte que quebra o
## inimigo (`ram_damage`), mira automática por cone (`aim_mode`), suspeito
## que escapa se o jogador ficar longe demais por tempo demais, tiro dos
## passageiros aplicado na lataria, e recomeço da missão quando o carro
## do jogador é destruído ou o suspeito escapa.
##
## Inimigos começam pausados: a missão chama `set_active(true)` quando a
## perseguição começa (senão andam/atiram durante o diálogo).

signal player_wrecked
signal enemy_disabled(car: EnemyCar)
signal suspect_escaped

const SHOT_LINE_TIME := 0.25
const RESTART_DELAY := 1.8
const PIT_RANGE := 70.0
const PIT_ANGLE_DOT := 0.6
const AIM_RANGE := 220.0
const AIM_DOT := 0.92

var player_car: PlayerCar
var enemies: Array[EnemyCar] = []
var active := false

var pit_enabled := false
var ram_damage := 0.0
var ram_impact_threshold := 40.0

var escape_target: EnemyCar
var escape_distance := 380.0
var escape_time := 4.0
var escape_progress := 0.0

## 0 = sem mira; 1 = cone pra frente (atirar no pneu); -1 = cone pra trás.
var aim_mode := 0
var auto_target: EnemyCar

var _lines: Array[Dictionary] = []
var _escaped_sent := false


func setup(car: PlayerCar) -> void:
	player_car = car
	car.bumped.connect(_on_bumped)
	car.wrecked.connect(_on_wrecked)


func add_enemy(car: EnemyCar) -> EnemyCar:
	car.target = player_car
	car.fired.connect(_on_enemy_fired.bind(car))
	car.disabled.connect(_on_enemy_disabled.bind(car))
	car.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	add_child(car)
	enemies.append(car)
	return car


func set_active(on: bool) -> void:
	active = on
	for e in enemies:
		e.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func active_count() -> int:
	var n := 0
	for e in enemies:
		if not e.is_disabled:
			n += 1
	return n


## Dispara no alvo travado pela mira automática. Devolve se acertou.
func fire_auto(damage: float) -> bool:
	if auto_target == null or auto_target.is_disabled:
		return false
	_lines.append({"from": player_car.global_position, "to": auto_target.global_position, "timer": SHOT_LINE_TIME, "enemy": false})
	auto_target.take_damage(damage)
	return true


func restart_mission(delay := RESTART_DELAY) -> void:
	get_tree().create_timer(delay).timeout.connect(_reload)


func _reload() -> void:
	if is_inside_tree():
		get_tree().reload_current_scene()


func _on_bumped(collider: Object, impact: float) -> void:
	if not (collider is EnemyCar) or collider.is_disabled:
		return
	if pit_enabled and InputBridge.is_held("handbrake"):
		var to: Vector2 = collider.global_position - player_car.global_position
		if to.length() <= PIT_RANGE and player_car.forward().dot(to.normalized()) > PIT_ANGLE_DOT:
			collider.spin_out()
			return
	if ram_damage > 0.0 and impact >= ram_impact_threshold:
		collider.take_damage(ram_damage)


func _on_enemy_fired(from: Vector2, to: Vector2, hit: bool, car: EnemyCar) -> void:
	_lines.append({"from": from, "to": to, "timer": SHOT_LINE_TIME, "enemy": true})
	if hit:
		player_car.take_damage(car.shot_damage)


func _on_enemy_disabled(car: EnemyCar) -> void:
	enemy_disabled.emit(car)


func _on_wrecked() -> void:
	for e in enemies:
		e.target = null
	player_wrecked.emit()


func _process(delta: float) -> void:
	for i in range(_lines.size() - 1, -1, -1):
		_lines[i]["timer"] -= delta
		if _lines[i]["timer"] <= 0.0:
			_lines.remove_at(i)
	if active and player_car and not player_car.is_wrecked:
		_update_escape(delta)
		_update_aim()
	else:
		auto_target = null
	queue_redraw()


func _update_escape(delta: float) -> void:
	if escape_target == null or escape_target.is_disabled:
		escape_progress = 0.0
		return
	if player_car.global_position.distance_to(escape_target.global_position) > escape_distance:
		escape_progress += delta / escape_time
	else:
		escape_progress = maxf(0.0, escape_progress - delta / escape_time * 1.5)
	if escape_progress >= 1.0 and not _escaped_sent:
		_escaped_sent = true
		suspect_escaped.emit()


func _update_aim() -> void:
	auto_target = null
	if aim_mode == 0:
		return
	var dir := player_car.forward() * float(aim_mode)
	var best_d := INF
	for e in enemies:
		if e.is_disabled:
			continue
		var to := e.global_position - player_car.global_position
		var d := to.length()
		if d <= AIM_RANGE and d > 0.01 and dir.dot(to / d) >= AIM_DOT and d < best_d:
			best_d = d
			auto_target = e


func _draw() -> void:
	if auto_target and player_car:
		draw_dashed_line(player_car.global_position, auto_target.global_position, Color(1.0, 0.3, 0.3, 0.6), 2.0, 8.0)
	for s in _lines:
		var c := Color(1.0, 0.5, 0.1, 0.9) if s["enemy"] else Color(1.0, 1.0, 0.4, 0.9)
		draw_line(s["from"], s["to"], c, 2.5)
