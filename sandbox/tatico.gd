extends Node2D
## Sandbox tático — caixas cinzas, sem arte. Controles validados em 8
## rodadas no celular (manches desacoplados, ATIRAR sempre visível, raio de
## física real, portas por estado, botões adicionados depois do manche pra
## ganharem o toque). GDD Seção 8.
##
## Piloto de combate com risco real (2ª rodada, retorno do usuário):
## - Guardas são `actors/enemy_guard.gd`: cone de visão fixo, perdem o
##   jogador atrás de parede, ouvem barulho e investigam, enxergam menos
##   no escuro, mostram a mira antes de atirar.
## - Um tiro derruba o Mark, a menos que ele esteja de colete (aguenta
##   `VEST_HITS`). Derrubado = o encontro recomeça.
## - Barulho: tiro, sprint, caixa quebrando, luminária e arrombar rápido
##   geram som; arrombar devagar é silencioso.
## - Mira com suavização exponencial (responde rápido a giro grande, suave
##   no ajuste fino) e toque duplo no manche direito pra atirar.

const ROOM_SIZE := Vector2(700.0, 420.0)
const ROOM_ORIGIN := Vector2(130.0, 60.0)
const WALL_THICK := 20.0
const DOOR_GAP := 80.0

const PLAYER_RADIUS := 14.0
const SPEED_CAUTIOUS := 90.0
const SPEED_SPRINT := 170.0
const SPRINT_CHARGE_TIME := 2.0
const SPRINT_DEFLECT_THRESHOLD := 0.75
const SPRINT_CHARGE_DECAY := 2.0

const FIRE_RANGE := 900.0
const COVER_DISTANCE := 30.0
const DOOR_INTERACT_DIST := 60.0
const PICKUP_DIST := 55.0

const AIM_RESPONSIVENESS := 16.0

const VEST_HITS := 2
const DEATH_RESET_TIME := 1.8
const TOAST_TIME := 2.5
const SHOT_LINE_DURATION := 0.25
const NOISE_RING_TIME := 0.6
const NOISE_GUNSHOT := 550.0
const NOISE_CRATE := 380.0
const NOISE_LAMP := 250.0
const NOISE_SPRINT_STEP := 170.0
const NOISE_BREACH_LOUD := 450.0
const NOISE_DOOR_OPEN := 80.0
const SPRINT_STEP_INTERVAL := 0.35

var player: CharacterBody2D
var player_start: Vector2
var has_vest := false
var vest_hp := 0
var vest_item: Area2D
var vest_picked := false
var _dead := false
var _death_timer := 0.0

var door1_body: StaticBody2D  ## trancada — precisa arrombar
var door1_open := false
var door2_body: StaticBody2D  ## destrancada — só abrir
var door2_open := false

var target: Area2D
var target_hit := false
var lamp: Area2D
var lamp_on := true
var crate: Area2D
var crate_broken := false

var enemies: Array[EnemyGuard] = []

var _aim_end := Vector2.ZERO
var _aim_hit_something := false
var _wall_rects: Array[Rect2] = []
var _sprint_charge := 0.0
var _sprint_step_timer := 0.0
var _in_cover := false
var _peeking := false
var _facing := Vector2.RIGHT

var _shot_lines: Array[Dictionary] = []
var _noise_rings: Array[Dictionary] = []
var _toast_timer := 0.0

var status_label: Label
var health_label: Label
var breach_btn: Control
var open_btn: Control
var pickup_btn: Control
var fire_btn: Control


func _ready() -> void:
	_build_room()
	_build_player()
	_build_doors()
	_build_objects()
	_build_vest()
	_build_enemies()
	_build_hud()
	_build_controls()


# ---------- construção da cena (caixas cinzas) ----------

func _build_room() -> void:
	_wall_rects.clear()
	var top := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y

	_wall_rects.append(Rect2(Vector2(top.x, top.y + h - WALL_THICK), Vector2(w, WALL_THICK)))
	_wall_rects.append(Rect2(top, Vector2(WALL_THICK, h)))

	var door2_x := top.x + w * 0.18
	_wall_rects.append(Rect2(top, Vector2(door2_x - top.x, WALL_THICK)))
	_wall_rects.append(Rect2(Vector2(door2_x + DOOR_GAP, top.y), Vector2(top.x + w - (door2_x + DOOR_GAP), WALL_THICK)))

	var gap_start := top.y + h * 0.5 - DOOR_GAP * 0.5
	_wall_rects.append(Rect2(Vector2(top.x + w - WALL_THICK, top.y), Vector2(WALL_THICK, gap_start - top.y)))
	_wall_rects.append(Rect2(Vector2(top.x + w - WALL_THICK, gap_start + DOOR_GAP), Vector2(WALL_THICK, top.y + h - (gap_start + DOOR_GAP))))

	# Quina solta no meio da sala — cobertura de verdade contra os guardas.
	_wall_rects.append(Rect2(top + Vector2(w * 0.42, h * 0.4), Vector2(90, 90)))

	for r in _wall_rects:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = r.size
		shape.shape = rect_shape
		shape.position = r.size * 0.5
		body.add_child(shape)
		body.position = r.position
		add_child(body)

		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2.ZERO, Vector2(r.size.x, 0), r.size, Vector2(0, r.size.y)])
		poly.color = Color(0.35, 0.35, 0.4)
		poly.position = r.position
		add_child(poly)


func _build_player() -> void:
	player = CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	shape.shape = circle
	player.add_child(shape)
	player_start = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 90)
	player.position = player_start
	add_child(player)


func _build_doors() -> void:
	door1_body = StaticBody2D.new()
	var shape1 := CollisionShape2D.new()
	var rect1 := RectangleShape2D.new()
	rect1.size = Vector2(WALL_THICK, DOOR_GAP)
	shape1.shape = rect1
	door1_body.add_child(shape1)
	var gap_start := ROOM_ORIGIN.y + ROOM_SIZE.y * 0.5 - DOOR_GAP * 0.5
	door1_body.position = Vector2(ROOM_ORIGIN.x + ROOM_SIZE.x - WALL_THICK * 0.5, gap_start + DOOR_GAP * 0.5)
	door1_body.set_collision_layer_value(1, false)
	add_child(door1_body)

	door2_body = StaticBody2D.new()
	var shape2 := CollisionShape2D.new()
	var rect2 := RectangleShape2D.new()
	rect2.size = Vector2(DOOR_GAP, WALL_THICK)
	shape2.shape = rect2
	door2_body.add_child(shape2)
	var door2_x := ROOM_ORIGIN.x + ROOM_SIZE.x * 0.18
	door2_body.position = Vector2(door2_x + DOOR_GAP * 0.5, ROOM_ORIGIN.y + WALL_THICK * 0.5)
	door2_body.set_collision_layer_value(1, false)
	add_child(door2_body)


func _area_circle(pos: Vector2, radius: float) -> Area2D:
	var a := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	a.add_child(shape)
	a.position = pos
	a.monitorable = true
	add_child(a)
	return a


func _build_objects() -> void:
	target = _area_circle(ROOM_ORIGIN + Vector2(ROOM_SIZE.x - 90, 60), 16.0)
	lamp = _area_circle(ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.5, ROOM_SIZE.y - 40), 10.0)

	crate = Area2D.new()
	var c_shape := CollisionShape2D.new()
	var c_rect := RectangleShape2D.new()
	c_rect.size = Vector2(26, 26)
	c_shape.shape = c_rect
	crate.add_child(c_shape)
	crate.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.6, ROOM_SIZE.y * 0.75)
	crate.monitorable = true
	add_child(crate)


func _build_vest() -> void:
	vest_item = _area_circle(ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y * 0.35), 14.0)


## Dois guardas: um vigia a lateral direita (de cima pra baixo), outro a
## faixa de cima (de lado a lado). Os cones não cobrem o canto inicial do
## jogador — dá pra planejar antes de ser visto.
func _build_enemies() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	var routes := [
		[o + Vector2(w * 0.78, h * 0.3), o + Vector2(w * 0.78, h * 0.75)],
		[o + Vector2(w * 0.35, h * 0.2), o + Vector2(w * 0.7, h * 0.2)],
	]
	for route in routes:
		var g := EnemyGuard.new()
		var pts: Array[Vector2] = []
		for p in route:
			pts.append(p)
		g.patrol_points = pts
		g.position = pts[0]
		g.target = player
		g.fired.connect(_on_enemy_fired)
		add_child(g)
		enemies.append(g)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(16, 16)
	status_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(status_label)

	health_label = Label.new()
	health_label.position = Vector2(16, 140)
	health_label.add_theme_font_size_override("font_size", 20)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	layer.add_child(health_label)

	var back := Button.new()
	back.text = "< Menu"
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_top = -60
	back.offset_bottom = -10
	back.offset_left = 16
	back.offset_right = 130
	layer.add_child(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://sandbox/menu.tscn"))


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var left_stick := Control.new()
	left_stick.set_script(load("res://ui/virtual_joystick.gd"))
	left_stick.anchor_left = 0.0
	left_stick.anchor_right = 0.5
	left_stick.anchor_top = 0.0
	left_stick.anchor_bottom = 1.0
	layer.add_child(left_stick)

	var right_stick := Control.new()
	right_stick.set_script(load("res://ui/virtual_joystick.gd"))
	right_stick.right_stick = true
	right_stick.double_tap_action = "shoot"
	right_stick.anchor_left = 0.5
	right_stick.anchor_right = 1.0
	right_stick.anchor_top = 0.0
	right_stick.anchor_bottom = 1.0
	layer.add_child(right_stick)

	# Botões DEPOIS do manche: no Godot quem é adicionado por último recebe
	# o toque primeiro, então os botões visíveis ganham do manche por baixo.
	breach_btn = _corner_button("breach", "ARROMBAR", 130, 30, 110, 110)
	breach_btn.visible = false
	breach_btn.show_hold_progress = true
	layer.add_child(breach_btn)

	open_btn = _corner_button("open_door", "ABRIR", 130, 30, 110, 110)
	open_btn.visible = false
	layer.add_child(open_btn)

	pickup_btn = _corner_button("pickup", "PEGAR\nCOLETE", 130, 30, 110, 110)
	pickup_btn.visible = false
	layer.add_child(pickup_btn)

	fire_btn = _corner_button("shoot", "ATIRAR", 30, 30, 100, 100)
	layer.add_child(fire_btn)


func _corner_button(action: String, label: String, right: float, bottom: float, w: float, h: float) -> Control:
	var btn := Control.new()
	btn.set_script(load("res://ui/contextual_button.gd"))
	btn.action_name = action
	btn.label_text = label
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_right = -right
	btn.offset_left = -right - w
	btn.offset_bottom = -bottom
	btn.offset_top = -bottom - h
	return btn


# ---------- lógica de jogo ----------

func _process(delta: float) -> void:
	if _dead:
		_death_timer -= delta
		if _death_timer <= 0.0:
			_reset_encounter()
	else:
		_move_player(delta)
		_update_facing(delta)
		_update_cover_and_peek()
		_update_doors()
		_update_vest_pickup()
		_update_aim_preview()
		_update_fire()
	for g in enemies:
		g.dark = not lamp_on
	_tick_effects(delta)
	_update_hud(delta)
	queue_redraw()


func _move_player(delta: float) -> void:
	var move := InputBridge.move_vector
	if move.length() >= SPRINT_DEFLECT_THRESHOLD:
		_sprint_charge += delta
	else:
		_sprint_charge = maxf(0.0, _sprint_charge - SPRINT_CHARGE_DECAY * delta)

	var sprinting := _sprint_charge >= SPRINT_CHARGE_TIME
	player.velocity = move * (SPEED_SPRINT if sprinting else SPEED_CAUTIOUS)
	player.move_and_slide()

	if sprinting and move.length() > 0.1:
		_sprint_step_timer -= delta
		if _sprint_step_timer <= 0.0:
			_sprint_step_timer = SPRINT_STEP_INTERVAL
			_emit_noise(player.position, NOISE_SPRINT_STEP)
	else:
		_sprint_step_timer = 0.0


## Suavização exponencial em vez de taxa máxima fixa: a taxa fixa deixava
## giro grande lento ("travado"); aqui a mira cobre a maior parte da
## distância rápido e só suaviza no fim.
func _update_facing(delta: float) -> void:
	if InputBridge.aim_touching and InputBridge.aim_vector.length() > 0.15:
		var t := 1.0 - exp(-AIM_RESPONSIVENESS * delta)
		_facing = Vector2.from_angle(lerp_angle(_facing.angle(), InputBridge.aim_vector.angle(), t))


func _nearest_wall_distance() -> float:
	var best := INF
	for r in _wall_rects:
		var closest := Vector2(
			clampf(player.position.x, r.position.x, r.position.x + r.size.x),
			clampf(player.position.y, r.position.y, r.position.y + r.size.y)
		)
		best = minf(best, player.position.distance_to(closest))
	return best


func _update_cover_and_peek() -> void:
	_in_cover = _nearest_wall_distance() <= COVER_DISTANCE
	var m := InputBridge.move_vector.length()
	_peeking = _in_cover and m > 0.15 and m < 0.6


func _update_doors() -> void:
	var near1 := player.position.distance_to(door1_body.position) < DOOR_INTERACT_DIST
	breach_btn.visible = near1 and not door1_open
	if breach_btn.visible and InputBridge.consume_just_released("breach"):
		var hold := InputBridge.last_hold_time("breach")
		door1_open = true
		if hold > 0.5:
			_toast("Porta arrombada DEVAGAR — silencioso, ninguém ouviu.")
		else:
			_emit_noise(door1_body.position, NOISE_BREACH_LOUD)
			_toast("Porta arrombada RÁPIDO — barulho, os guardas vão vir ver.")

	var near2 := player.position.distance_to(door2_body.position) < DOOR_INTERACT_DIST
	open_btn.visible = near2 and not door2_open
	if open_btn.visible and InputBridge.consume_just_pressed("open_door"):
		door2_open = true
		_emit_noise(door2_body.position, NOISE_DOOR_OPEN)
		_toast("Porta destrancada aberta.")


func _update_vest_pickup() -> void:
	if vest_picked:
		pickup_btn.visible = false
		return
	var near := player.position.distance_to(vest_item.position) < PICKUP_DIST
	pickup_btn.visible = near
	if near and InputBridge.consume_just_pressed("pickup"):
		vest_picked = true
		has_vest = true
		vest_hp = VEST_HITS
		pickup_btn.visible = false
		_toast("Colete vestido — aguenta %d tiros. Sem ele, um tiro derruba." % VEST_HITS)


func _fire_exclude() -> Array[RID]:
	var ex: Array[RID] = [player.get_rid(), vest_item.get_rid()]
	if target_hit:
		ex.append(target.get_rid())
	return ex


func _cast_player_ray() -> Dictionary:
	var start := player.position + _facing * (PLAYER_RADIUS + 2.0)
	var query := PhysicsRayQueryParameters2D.create(start, start + _facing * FIRE_RANGE)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = _fire_exclude()
	return get_world_2d().direct_space_state.intersect_ray(query)


func _update_aim_preview() -> void:
	var result := _cast_player_ray()
	if result.is_empty():
		_aim_end = player.position + _facing * FIRE_RANGE
		_aim_hit_something = false
	else:
		_aim_end = result.position
		_aim_hit_something = true


func _update_fire() -> void:
	if not InputBridge.consume_just_pressed("shoot"):
		return

	var result := _cast_player_ray()
	var end: Vector2 = result.position if not result.is_empty() else player.position + _facing * FIRE_RANGE
	_shot_lines.append({"from": player.position, "to": end, "timer": SHOT_LINE_DURATION, "enemy": false})
	# Barulho do tiro sai ANTES do impacto: se o tiro quebrar a caixa, o
	# barulho da caixa é o mais recente e puxa os guardas pra lá (distração).
	_emit_noise(player.position, NOISE_GUNSHOT)

	if result.is_empty():
		_toast("Tiro no vazio.")
		return

	var collider = result.collider
	if collider is EnemyGuard:
		if not collider.is_dead():
			collider.take_hit()
			_toast("Guarda abatido.")
	elif collider == target:
		if not target_hit:
			target_hit = true
			_toast("Alvo atingido.")
	elif collider == lamp:
		if lamp_on:
			lamp_on = false
			_emit_noise(lamp.position, NOISE_LAMP)
			_toast("Luminária apagada — no escuro os guardas enxergam bem menos.")
	elif collider == crate:
		if not crate_broken:
			crate_broken = true
			_emit_noise(crate.position, NOISE_CRATE)
			_toast("Caixa estourada — o barulho puxa os guardas pra lá.")
	else:
		_toast("Acertou a parede — o tiro não atravessa.")


func _on_enemy_fired(from: Vector2, to: Vector2, hit: bool) -> void:
	_shot_lines.append({"from": from, "to": to, "timer": SHOT_LINE_DURATION, "enemy": true})
	_emit_noise(from, NOISE_GUNSHOT)
	if hit and not _dead:
		_on_player_hit()


func _on_player_hit() -> void:
	if vest_hp > 0:
		vest_hp -= 1
		if vest_hp > 0:
			_toast("O colete segurou o tiro! Aguenta mais %d." % vest_hp)
		else:
			_toast("Colete destruído — o próximo tiro derruba.")
		return
	_dead = true
	_death_timer = DEATH_RESET_TIME
	for g in enemies:
		g.target = null
	_toast("Mark foi abatido. Recomeçando o encontro...")


func _reset_encounter() -> void:
	_dead = false
	player.position = player_start
	player.velocity = Vector2.ZERO
	_facing = Vector2.RIGHT
	_sprint_charge = 0.0
	has_vest = false
	vest_hp = 0
	vest_picked = false
	lamp_on = true
	crate_broken = false
	target_hit = false
	door1_open = false
	door2_open = false
	_shot_lines.clear()
	_noise_rings.clear()
	for g in enemies:
		g.target = player
		g.reset()
	_toast("Encontro reiniciado.")


func _emit_noise(pos: Vector2, radius: float) -> void:
	_noise_rings.append({"pos": pos, "radius": radius, "timer": NOISE_RING_TIME})
	get_tree().call_group("enemies", "hear_noise", pos, radius)


func _tick_effects(delta: float) -> void:
	for i in range(_shot_lines.size() - 1, -1, -1):
		_shot_lines[i]["timer"] -= delta
		if _shot_lines[i]["timer"] <= 0.0:
			_shot_lines.remove_at(i)
	for i in range(_noise_rings.size() - 1, -1, -1):
		_noise_rings[i]["timer"] -= delta
		if _noise_rings[i]["timer"] <= 0.0:
			_noise_rings.remove_at(i)


func _toast(msg: String) -> void:
	status_label.text = msg
	_toast_timer = TOAST_TIME


func _update_hud(delta: float) -> void:
	if _dead:
		health_label.text = "ABATIDO"
	elif has_vest:
		health_label.text = "Colete: %d/%d" % [vest_hp, VEST_HITS]
	else:
		health_label.text = "Sem colete — um tiro derruba"

	if _toast_timer > 0.0:
		_toast_timer -= delta
		return

	var state := "cauteloso"
	if _sprint_charge >= SPRINT_CHARGE_TIME:
		state = "SPRINT (barulhento)"
	elif _peeking:
		state = "espiando"
	elif _in_cover:
		state = "em cobertura"
	var alive := 0
	var seeing := 0
	for g in enemies:
		if not g.is_dead():
			alive += 1
			if g.state == EnemyGuard.State.COMBAT:
				seeing += 1
	status_label.text = "Estado: %s | Guardas: %d vivos, %d te vendo\nEsquerda move. Direita mira — TOQUE DUAS VEZES no lado direito pra atirar (ou ATIRAR).\nGuardas só veem dentro do cone e não atravessam parede. Sprint e tiro fazem barulho: eles vão investigar.\nApague a luminária (escuro = visão curta), quebre a caixa pra distrair, pegue o colete à esquerda." % [state, alive, seeing]


func _draw() -> void:
	if not lamp_on:
		draw_rect(Rect2(ROOM_ORIGIN, ROOM_SIZE), Color(0.0, 0.0, 0.05, 0.5))

	for n in _noise_rings:
		var frac: float = 1.0 - n["timer"] / NOISE_RING_TIME
		draw_arc(n["pos"], n["radius"] * frac, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.35 * (1.0 - frac)), 2.0)

	if vest_item and not vest_picked:
		draw_rect(Rect2(vest_item.position - Vector2(12, 14), Vector2(24, 28)), Color(0.25, 0.4, 0.6))

	if player:
		var color := Color(0.9, 0.3, 0.3)
		if _dead:
			color = Color(0.3, 0.1, 0.1)
		elif _in_cover:
			color = Color(0.3, 0.6, 0.9)
		if _peeking and not _dead:
			color = Color(0.9, 0.8, 0.2)
		draw_circle(player.position, PLAYER_RADIUS, color)
		if has_vest and vest_hp > 0:
			draw_arc(player.position, PLAYER_RADIUS + 3.0, 0.0, TAU, 24, Color(0.4, 0.7, 1.0), 3.0)

		if not _dead:
			var aim_color := Color(0.3, 1.0, 0.4, 0.8) if _aim_hit_something else Color(1.0, 1.0, 1.0, 0.35)
			draw_dashed_line(player.position, _aim_end, aim_color, 2.0, 10.0)
			draw_circle(_aim_end, 5.0, aim_color)

		if _sprint_charge > 0.05 and _sprint_charge < SPRINT_CHARGE_TIME:
			var sfrac := _sprint_charge / SPRINT_CHARGE_TIME
			draw_arc(player.position, PLAYER_RADIUS + 7.0, -PI * 0.5, -PI * 0.5 + TAU * sfrac, 24, Color.YELLOW, 3.0)

	for s in _shot_lines:
		var c := Color(1.0, 0.5, 0.1, 0.9) if s["enemy"] else Color(1.0, 1.0, 0.4, 0.9)
		draw_line(s["from"], s["to"], c, 2.5)

	if door1_body:
		draw_circle(door1_body.position, 8.0, Color.GREEN if door1_open else Color(0.7, 0.15, 0.15))
	if door2_body:
		draw_circle(door2_body.position, 8.0, Color.GREEN if door2_open else Color(0.5, 0.5, 0.2))

	if target:
		draw_circle(target.position, 16.0, Color(0.2, 0.2, 0.2) if target_hit else Color(0.8, 0.2, 0.2))
	if lamp:
		draw_circle(lamp.position, 10.0, Color(1.0, 0.95, 0.6) if lamp_on else Color(0.25, 0.25, 0.25))
	if crate:
		var crate_color := Color(0.3, 0.3, 0.3) if crate_broken else Color(0.55, 0.4, 0.2)
		draw_rect(Rect2(crate.position - Vector2(13, 13), Vector2(26, 26)), crate_color)
