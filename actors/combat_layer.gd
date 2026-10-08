class_name CombatLayer
extends Node2D
## Liga jogador tático e guardas numa missão (GDD Seção 8, "Risco e
## consequência no combate tático"): cria os guardas, aplica no jogador o
## tiro que acerta, espalha barulho pros guardas, desenha anéis de som e
## linhas de tiro, e recomeça a missão do início quando o Mark cai
## (decisão do usuário; o diálogo repetido se pula com "Pular >>").
##
## Guardas começam pausados: a missão chama `set_active(true)` quando o
## combate começa — senão eles patrulham/atiram durante o diálogo.

signal player_downed
signal all_guards_down

const NOISE_RING_TIME := 0.6
const SHOT_LINE_TIME := 0.25
const RESTART_DELAY := 1.8

var player: TacticalPlayer
var guards: Array[EnemyGuard] = []
var active := false

var _rings: Array[Dictionary] = []
var _lines: Array[Dictionary] = []
var _all_down_sent := false


func setup(p: TacticalPlayer) -> void:
	player = p
	p.combat = self
	p.downed.connect(_on_player_downed)


## `points`: rota de patrulha (1 ponto = guarda parado). `look` só vale
## pra guarda parado — pra onde ele olha.
func add_guard(points: Array[Vector2], look := Vector2.ZERO) -> EnemyGuard:
	var g := EnemyGuard.new()
	g.patrol_points = points
	g.position = points[0]
	if look != Vector2.ZERO:
		g.facing = look.normalized()
	g.target = player
	g.fired.connect(_on_guard_fired)
	g.died.connect(_on_guard_died)
	g.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	add_child(g)
	guards.append(g)
	return g


func set_active(on: bool) -> void:
	active = on
	for g in guards:
		g.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func set_dark(on: bool) -> void:
	for g in guards:
		g.dark = on


func alive_count() -> int:
	var n := 0
	for g in guards:
		if not g.is_dead():
			n += 1
	return n


func seeing_count() -> int:
	var n := 0
	for g in guards:
		if not g.is_dead() and g.state == EnemyGuard.State.COMBAT:
			n += 1
	return n


func noise(pos: Vector2, radius: float) -> void:
	_rings.append({"pos": pos, "radius": radius, "timer": NOISE_RING_TIME})
	get_tree().call_group("enemies", "hear_noise", pos, radius)


func shot_line(from: Vector2, to: Vector2, enemy: bool) -> void:
	_lines.append({"from": from, "to": to, "timer": SHOT_LINE_TIME, "enemy": enemy})


func restart_mission(delay := RESTART_DELAY) -> void:
	get_tree().create_timer(delay).timeout.connect(_reload)


func _reload() -> void:
	if is_inside_tree():
		get_tree().reload_current_scene()


func _on_guard_fired(from: Vector2, to: Vector2, hit: bool) -> void:
	shot_line(from, to, true)
	noise(from, TacticalPlayer.NOISE_GUNSHOT)
	if hit and player:
		player.take_shot()


func _on_guard_died() -> void:
	if not _all_down_sent and alive_count() == 0:
		_all_down_sent = true
		all_guards_down.emit()


func _on_player_downed() -> void:
	for g in guards:
		g.target = null
	player_downed.emit()


func _process(delta: float) -> void:
	for arr in [_rings, _lines]:
		for i in range(arr.size() - 1, -1, -1):
			arr[i]["timer"] -= delta
			if arr[i]["timer"] <= 0.0:
				arr.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for n in _rings:
		var frac: float = 1.0 - n["timer"] / NOISE_RING_TIME
		draw_arc(n["pos"], n["radius"] * frac, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.35 * (1.0 - frac)), 2.0)
	for s in _lines:
		var c := Color(1.0, 0.5, 0.1, 0.9) if s["enemy"] else Color(1.0, 1.0, 0.4, 0.9)
		draw_line(s["from"], s["to"], c, 2.5)
