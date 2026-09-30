extends Node2D
## Sandbox tático — caixas cinzas, sem arte. Revisado após o 7º teste no
## celular:
## - Manche direito preso a uma origem, mira suavizada, cobrindo a
##   metade direita INTEIRA da tela (a faixa reservada pros botões criava
##   área morta quando eles estavam invisíveis). Botões são adicionados
##   DEPOIS do manche na árvore — no Godot quem é adicionado por último
##   recebe o toque primeiro, então são os botões que ganham a disputa
##   quando visíveis, não o manche por baixo (rodada 6 tinha isso
##   invertido, o que fazia nenhum botão responder).
## - Botão "ATIRAR" continua sempre visível/disponível, e atirar continua
##   um raio de física de verdade: pode acertar o alvo, uma parede
##   (bloqueia), ou objetos do cenário (luminária, caixa) — estratégia
##   tipo Police Stories.
## - Duas portas: uma trancada (Arrombar) e uma destrancada (Abrir) —
##   o conjunto de ações muda conforme o estado do objeto.
## GDD Seção 8.

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

const FIRE_RANGE := 900.0  ## bem maior que a sala — na prática "até bater em algo"
const COVER_DISTANCE := 30.0
const DOOR_INTERACT_DIST := 60.0

const FACING_TURN_SPEED_AIMING := 9.0   ## rad/s enquanto o manche direito está sendo arrastado — voltou de 6 pra 9 depois que manche/movimento foram desacoplados

var player: CharacterBody2D
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

# Preview da mira: raio calculado todo frame (não só ao atirar), pra
# mostrar exatamente onde o tiro vai bater — sem isso, a direção do tiro
# era difícil de entender só pela linha curta de direção do personagem.
var _aim_end := Vector2.ZERO
var _aim_hit_something := false

var _wall_rects: Array[Rect2] = []
var _sprint_charge := 0.0
var _in_cover := false
var _peeking := false
var _facing := Vector2.RIGHT

var status_label: Label
var breach_btn: Control
var open_btn: Control
var fire_btn: Control


func _ready() -> void:
	_build_room()
	_build_player()
	_build_doors()
	_build_objects()
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

	# Parede de cima com um vão = porta 2 (destrancada), perto do canto esquerdo.
	var door2_x := top.x + w * 0.18
	_wall_rects.append(Rect2(top, Vector2(door2_x - top.x, WALL_THICK)))
	_wall_rects.append(Rect2(Vector2(door2_x + DOOR_GAP, top.y), Vector2(top.x + w - (door2_x + DOOR_GAP), WALL_THICK)))

	# Parede da direita com um vão = porta 1 (trancada).
	var gap_start := top.y + h * 0.5 - DOOR_GAP * 0.5
	_wall_rects.append(Rect2(Vector2(top.x + w - WALL_THICK, top.y), Vector2(WALL_THICK, gap_start - top.y)))
	_wall_rects.append(Rect2(Vector2(top.x + w - WALL_THICK, gap_start + DOOR_GAP), Vector2(WALL_THICK, top.y + h - (gap_start + DOOR_GAP))))

	# Quina solta no meio da sala pra testar espiar/cobertura.
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
	player.position = ROOM_ORIGIN + Vector2(60, ROOM_SIZE.y - 90)
	add_child(player)
	# O jogador é desenhado pelo _draw() da raiz da cena (ver final do arquivo).


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


func _build_objects() -> void:
	target = Area2D.new()
	var t_shape := CollisionShape2D.new()
	var t_circle := CircleShape2D.new()
	t_circle.radius = 16.0
	t_shape.shape = t_circle
	target.add_child(t_shape)
	target.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x - 90, 60)
	target.monitorable = true
	add_child(target)

	lamp = Area2D.new()
	var l_shape := CollisionShape2D.new()
	var l_circle := CircleShape2D.new()
	l_circle.radius = 10.0
	l_shape.shape = l_circle
	lamp.add_child(l_shape)
	lamp.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.5, ROOM_SIZE.y - 40)
	lamp.monitorable = true
	add_child(lamp)

	crate = Area2D.new()
	var c_shape := CollisionShape2D.new()
	var c_rect := RectangleShape2D.new()
	c_rect.size = Vector2(26, 26)
	c_shape.shape = c_rect
	crate.add_child(c_shape)
	crate.position = ROOM_ORIGIN + Vector2(ROOM_SIZE.x * 0.6, ROOM_SIZE.y * 0.75)
	crate.monitorable = true
	add_child(crate)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(16, 16)
	status_label.add_theme_font_size_override("font_size", 17)
	layer.add_child(status_label)

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

	# Manche esquerdo: metade esquerda inteira da tela (movimento).
	var left_stick := Control.new()
	left_stick.set_script(load("res://ui/virtual_joystick.gd"))
	left_stick.anchor_left = 0.0
	left_stick.anchor_right = 0.5
	left_stick.anchor_top = 0.0
	left_stick.anchor_bottom = 1.0
	layer.add_child(left_stick)

	# Manche direito (mira): preso a uma origem, cobre a metade direita
	# INTEIRA da tela (sem "reservar" faixa pros botões — isso criava uma
	# área morta permanente quando os botões estavam invisíveis, que era
	# a maior parte do tempo).
	var right_stick := Control.new()
	right_stick.set_script(load("res://ui/virtual_joystick.gd"))
	right_stick.right_stick = true
	right_stick.anchor_left = 0.5
	right_stick.anchor_right = 1.0
	right_stick.anchor_top = 0.0
	right_stick.anchor_bottom = 1.0
	layer.add_child(right_stick)

	# Botões DEPOIS do manche: no Godot, quem é adicionado por último na
	# árvore recebe o toque primeiro (o oposto do que eu tinha assumido
	# antes — corrigido aqui). Assim os botões, quando visíveis, ganham a
	# disputa pelo toque contra o manche que está por baixo cobrindo a
	# mesma área.
	breach_btn = _corner_button("breach", "ARROMBAR", 130, 30, 110, 110)
	breach_btn.visible = false
	breach_btn.show_hold_progress = true
	layer.add_child(breach_btn)

	open_btn = _corner_button("open_door", "ABRIR", 130, 30, 110, 110)
	open_btn.visible = false
	layer.add_child(open_btn)

	# Atirar: sempre visível, sempre no mesmo lugar — estilo COD Mobile/Free Fire.
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
	_move_player(delta)
	_update_facing(delta)
	_update_cover_and_peek()
	_update_doors()
	_update_aim_preview()
	_update_fire()
	_update_hud()
	queue_redraw()


func _move_player(delta: float) -> void:
	var move := InputBridge.move_vector
	var deflect := move.length()

	if deflect >= SPRINT_DEFLECT_THRESHOLD:
		_sprint_charge += delta
	else:
		_sprint_charge = max(0.0, _sprint_charge - SPRINT_CHARGE_DECAY * delta)

	var sprinting := _sprint_charge >= SPRINT_CHARGE_TIME
	var speed := SPEED_SPRINT if sprinting else SPEED_CAUTIOUS

	player.velocity = move * speed
	player.move_and_slide()


func _update_facing(delta: float) -> void:
	# Manches totalmente desacoplados: esquerdo só move, direito é o
	# único jeito de mudar pra onde o personagem olha. Antes, sem tocar
	# o manche direito, a mira "seguia" a direção de movimento — parecia
	# uma boa ideia isolada, mas em gameplay de verdade (Fase 2) isso
	# deixava tudo travado (girar sem querer só de andar). Agora, sem
	# tocar o manche direito, a mira simplesmente congela onde estava.
	if InputBridge.aim_touching and InputBridge.aim_vector.length() > 0.15:
		var target_dir := InputBridge.aim_vector.normalized()
		var diff := wrapf(target_dir.angle() - _facing.angle(), -PI, PI)
		var max_step := FACING_TURN_SPEED_AIMING * delta
		_facing = _facing.rotated(clamp(diff, -max_step, max_step))


func _nearest_wall_distance() -> float:
	var best := INF
	for r in _wall_rects:
		var closest := Vector2(
			clamp(player.position.x, r.position.x, r.position.x + r.size.x),
			clamp(player.position.y, r.position.y, r.position.y + r.size.y)
		)
		best = min(best, player.position.distance_to(closest))
	return best


func _update_cover_and_peek() -> void:
	var dist := _nearest_wall_distance()
	_in_cover = dist <= COVER_DISTANCE
	_peeking = _in_cover and InputBridge.move_vector.length() > 0.15 and InputBridge.move_vector.length() < 0.6


func _update_doors() -> void:
	var near1 := player.position.distance_to(door1_body.position) < DOOR_INTERACT_DIST
	breach_btn.visible = near1 and not door1_open
	if breach_btn.visible and InputBridge.consume_just_released("breach"):
		var hold := InputBridge.last_hold_time("breach")
		door1_open = true
		status_label.text = ("Porta TRANCADA arrombada DEVAGAR (silencioso) — %.2fs" % hold) if hold > 0.5 else ("Porta TRANCADA arrombada RÁPIDO (barulhento) — %.2fs" % hold)

	var near2 := player.position.distance_to(door2_body.position) < DOOR_INTERACT_DIST
	open_btn.visible = near2 and not door2_open
	if open_btn.visible and InputBridge.consume_just_pressed("open_door"):
		door2_open = true
		status_label.text = "Porta DESTRANCADA aberta normalmente — sem precisar arrombar."


func _fire_exclude() -> Array[RID]:
	# Alvo já abatido não deveria continuar bloqueando o raio — sem isso,
	# a mira "parava" nele pra sempre mesmo depois de neutralizado.
	var ex: Array[RID] = [player.get_rid()]
	if target_hit:
		ex.append(target.get_rid())
	return ex


func _update_aim_preview() -> void:
	var space_state := get_world_2d().direct_space_state
	var start := player.position + _facing * (PLAYER_RADIUS + 2.0)
	var query := PhysicsRayQueryParameters2D.create(start, start + _facing * FIRE_RANGE)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = _fire_exclude()
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		_aim_end = start + _facing * FIRE_RANGE
		_aim_hit_something = false
	else:
		_aim_end = result.position
		_aim_hit_something = true


func _update_fire() -> void:
	if not InputBridge.consume_just_pressed("shoot"):
		return

	var space_state := get_world_2d().direct_space_state
	# Começa um pouco à frente do corpo do próprio jogador (senão o raio
	# nasceria dentro da própria colisão e "acertaria" o personagem antes
	# de qualquer outra coisa) e exclui o jogador por garantia extra.
	var start := player.position + _facing * (PLAYER_RADIUS + 2.0)
	var query := PhysicsRayQueryParameters2D.create(start, start + _facing * FIRE_RANGE)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = _fire_exclude()
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		status_label.text = "Tiro no vazio — não acertou nada."
		return

	var collider = result.collider
	if collider == target:
		if not target_hit:
			target_hit = true
			status_label.text = "ALVO ATINGIDO."
	elif collider == lamp:
		lamp_on = not lamp_on
		status_label.text = "Luminária desligada — escureceu a sala (uso tático)." if not lamp_on else "Luminária ligada de novo."
	elif collider == crate:
		if not crate_broken:
			crate_broken = true
			status_label.text = "Caixa estourada — isso faria barulho e chamaria atenção."
	else:
		status_label.text = "Acertou a parede — o tiro não atravessa."


func _update_hud() -> void:
	if status_label.text != "" and not status_label.text.begins_with("Estado:"):
		return
	var state := "cauteloso"
	if _sprint_charge >= SPRINT_CHARGE_TIME:
		state = "SPRINT (barulhento)"
	elif _peeking:
		state = "espiando"
	elif _in_cover:
		state = "em cobertura"
	status_label.text = "Estado: %s\nEsquerda SÓ move. Direita SÓ mira (segure pra apontar; solte e a mira congela onde estava, não segue mais o movimento).\nATIRAR sempre disponível — acerta o que estiver na mira: parede, alvo, luminária, caixa.\nPorta de cima é destrancada (ABRIR); porta da direita é trancada — segure ARROMBAR até o anel ficar AZUL pra entrar em silêncio; solte antes disso pra entrar com força." % state


func _draw() -> void:
	if player:
		var color := Color(0.9, 0.3, 0.3)
		if _in_cover:
			color = Color(0.3, 0.6, 0.9)
		if _peeking:
			color = Color(0.9, 0.8, 0.2)
		draw_circle(player.position, PLAYER_RADIUS, color)

		var aim_color := Color(0.3, 1.0, 0.4, 0.8) if _aim_hit_something else Color(1.0, 1.0, 1.0, 0.35)
		draw_dashed_line(player.position, _aim_end, aim_color, 2.0, 10.0)
		draw_circle(_aim_end, 5.0, aim_color)

		if _sprint_charge > 0.05 and _sprint_charge < SPRINT_CHARGE_TIME:
			var frac := _sprint_charge / SPRINT_CHARGE_TIME
			draw_arc(player.position, PLAYER_RADIUS + 7.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 24, Color.YELLOW, 3.0)

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
		var half := Vector2(13, 13)
		draw_rect(Rect2(crate.position - half, half * 2), crate_color)
