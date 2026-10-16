extends Node2D
## Sandbox tático — caixas cinzas, sem arte. Controles validados em 8
## rodadas no celular; piloto de combate com risco real aprovado na 2ª
## versão ("ficou muito bom"). Agora é a referência viva dos componentes
## compartilhados: `actors/tactical_player.gd` (jogador), `actors/
## enemy_guard.gd` (guardas) e `actors/combat_layer.gd` (liga os dois,
## barulho, efeitos, recomeço). GDD Seção 8.
##
## Colete no canto esquerdo (aguenta `VEST_HITS`); sem ele um tiro
## derruba, e cair recomeça a cena. Barulho: tiro, sprint, caixa,
## luminária, arrombar rápido. Luminária apagada = guardas enxergam pouco.

const ROOM_SIZE := Vector2(700.0, 420.0)
const ROOM_ORIGIN := Vector2(130.0, 60.0)
const WALL_THICK := 20.0
const DOOR_GAP := 80.0

const DOOR_INTERACT_DIST := 60.0
const PICKUP_DIST := 55.0
const VEST_HITS := 2
const TOAST_TIME := 2.5
const NOISE_CRATE := 380.0
const NOISE_LAMP := 250.0
const NOISE_BREACH_LOUD := 450.0
const NOISE_DOOR_OPEN := 80.0
## Piloto de munição: pouca de propósito, pra o jogador sentir o sistema
## (errar e distrair gastam bala; sem bala, pegar a arma de um guarda).
const MAG_SIZE := 6
const SPARE_AMMO := 6
const DROP_AMMO := 6

var player: TacticalPlayer
var combat: CombatLayer

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
var vest_item: Area2D
var vest_picked := false

var _toast_timer := 0.0

var status_label: Label
var health_label: Label
var breach_btn: Control
var open_btn: Control
var pickup_btn: Control
var fire_btn: Control
var reload_btn: Control


func _ready() -> void:
	_build_room()
	_build_doors()
	_build_objects()
	combat = CombatLayer.new()
	add_child(combat)
	_build_player()
	_build_enemies()
	_build_hud()
	_build_controls()
	combat.set_active(true)


# ---------- construção da cena (caixas cinzas) ----------

func _build_room() -> void:
	var top := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	var rects: Array[Rect2] = []

	rects.append(Rect2(Vector2(top.x, top.y + h - WALL_THICK), Vector2(w, WALL_THICK)))
	rects.append(Rect2(top, Vector2(WALL_THICK, h)))

	var door2_x := top.x + w * 0.18
	rects.append(Rect2(top, Vector2(door2_x - top.x, WALL_THICK)))
	rects.append(Rect2(Vector2(door2_x + DOOR_GAP, top.y), Vector2(top.x + w - (door2_x + DOOR_GAP), WALL_THICK)))

	var gap_start := top.y + h * 0.5 - DOOR_GAP * 0.5
	rects.append(Rect2(Vector2(top.x + w - WALL_THICK, top.y), Vector2(WALL_THICK, gap_start - top.y)))
	rects.append(Rect2(Vector2(top.x + w - WALL_THICK, gap_start + DOOR_GAP), Vector2(WALL_THICK, top.y + h - (gap_start + DOOR_GAP))))

	# Quina solta no meio da sala — cobertura de verdade contra os guardas.
	rects.append(Rect2(top + Vector2(w * 0.42, h * 0.4), Vector2(90, 90)))

	for r in rects:
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
	vest_item = _area_circle(ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y * 0.35), 14.0)

	crate = Area2D.new()
	var c_shape := CollisionShape2D.new()
	var c_rect := RectangleShape2D.new()
	c_rect.size = Vector2(26, 26)
	c_shape.shape = c_rect
	crate.add_child(c_shape)
	crate.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.6, ROOM_SIZE.y * 0.75)
	crate.monitorable = true
	add_child(crate)


func _build_player() -> void:
	player = TacticalPlayer.new()
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 90)
	player.controls_locked = false
	player.can_shoot = true
	player.extra_exclude = [vest_item.get_rid()]
	player.set_ammo(MAG_SIZE, SPARE_AMMO)
	player.dry_fired.connect(_on_dry_fired)
	player.reload_started.connect(func(): _toast("Recarregando... (faz um pouco de barulho)"))
	add_child(player)
	combat.setup(player)
	player.fired.connect(_on_player_fired)
	player.hit_taken.connect(_on_hit_taken)
	combat.player_downed.connect(_on_player_downed)
	combat.drop_ammo = DROP_AMMO
	combat.weapon_picked.connect(func(n): _toast("Pegou a arma do guarda: +%d balas." % n))


## Dois guardas: um vigia a lateral direita (de cima pra baixo), outro a
## faixa de cima (de lado a lado). Os cones não cobrem o canto inicial.
func _build_enemies() -> void:
	var o := ROOM_ORIGIN
	var w := ROOM_SIZE.x
	var h := ROOM_SIZE.y
	combat.add_guard([o + Vector2(w * 0.78, h * 0.3), o + Vector2(w * 0.78, h * 0.75)])
	combat.add_guard([o + Vector2(w * 0.35, h * 0.2), o + Vector2(w * 0.7, h * 0.2)])


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

	# ATIRAR e RECARGA seguem a disposição configurável (ControlLayout),
	# como nas missões. ARROMBAR/ABRIR/PEGAR ficam fixos: aqui aparecem ao
	# mesmo tempo que o ATIRAR, e nas missões dividem o lugar dele.
	fire_btn = _corner_button("shoot", "ATIRAR", 30, 30, 100, 100)
	fire_btn.layout_slot = "acao_principal"
	layer.add_child(fire_btn)

	reload_btn = _corner_button("reload", "RECARGA", 44, 148, 72, 72)
	reload_btn.layout_slot = "acao_secundaria"
	reload_btn.visible = false
	layer.add_child(reload_btn)


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
	if not player.is_down:
		_update_doors()
		_update_vest_pickup()
	reload_btn.visible = player.can_reload() and not player.is_down
	combat.set_dark(not lamp_on)
	_update_hud(delta)
	queue_redraw()


func _update_doors() -> void:
	var near1 := player.position.distance_to(door1_body.position) < DOOR_INTERACT_DIST
	breach_btn.visible = near1 and not door1_open
	if breach_btn.visible and InputBridge.consume_just_released("breach"):
		door1_open = true
		if InputBridge.last_hold_time("breach") > 0.5:
			_toast("Porta arrombada DEVAGAR — silencioso, ninguém ouviu.")
		else:
			combat.noise(door1_body.position, NOISE_BREACH_LOUD)
			_toast("Porta arrombada RÁPIDO — barulho, os guardas vão vir ver.")

	var near2 := player.position.distance_to(door2_body.position) < DOOR_INTERACT_DIST
	open_btn.visible = near2 and not door2_open
	if open_btn.visible and InputBridge.consume_just_pressed("open_door"):
		door2_open = true
		combat.noise(door2_body.position, NOISE_DOOR_OPEN)
		_toast("Porta destrancada aberta.")


func _update_vest_pickup() -> void:
	if vest_picked:
		pickup_btn.visible = false
		return
	var near := player.position.distance_to(vest_item.position) < PICKUP_DIST
	pickup_btn.visible = near
	if near and InputBridge.consume_just_pressed("pickup"):
		vest_picked = true
		player.set_vest(VEST_HITS)
		pickup_btn.visible = false
		_toast("Colete vestido — aguenta %d tiros. Sem ele, um tiro derruba." % VEST_HITS)


func _on_player_fired(collider: Object, _from: Vector2, _to: Vector2) -> void:
	if collider == null:
		_toast("Tiro no vazio.")
	elif collider is EnemyGuard:
		_toast("Guarda abatido.")
	elif collider == target:
		if not target_hit:
			target_hit = true
			player.extra_exclude.append(target.get_rid())
			_toast("Alvo atingido.")
	elif collider == lamp:
		if lamp_on:
			lamp_on = false
			combat.noise(lamp.position, NOISE_LAMP)
			_toast("Luminária apagada — no escuro os guardas enxergam bem menos.")
	elif collider == crate:
		if not crate_broken:
			crate_broken = true
			combat.noise(crate.position, NOISE_CRATE)
			_toast("Caixa estourada — o barulho puxa os guardas pra lá.")
	else:
		_toast("Acertou a parede — o tiro não atravessa.")


func _on_dry_fired() -> void:
	if player.reserve > 0:
		_toast("Pente vazio — recarregando.")
	else:
		_toast("SEM MUNIÇÃO! Pegue a arma de um guarda caído (anel amarelo).")


func _on_hit_taken(vest_left: int) -> void:
	if vest_left > 0:
		_toast("O colete segurou o tiro! Aguenta mais %d." % vest_left)
	else:
		_toast("Colete destruído — o próximo tiro derruba.")


func _on_player_downed() -> void:
	_toast("Mark foi abatido. Recomeçando...")
	combat.restart_mission()


func _toast(msg: String) -> void:
	status_label.text = msg
	_toast_timer = TOAST_TIME


func _update_hud(delta: float) -> void:
	if player.is_down:
		health_label.text = "ABATIDO"
	elif player.vest_hits > 0:
		health_label.text = "Colete: %d/%d" % [player.vest_hp, player.vest_hits]
	else:
		health_label.text = "Sem colete — um tiro derruba"
	if player.uses_ammo() and not player.is_down:
		var ammo := "RECARREGANDO" if player.is_reloading() else "%d/%d" % [player.mag, player.mag_size]
		health_label.text += "\nMunição: %s   Reserva: %d" % [ammo, player.reserve]

	if _toast_timer > 0.0:
		_toast_timer -= delta
		return
	var state := "SPRINT (barulhento)" if player.is_sprinting() else "cauteloso"
	status_label.text = "Estado: %s | Guardas: %d vivos, %d te vendo\nEsquerda move. Direita mira — TOQUE DUAS VEZES no lado direito pra atirar (ou ATIRAR).\nGuardas só veem dentro do cone e não atravessam parede. Sprint e tiro fazem barulho: eles vão investigar.\nApague a luminária (escuro = visão curta), quebre a caixa pra distrair, pegue o colete à esquerda.\nMunição contada: errar e distrair gastam bala. Guarda caído larga a arma — passe por cima pra pegar." % [state, combat.alive_count(), combat.seeing_count()]


func _draw() -> void:
	if not lamp_on:
		draw_rect(Rect2(ROOM_ORIGIN, ROOM_SIZE), Color(0.0, 0.0, 0.05, 0.5))
	if not vest_picked:
		draw_rect(Rect2(vest_item.position - Vector2(12, 14), Vector2(24, 28)), Color(0.25, 0.4, 0.6))
	draw_circle(door1_body.position, 8.0, Color.GREEN if door1_open else Color(0.7, 0.15, 0.15))
	draw_circle(door2_body.position, 8.0, Color.GREEN if door2_open else Color(0.5, 0.5, 0.2))
	draw_circle(target.position, 16.0, Color(0.2, 0.2, 0.2) if target_hit else Color(0.8, 0.2, 0.2))
	draw_circle(lamp.position, 10.0, Color(1.0, 0.95, 0.6) if lamp_on else Color(0.25, 0.25, 0.25))
	draw_rect(Rect2(crate.position - Vector2(13, 13), Vector2(26, 26)), Color(0.3, 0.3, 0.3) if crate_broken else Color(0.55, 0.4, 0.2))
