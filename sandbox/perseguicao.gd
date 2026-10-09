extends Node2D
## Sandbox de perseguição — caixas cinzas. Controle do carro validado no
## celular (direção relativa à tela, ACELERAR/FREAR/FREIO DE MÃO em
## botões). Agora é a referência viva do risco real nas perseguições,
## montado com os componentes das missões: `actors/player_car.gd`,
## `actors/enemy_car.gd` e `actors/chase_layer.gd`. GDD Seção 8.
##
## Tudo ligado de uma vez pra testar: lataria (batida forte machuca),
## suspeito que escapa se você ficar longe, passageiro atirando (com
## aviso), freada brusca, PIT, bater até quebrar e tiro no pneu.

const TRACK_SIZE := Vector2(820.0, 460.0)
const TRACK_ORIGIN := Vector2(60.0, 40.0)
const WALL_THICK := 20.0
const TIRE_SHOT_DAMAGE := 2.0
const RESET_AFTER_WIN := 2.5

var car: PlayerCar
var chase: ChaseLayer
var suspect: EnemyCar
var status_label: Label
var shoot_btn: Control
var _ended := false


func _ready() -> void:
	_build_track()
	chase = ChaseLayer.new()
	add_child(chase)
	_build_cars()
	_build_hud()
	_build_controls()
	chase.set_active(true)


func _add_block(r: Rect2, color: Color) -> void:
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
	poly.color = color
	poly.position = r.position
	add_child(poly)


func _build_track() -> void:
	var top := TRACK_ORIGIN
	var w := TRACK_SIZE.x
	var h := TRACK_SIZE.y
	var wall := Color(0.3, 0.3, 0.35)
	_add_block(Rect2(top, Vector2(w, WALL_THICK)), wall)
	_add_block(Rect2(Vector2(top.x, top.y + h - WALL_THICK), Vector2(w, WALL_THICK)), wall)
	_add_block(Rect2(top, Vector2(WALL_THICK, h)), wall)
	_add_block(Rect2(Vector2(top.x + w - WALL_THICK, top.y), Vector2(WALL_THICK, h)), wall)
	# Ilha no meio (vira uma volta de verdade, não dá pra cortar caminho) e
	# pilares na parte de dentro das curvas — cortar a curva custa lataria.
	var block := Color(0.4, 0.33, 0.25)
	_add_block(Rect2(top + Vector2(180, 170), Vector2(460, 120)), block)
	_add_block(Rect2(top + Vector2(130, 120), Vector2(28, 28)), block)
	_add_block(Rect2(top + Vector2(w - 158, h - 148), Vector2(28, 28)), block)


func _build_cars() -> void:
	var top := TRACK_ORIGIN
	var w := TRACK_SIZE.x
	var h := TRACK_SIZE.y

	car = PlayerCar.new()
	car.position = top + Vector2(120, 260)
	car.rotation = -PI * 0.5
	car.controls_locked = false
	add_child(car)
	chase.setup(car)
	chase.pit_enabled = true
	chase.ram_damage = 1.0
	chase.aim_mode = 1

	suspect = EnemyCar.new()
	suspect.waypoints = [
		top + Vector2(80, 80),
		top + Vector2(w - 80, 80),
		top + Vector2(w - 80, h - 80),
		top + Vector2(80, h - 80),
	]
	suspect.position = suspect.waypoints[0]
	suspect.speed = 150.0
	suspect.shooter = true
	suspect.brake_check = true
	chase.add_enemy(suspect)
	chase.escape_target = suspect

	chase.player_wrecked.connect(func(): _end("Carro destruído. Recomeçando...", 0.0))
	chase.suspect_escaped.connect(func(): _end("O suspeito escapou. Recomeçando...", 0.0))
	chase.enemy_disabled.connect(func(_c): _end("ALVO PARADO! Recomeçando pra testar de novo...", RESET_AFTER_WIN))


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(16, 16)
	status_label.add_theme_font_size_override("font_size", 16)
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

	var stick := Control.new()
	stick.set_script(load("res://ui/virtual_joystick.gd"))
	stick.anchor_left = 0.0
	stick.anchor_right = 0.55
	stick.anchor_top = 0.0
	stick.anchor_bottom = 1.0
	layer.add_child(stick)

	layer.add_child(_corner_button("accelerate", "ACELERAR", 30, 30, 110, 110))
	layer.add_child(_corner_button("brake", "FREAR", 160, 40, 100, 100))
	layer.add_child(_corner_button("handbrake", "FREIO DE\nMÃO / PIT", 30, 160, 110, 110))

	shoot_btn = _corner_button("shoot", "ATIRAR\nNO PNEU", 280, 30, 90, 90)
	shoot_btn.visible = false
	layer.add_child(shoot_btn)


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


func _end(msg: String, extra_delay: float) -> void:
	if _ended:
		return
	_ended = true
	car.controls_locked = true
	status_label.text = msg
	chase.restart_mission(ChaseLayer.RESTART_DELAY + extra_delay)


func _process(_delta: float) -> void:
	shoot_btn.visible = chase.auto_target != null and not _ended
	if InputBridge.consume_just_pressed("shoot") and not _ended:
		chase.fire_auto(TIRE_SHOT_DAMAGE)
	if not _ended:
		status_label.text = "Lataria: %d%%   |   Suspeito: %d/%d   |   Fugindo: %s\nCole nele. Longe demais por muito tempo = ele escapa. Batida forte machuca seu carro.\nTerminar: PIT (freio de mão encostado atrás), bater forte até quebrar, ou alinhar e ATIRAR NO PNEU.\nO passageiro atira — a linha vermelha avisa antes: saia da linha (atrás da ilha)." % [int(car.hp), int(suspect.hp), int(suspect.max_hp), _bar(chase.escape_progress)]


func _bar(frac: float) -> String:
	var n := int(round(clampf(frac, 0.0, 1.0) * 10.0))
	return "[" + "#".repeat(n) + "-".repeat(10 - n) + "]"
