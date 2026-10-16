extends TestCase
## Sistemas compartilhados isolados numa arena montada por código: visão e
## audição do guarda (EnemyGuard), controle e lataria do carro (PlayerCar)
## e o toque duplo do manche direito (virtual_joystick). Cada caso aqui já
## foi bug real ou pedido explícito do usuário no celular — ver CLAUDE.md.


func run() -> void:
	await _guarda()
	await _municao()
	await _sandbox_tatico()
	await _carro()
	await _manche_toque_duplo()
	await _disposicao_controles()
	await _editor_controles()
	await _interrogatorio()


# ---------- arena ----------

func _arena() -> Node2D:
	if scene and is_instance_valid(scene):
		scene.queue_free()
		await frames(1)
	ib().reset()
	scene = Node2D.new()
	get_tree().root.add_child(scene)
	return scene


func _wall(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.position = pos
	scene.add_child(body)
	return body


# ---------- guarda ----------

func _sees(g: EnemyGuard) -> bool:
	return g._can_see_target()


func _guarda() -> void:
	await _arena()
	var player := TacticalPlayer.new()
	scene.add_child(player)
	var combat := CombatLayer.new()
	scene.add_child(combat)
	combat.setup(player)
	var pts: Array[Vector2] = [Vector2.ZERO]
	var g := combat.add_guard(pts, Vector2.RIGHT)
	var wall := _wall(Vector2(5000, 0), Vector2(20, 200))
	await frames(2)

	player.position = Vector2(200, 0)
	await frames(2)
	check("Guarda: vê o jogador na frente, dentro do alcance", _sees(g))
	player.position = Vector2(-200, 0)
	await frames(2)
	check("Guarda: não vê pelas costas", not _sees(g))
	player.position = Vector2(150, 0).rotated(deg_to_rad(50))
	await frames(2)
	check("Guarda: cone fixo — 50° de lado fica fora", not _sees(g))
	g.state = EnemyGuard.State.COMBAT
	check("Guarda: em combate o cone abre um pouco (50° entra)", _sees(g))
	g.state = EnemyGuard.State.PATROL
	player.position = Vector2(350, 0)
	await frames(2)
	check("Guarda: longe demais não vê", not _sees(g))

	player.position = Vector2(200, 0)
	wall.position = Vector2(100, 0)
	await frames(2)
	check("Guarda: parede bloqueia a visão (bug do 1º piloto)", not _sees(g))
	g.state = EnemyGuard.State.COMBAT
	check("Guarda: nem em combate ele enxerga através da parede", not _sees(g))
	g.state = EnemyGuard.State.PATROL
	wall.position = Vector2(5000, 0)
	await frames(2)

	g.dark = true
	check("Guarda: no escuro, a 200px já não vê", not _sees(g))
	player.position = Vector2(90, 0)
	await frames(2)
	check("Guarda: no escuro ainda vê de perto", _sees(g))
	g.dark = false

	# Audição: barulho do lado de lá da parede chega abafado.
	player.position = Vector2(-400, 0)
	wall.position = Vector2(100, 0)
	await frames(2)
	g.hear_noise(Vector2(200, 0), 200.0)
	check("Guarda: barulho atrás da parede no limite do raio fica abafado", g.state == EnemyGuard.State.PATROL)
	g.hear_noise(Vector2(200, 0), 400.0)
	check("Guarda: barulho mais alto atrás da parede ele ouve e vai ver", g.state == EnemyGuard.State.INVESTIGATE)
	g.reset()
	wall.position = Vector2(5000, 0)
	await frames(2)

	# Detecção leva tempo; depois mira visível antes do tiro.
	var shots: Array[float] = []
	var start := Time.get_ticks_msec()
	g.fired.connect(func(_f, _t, _h): shots.append((Time.get_ticks_msec() - start) / 1000.0))
	player.position = Vector2(150, 0)
	combat.set_active(true)
	await frames(2)
	check("Guarda: não entra em combate na hora — o medidor enche", g.state != EnemyGuard.State.COMBAT)
	var in_combat := await wait_until(func(): return g.state == EnemyGuard.State.COMBAT, 2.0)
	var combat_at := (Time.get_ticks_msec() - start) / 1000.0
	check("Guarda: vendo o jogador, entra em combate", in_combat)
	await wait_until(func(): return not shots.is_empty(), 3.0)
	check("Guarda: mira visível antes do primeiro tiro", not shots.is_empty() and shots[0] - combat_at >= g.aim_time * 0.9, str(shots))

	# Sumir atrás da parede: perde o jogador e vai procurar.
	wall.position = Vector2(75, 0)
	await wait(g.lose_sight_time + 0.6)
	check("Guarda: sem linha de visão, sai do combate e procura", g.state != EnemyGuard.State.COMBAT, str(g.state))


# ---------- munição ----------

func _municao() -> void:
	await _arena()
	var player := TacticalPlayer.new()
	scene.add_child(player)
	var combat := CombatLayer.new()
	scene.add_child(combat)
	combat.setup(player)
	player.controls_locked = false
	player.can_shoot = true
	player.reload_time = 0.3
	var shots := [0]
	player.fired.connect(func(_c, _f, _t): shots[0] += 1)
	await frames(2)

	check("Munição: sem set_ammo é infinita (missões que não usam o sistema)", not player.uses_ammo())
	for i in 3:
		await tap("shoot")
	check("Munição: ...e atira sempre", shots[0] == 3)

	shots[0] = 0
	player.set_ammo(2, 1)
	await tap("shoot")
	check("Munição: cada tiro gasta uma bala do pente", player.mag == 1 and shots[0] == 1)
	await tap("shoot")
	check("Munição: pente vazio recarrega sozinho", player.mag == 0 and player.is_reloading())
	await tap("shoot")
	check("Munição: recarregando não atira", shots[0] == 2)
	await wait(0.45)
	check("Munição: recarga tira da reserva só o que cabe", player.mag == 1 and player.reserve == 0 and not player.is_reloading())
	await tap("shoot")
	var dry := [0]
	player.dry_fired.connect(func(): dry[0] += 1)
	await tap("shoot")
	check("Munição: sem bala nenhuma o gatilho só dá clique", shots[0] == 3 and dry[0] == 1 and not player.is_reloading())

	# Guarda derrubado larga a arma; passar por cima pega e já recarrega.
	var pts: Array[Vector2] = [Vector2(300, 0)]
	var g := combat.add_guard(pts, Vector2.LEFT)
	await frames(2)
	g.take_hit()
	await frames(2)
	check("Munição: guarda derrubado larga a arma", combat.drops.size() == 1)
	player.position = Vector2(150, 0)
	await frames(3)
	check("Munição: longe dela não pega", combat.drops.size() == 1 and player.reserve == 0)
	player.position = g.global_position
	await frames(3)
	check("Munição: passar por cima pega as balas", combat.drops.is_empty() and (player.reserve > 0 or player.is_reloading()))
	await wait(0.45)
	check("Munição: arma pega com o pente vazio já recarrega", player.mag == mini(2, combat.drop_ammo))

	player.set_ammo(3, 5)
	await tap("shoot")
	await tap("reload")
	check("Munição: RECARREGAR antes de esvaziar funciona", player.is_reloading())
	await wait(0.45)
	check("Munição: recarga manual completa o pente", player.mag == 3 and player.reserve == 4)
	await tap("reload")
	check("Munição: pente cheio não recarrega", not player.is_reloading())


func _sandbox_tatico() -> void:
	await load_scene("res://sandbox/tatico.tscn")
	var p: TacticalPlayer = scene.player
	check("Sandbox tático: piloto de munição ligado", p.uses_ammo() and p.mag == scene.MAG_SIZE and p.reserve == scene.SPARE_AMMO)
	check("Sandbox tático: RECARREGAR escondido com pente cheio", not scene.reload_btn.visible)
	await tap("shoot")
	check("Sandbox tático: depois de um tiro, RECARREGAR aparece", scene.reload_btn.visible)
	check("Sandbox tático: HUD mostra a munição", "Munição: %d/%d" % [p.mag, p.mag_size] in scene.health_label.text, scene.health_label.text)
	await clear_guards(p, scene.combat)
	check("Sandbox tático: cada guarda derrubado larga a arma", scene.combat.drops.size() == scene.combat.guards.size(), "%d armas" % scene.combat.drops.size())


# ---------- carro ----------

func _carro() -> void:
	await _arena()
	var car := PlayerCar.new()
	scene.add_child(car)
	car.controls_locked = false
	await frames(2)

	ib().press("accelerate")
	await wait(0.5)
	ib().release("accelerate")
	check("Carro: acelera pra frente", car.speed > 50.0 and car.position.x > 10.0, "speed=%d" % car.speed)
	ib().press("brake")
	await wait(1.5)
	check("Carro: segurar FREAR para e dá ré", car.speed < 0.0, "speed=%d" % car.speed)
	ib().release("brake")
	await wait(0.6)

	# Prensado na parede segurando ACELERAR: só a primeira batida conta, e
	# continua dando pra frear/dar ré (bug real: o carro travava).
	car.position = Vector2(0, 0)
	car.rotation = 0.0
	car.speed = 0.0
	car.hp = car.max_hp
	_wall(Vector2(60, 0), Vector2(20, 300))
	await frames(2)
	ib().press("accelerate")
	await wait(1.2)
	var hp_pinned := car.hp
	await wait(1.0)
	ib().release("accelerate")
	check("Carro: prensado na parede não se destrói sozinho", car.hp == hp_pinned and car.hp > car.max_hp * 0.7, "hp=%d" % car.hp)
	ib().press("brake")
	await wait(1.0)
	ib().release("brake")
	check("Carro: prensado, FREAR ainda dá ré e sai da parede (bug do celular)", car.position.x < 10.0 and car.speed <= 0.0, "x=%d speed=%d" % [car.position.x, car.speed])

	# Batida de frente em velocidade máxima: ~25% de lataria.
	var far := _wall(Vector2(700, 0), Vector2(20, 300))
	car.position = Vector2(0, 0)
	car.rotation = 0.0
	car.hp = car.max_hp
	car.speed = car.max_speed
	ib().press("accelerate")
	await wait_until(func(): return car.hp < car.max_hp, 4.0)
	ib().release("accelerate")
	var lost := car.max_hp - car.hp
	check("Carro: batida de frente no máximo tira ~1/4 da lataria", lost > 15.0 and lost < 35.0, "perdeu %d" % lost)
	far.queue_free()
	car.take_damage(1000.0)
	check("Carro: lataria zerada = destruído e trava os controles", car.is_wrecked and car.controls_locked)


# ---------- manche direito ----------

func _touch(stick: Control, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 1
	ev.position = pos
	ev.pressed = pressed
	stick._input(ev)


func _manche_toque_duplo() -> void:
	await _arena()
	var layer := CanvasLayer.new()
	scene.add_child(layer)
	var stick := Control.new()
	stick.set_script(load("res://ui/virtual_joystick.gd"))
	stick.right_stick = true
	stick.double_tap_action = "shoot"
	stick.position = Vector2(500, 0)
	stick.size = Vector2(500, 540)
	layer.add_child(stick)
	await frames(2)
	var p := Vector2(800, 300)

	_touch(stick, p, true)
	_touch(stick, p, false)
	check("Manche: um toque só não atira", not ib().consume_just_pressed("shoot"))
	_touch(stick, p, true)
	check("Manche: toque duplo atira", ib().consume_just_pressed("shoot"))
	_touch(stick, p, false)
	_touch(stick, p, true)
	check("Manche: pegar o manche logo depois de atirar não solta outro tiro (bug do celular)", not ib().consume_just_pressed("shoot"))
	_touch(stick, p, false)
	await wait(0.4)
	_touch(stick, p, true)
	_touch(stick, p, false)
	await wait(0.4)
	_touch(stick, p, true)
	check("Manche: dois toques espaçados demais não atiram", not ib().consume_just_pressed("shoot"))
	_touch(stick, p, false)


# ---------- disposição configurável dos botões ----------

func _layout() -> Node:
	return get_node("/root/ControlLayout")


## Centro do botão medido do canto inferior direito, como o ControlLayout.
func _btn_center(btn: Control) -> Vector2:
	return -Vector2((btn.offset_left + btn.offset_right) * 0.5, (btn.offset_top + btn.offset_bottom) * 0.5)


func _disposicao_controles() -> void:
	var cl := _layout()
	cl.reset_defaults()
	for scr in [Vector2(960, 540), Vector2(1170, 540)]:
		for m in ["pe", "carro"]:
			check("Controles: padrão de fábrica sem botão encostado (%s, %dx%d)" % [m, scr.x, scr.y], cl.problems(m, scr).is_empty(), str(cl.problems(m, scr)))

	# Padrão = a disposição validada no celular (antes era fixa em cada missão).
	await load_scene("res://missions/ato4_fase1_infiltrar.tscn")
	var b: Control = scene.fire_btn
	check("Controles: ATIRAR da missão no lugar validado (30 da direita, 180 de baixo, 100)", is_equal_approx(b.offset_right, -30.0) and is_equal_approx(b.offset_bottom, -180.0) and is_equal_approx(b.radius, 50.0), "%s %s %s" % [b.offset_right, b.offset_bottom, b.radius])

	# Mudou o lugar: toda missão abre com o botão lá.
	cl.set_placement("acao_principal", Vector2(400, 260), 130.0)
	cl.set_placement("carro_extra", Vector2(300, 120), 90.0)
	await load_scene("res://missions/ato4_fase1_infiltrar.tscn")
	check("Controles: ATIRAR segue a disposição do jogador", _btn_center(scene.fire_btn).is_equal_approx(Vector2(400, 260)) and is_equal_approx(scene.fire_btn.radius, 65.0))
	check("Controles: ARROMBAR divide o lugar do ATIRAR (botão principal)", _btn_center(scene.breach_btn).is_equal_approx(Vector2(400, 260)))
	check("Controles: RECARGA fica onde estava (lugar próprio)", _btn_center(scene.reload_btn).is_equal_approx(cl.SLOTS["acao_secundaria"]["center"]))
	await load_scene("res://missions/ato4_fase2_perseguicao.tscn")
	check("Controles: tiro no pneu (dirigindo) segue o lugar extra do carro, não o ATIRAR a pé", _btn_center(scene.fire_btn).is_equal_approx(Vector2(300, 120)))
	await load_scene("res://missions/ato1_fase2_abordagem.tscn")
	check("Controles: vale também na Academia", _btn_center(scene.fire_btn).is_equal_approx(Vector2(400, 260)))

	# Salvar e carregar (arquivo de teste — ver run_tests.gd).
	cl.save_layout()
	cl.reset_defaults()
	cl.load_layout()
	check("Controles: disposição salva volta ao abrir o jogo", cl.center_of("acao_principal").is_equal_approx(Vector2(400, 260)) and is_equal_approx(cl.size_of("carro_extra"), 90.0))

	cl.set_placement("acao_secundaria", Vector2(400, 200), 72.0)
	check("Controles: botões encostados são detectados", not cl.problems("pe", Vector2(960, 540)).is_empty())
	cl.set_placement("acao_secundaria", Vector2(960 - 70, 35), 72.0)
	check("Controles: botão em cima do \"< Menu\" é detectado", cl.problems("pe", Vector2(960, 540)).size() == 1)
	cl.set_placement("acao_secundaria", Vector2(80, 110), 500.0)
	check("Controles: tamanho fica entre o mínimo e o máximo", is_equal_approx(cl.size_of("acao_secundaria"), cl.SIZE_MAX))
	cl.reset_defaults()
	cl.save_layout()


func _mouse(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = pos
	ev.pressed = pressed
	scene._on_canvas_input(ev)


func _mouse_move(pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	scene._on_canvas_input(ev)


func _editor_controles() -> void:
	var cl := _layout()
	cl.reset_defaults()
	await load_scene("res://ui/controls_editor.tscn")
	check("Editor: abre na aba A pé com o botão principal escolhido", scene.mode == "pe" and scene.selected == "acao_principal")

	var start: Vector2 = scene.screen_pos("acao_secundaria")
	_mouse(start, true)
	_mouse_move(start + Vector2(-200, 0))
	_mouse(start + Vector2(-200, 0), false)
	check("Editor: tocar e arrastar escolhe e move o botão", scene.selected == "acao_secundaria" and scene.screen_pos("acao_secundaria").is_equal_approx(start + Vector2(-200, 0)))

	var big: float = cl.size_of("acao_secundaria")
	scene._resize(scene.SIZE_STEP)
	check("Editor: + aumenta o tamanho", is_equal_approx(cl.size_of("acao_secundaria"), big + scene.SIZE_STEP))

	_mouse(scene.screen_pos("acao_secundaria"), true)
	_mouse_move(Vector2(scene.screen_pos("acao_secundaria").x, -500))
	_mouse(Vector2.ZERO, false)
	check("Editor: não deixa subir na barra de cima", scene.screen_pos("acao_secundaria").y >= scene.TOOLBAR_H + cl.size_of("acao_secundaria") * 0.5 - 0.5)

	# Encostado no ATIRAR: não salva.
	var target: Vector2 = scene.screen_pos("acao_principal") + Vector2(-30, 0)
	_mouse(scene.screen_pos("acao_secundaria"), true)
	_mouse_move(target)
	_mouse(target, false)
	scene._on_save()
	cl.load_layout()
	check("Editor: com botões encostados, Salvar recusa e avisa", cl.center_of("acao_secundaria").is_equal_approx(cl.SLOTS["acao_secundaria"]["center"]) and "encostados" in scene.msg_label.text, scene.msg_label.text)

	# Afastado: salva.
	await load_scene("res://ui/controls_editor.tscn")
	var p2: Vector2 = scene.screen_pos("acao_secundaria") + Vector2(-150, -20)
	_mouse(scene.screen_pos("acao_secundaria"), true)
	_mouse_move(p2)
	_mouse(p2, false)
	scene._on_save()
	cl.reset_defaults()
	cl.load_layout()
	check("Editor: Salvar grava a disposição", cl.is_custom() and scene._screen() - cl.center_of("acao_secundaria") == p2, scene.msg_label.text)

	scene._on_reset()
	check("Editor: Restaurar padrão volta à disposição de fábrica", not cl.is_custom())
	cl.save_layout()
	scene._set_mode("carro")
	check("Editor: aba Carro mostra os 3 botões do carro", scene.selected == "carro_acelerar" and cl.slots_for_mode("carro").size() == 3)


# ---------- interrogatório (piloto do sandbox) ----------

func _interrogatorio() -> void:
	await load_scene("res://sandbox/interrogatorio.tscn")
	var it: Control = scene.interrogation
	var results: Array[Dictionary] = []
	it.finished.connect(func(r): results.append(r))

	scene._start()
	await frames(1)
	check("Interrogatório: abre com o suspeito do piloto", it.visible)
	var total: int = it._rounds.size()
	await answer_interrogation(it, true)
	var r: Dictionary = results.back() if not results.is_empty() else {}
	check("Interrogatório: ler todas as deixas certo revela tudo", not r.is_empty() and not r["shut_down"] and r["correct"] == total and r["revealed"].size() == total, str(r))

	scene._start()
	await frames(1)
	await answer_interrogation(it, false)
	r = results.back()
	check("Interrogatório: errar até acabar a paciência fecha o suspeito (sem fail state)", r["shut_down"] and r["correct"] == 0 and not it.visible, str(r))
	check("Interrogatório: tela de resultado aparece depois", scene.result_panel.visible)
