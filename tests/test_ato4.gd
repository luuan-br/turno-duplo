extends TestCase
## Ato 4 (A Cidade em Chamas) do começo ao fim de cada fase, os caminhos de
## falha (cair / perder o carro recomeça) e as variações do Epílogo.


func run() -> void:
	await _fase1_silencioso()
	await _fase1_barulhento_e_queda()
	await _fase2_pneu()
	await _fase2_batida_e_perda()
	await _fase3()
	await _fase4()
	await _fase5()
	await _fase5_carro_destruido()
	await _fase6()
	await _epilogo()


func _investigating(combat: CombatLayer) -> int:
	var n := 0
	for g in combat.guards:
		if g.state == EnemyGuard.State.INVESTIGATE or g.state == EnemyGuard.State.COMBAT:
			n += 1
	return n


func _fase1_silencioso() -> void:
	await load_scene("res://missions/ato4_fase1_infiltrar.tscn")
	await skip_story()
	var gate: Vector2 = scene.gate_body.position
	scene.player.position = gate + Vector2(-40, 0)
	ib().set_move_vector(Vector2.RIGHT)
	await wait(0.4)
	ib().set_move_vector(Vector2.ZERO)
	check("Fase 1: portão fechado bloqueia", scene.player.position.x < gate.x and not scene.gate_open)
	await hold("breach", 0.8)
	check("Fase 1: arrombar devagar abre o portão", scene.gate_open and scene._phase == "breach", scene._phase)
	await skip_story()
	check("Fase 1: devagar, ninguém ouve", _investigating(scene.combat) == 0)
	check("Fase 1: combate começa depois do diálogo", scene._phase == "fight" and scene.combat.active)
	expect_ammo("Fase 1", 10, 10)
	await clear_guards(scene.player, scene.combat)
	expect_drops("Fase 1")
	check("Fase 1: derrubar os três fecha o combate", scene.combat.alive_count() == 0 and scene._phase == "outro", scene._phase)
	await expect_done("Fase 1")


func _fase1_barulhento_e_queda() -> void:
	await load_scene("res://missions/ato4_fase1_infiltrar.tscn")
	await skip_story()
	await teleport(scene.player, scene.gate_body.position + Vector2(-40, 0))
	await hold("breach", 0.1)
	await skip_story()
	check("Fase 1: arrombar de uma vez faz os guardas virem ver", _investigating(scene.combat) > 0, "%d investigando" % _investigating(scene.combat))
	scene.player.take_shot()
	scene.player.take_shot()
	check("Fase 1: colete do Ato 4 segura 2 tiros", not scene.player.is_down)
	scene.player.take_shot()
	check("Fase 1: o terceiro tiro derruba", scene.player.is_down and scene._phase == "down")
	check("Fase 1: cair recomeça a missão do início", await wait_reload() and scene._phase == "intro")


## Encosta o carro atrás do Ghost (parado), de frente pra ele. O Ghost
## larga a ~107px da parede da pista — mais longe que isso nasce na parede.
func _behind_ghost(dist: float) -> void:
	var ghost: EnemyCar = scene.ghost
	var car: PlayerCar = scene.car
	ghost.speed = 0.0
	var back := (car.position - ghost.position).normalized()
	car.position = ghost.position + back * dist
	car.rotation = (-back).angle()
	car.speed = 0.0
	await frames(3)


func _fase2_pneu() -> void:
	await load_scene("res://missions/ato4_fase2_perseguicao.tscn")
	await skip_story()
	check("Fase 2: perseguição começa depois do diálogo", scene._phase == "chase" and scene.chase.active, scene._phase)
	await _behind_ghost(90.0)
	check("Fase 2: alinhado atrás, a mira trava no Ghost", scene.chase.auto_target == scene.ghost and scene.fire_btn.visible)
	await tap("shoot")
	await tap("shoot")
	check("Fase 2: dois tiros no pneu param o Ghost", scene.ghost.is_disabled and scene._phase == "outro", scene._phase)
	await expect_done("Fase 2")


func _fase2_batida_e_perda() -> void:
	await load_scene("res://missions/ato4_fase2_perseguicao.tscn")
	await skip_story()
	await _behind_ghost(90.0)
	ib().press("accelerate")
	var hit := await wait_until(func(): return scene.ghost.hp < scene.ghost.max_hp, 4.0)
	ib().reset()
	check("Fase 2: bater forte no Ghost tira vida dele", hit, "hp=%.1f" % scene.ghost.hp)
	scene.car.take_damage(1000.0)
	await frames(2)
	check("Fase 2: lataria zerada perde a perseguição", scene._phase == "down", scene._phase)
	check("Fase 2: carro destruído recomeça a missão", await wait_reload() and scene._phase == "intro")


func _fase3() -> void:
	await load_scene("res://missions/ato4_fase3_extracao.tscn")
	await skip_story()
	check("Fase 3: combate começa depois do diálogo", scene._phase == "fight" and scene.combat.active, scene._phase)
	expect_ammo("Fase 3", 10, 10)
	await clear_guards(scene.player, scene.combat)
	expect_drops("Fase 3")
	check("Fase 3: derrubar os sequestradores", scene._phase == "aftermath", scene._phase)
	await skip_story()
	await teleport(scene.player, scene.family_obj.position + Vector2(-35, 0))
	await hold("rescue", 0.6)
	check("Fase 3: libertar a Sarah e a Emma", scene._rescued)
	await expect_done("Fase 3")


func _fase4() -> void:
	await load_scene("res://missions/ato4_fase4_luzes.tscn")
	await skip_story()
	for i in scene.panels.size():
		await teleport(scene.player, scene.panels[i].position + Vector2(-30, 0))
		await hold("reactivate", 0.6)
		check("Fase 4: painel %d reconectado" % (i + 1), scene.panel_done[i])
		if i < scene.panels.size() - 1:
			await skip_story()
			check("Fase 4: controles voltam depois do aviso do painel %d" % (i + 1), scene._phase == "work" and not scene._controls_locked, scene._phase)
	await expect_done("Fase 4")


func _fase5() -> void:
	await load_scene("res://missions/ato4_fase5_cofre.tscn")
	await skip_story()
	expect_ammo("Fase 5", 10, 10)
	await clear_guards(scene.player, scene.combat)
	expect_drops("Fase 5")
	check("Fase 5: derrubar os guardas do Cofre", scene._phase == "aftermath", scene._phase)
	await skip_story()
	await teleport(scene.player, scene.vault_obj.position + Vector2(-35, 0))
	await hold("open_vault", 0.6)
	check("Fase 5: abrir o cofre", scene._vault_opened and scene._phase == "to_car", scene._phase)
	await skip_story()
	check("Fase 5: fuga de carro começa", scene._phase == "escape" and scene.car != null, scene._phase)
	check("Fase 5: câmera passa pro carro (bug do celular)", not scene.player.camera.enabled and scene.car.camera.enabled)
	check("Fase 5: manche direito some na fuga (não disputa toque com o carro)", not scene.right_stick.visible)
	check("Fase 5: perseguidores nascem dentro da pista (bug do celular)", scene.chase.enemies.all(func(e): return e.position.x > scene.TRACK_ORIGIN.x + scene.WALL_THICK))
	await wait(scene.PURSUIT_HEAD_START + 0.2)
	check("Fase 5: reforços largam depois da vantagem", scene.chase.active)
	# Um perseguidor parado logo atrás: a mira de trás trava e o tiro pega.
	var e: EnemyCar = scene.chase.enemies[0]
	e.speed = 0.0
	e.position = scene.car.position - scene.car.forward() * 120.0
	await frames(3)
	var hp_before: float = e.hp
	check("Fase 5: mira de trás trava no perseguidor", scene.chase.auto_target == e and scene.rear_fire_btn.visible)
	await tap("rear_shoot")
	check("Fase 5: atirar pra trás acerta", e.hp < hp_before)
	await teleport(scene.car, scene.escape_finish.position)
	check("Fase 5: chegar no fim da pista encerra a fuga", scene._phase == "outro", scene._phase)
	await expect_done("Fase 5")


func _fase5_carro_destruido() -> void:
	await load_scene("res://missions/ato4_fase5_cofre.tscn")
	await skip_story()
	await clear_guards(scene.player, scene.combat)
	await skip_story()
	await teleport(scene.player, scene.vault_obj.position + Vector2(-35, 0))
	await hold("open_vault", 0.3)
	await skip_story()
	await frames(2)
	scene.car.take_damage(1000.0)
	await frames(2)
	check("Fase 5: carro destruído na fuga recomeça a missão", scene._phase == "down" and await wait_reload() and scene._phase == "intro", scene._phase)


func _fase6() -> void:
	await load_scene("res://missions/ato4_fase6_arquiteto.tscn")
	await skip_story()
	expect_ammo("Fase 6", 10, 10)
	await clear_guards(scene.player, scene.combat)
	expect_drops("Fase 6")
	check("Fase 6: derrubar a escolta do Kessler", scene._phase == "aftermath", scene._phase)
	await skip_story()
	var start: Vector2 = scene.kessler_marker.position
	await wait(0.5)
	check("Fase 6: o Kessler foge pelo corredor", scene._phase == "corridor" and scene.kessler_marker.position.distance_to(start) > 5.0, scene._phase)
	# Toque, não segurar: o Kessler continua andando e sairia do alcance.
	await teleport(scene.player, scene.kessler_marker.position + Vector2(-30, 0))
	await tap("detain")
	check("Fase 6: deter o Kessler (captura, não tiro)", scene._kessler_caught)
	await expect_done("Fase 6")


func _epilogo_text() -> String:
	return " ".join(PackedStringArray(scene.story._lines))


func _epilogo() -> void:
	gs().reset()
	gs().doyle_fate = "confronto"
	gs().doyle_confessed = true
	gs().family_meter = 2
	await load_scene("res://missions/ato4_epilogo.tscn")
	var t := _epilogo_text()
	check("Epílogo: Doyle depõe (confronto)", "aceitou depor" in t)
	check("Epílogo: confissão da dívida ecoa", "uma dívida" in t)
	check("Epílogo: família presente", "três sentados à mesa" in t)
	scene.story.skip()
	await frames(2)
	check("Epílogo: termina a campanha", scene._phase == "done")

	gs().reset()
	gs().doyle_fate = "saida"
	await load_scene("res://missions/ato4_epilogo.tscn")
	t = _epilogo_text()
	check("Epílogo: Doyle sumiu (saída)", "Ninguém mais viu o Doyle" in t)
	check("Epílogo: sem confissão, fica a dúvida", "nunca soube direito" in t)
	check("Epílogo: família distante", "meses de ausência" in t)

	gs().reset()
	gs().doyle_fate = "entregue"
	await load_scene("res://missions/ato4_epilogo.tscn")
	check("Epílogo: Doyle entregue", "Corregedoria. Mark não se arrepende" in _epilogo_text())
