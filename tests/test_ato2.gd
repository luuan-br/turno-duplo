extends TestCase
## Ato 2 (Novato nas Ruas) do começo ao fim de cada turno, mais os
## caminhos de falha das fases com risco (Turno 4 e Turno 6 recomeçam).


func run() -> void:
	await _turno1()
	await _turno2()
	await _turno3()
	await _turno4()
	await _turno4_fuga()
	await _turno5()
	await _turno6()
	await _turno6_queda()


func _turno1() -> void:
	gs().reset()
	await load_scene("res://missions/ato2_turno1_a_dupla.tscn")
	await skip_story()
	await teleport(scene.player, scene.greet_zone.position)
	await skip_story()
	check("Turno 1: Doyle passa a seguir o Mark", scene._doyle_following)
	await teleport(scene.player, scene.car_zone.position)
	await skip_story()
	check("Turno 1: abordagem termina numa escolha", scene._phase == "choice" and scene.choice.visible, scene._phase)
	scene.choice._on_chosen(0)
	await frames(2)
	check("Turno 1: de-escalar sobe a reputação", gs().reputation == 1, "rep=%d" % gs().reputation)
	await expect_done("Turno 1")


func _turno2() -> void:
	await load_scene("res://missions/ato2_turno2_furto.tscn")
	await skip_story()
	await teleport(scene.player, scene.shopkeeper_marker.position)
	check("Turno 2: lojista conta o que aconteceu", scene._phase == "shopkeeper", scene._phase)
	await skip_story()
	await teleport(scene.player, scene.radio_zone.position)
	check("Turno 2: chamado de rádio opcional dispara", scene._radio_visited)
	await skip_story()
	await teleport(scene.player, scene.window_obj.position + Vector2(0, 30))
	await tap("examine")
	check("Turno 2: examinar o vidro fecha o turno", scene._window_examined)
	await expect_done("Turno 2")


func _turno3() -> void:
	await load_scene("res://missions/ato2_turno3_corrida.tscn")
	await skip_story()
	await teleport(scene.player, scene.start_zone.position)
	check("Turno 3: o suspeito sai correndo", scene._phase == "chase", scene._phase)
	await wait(0.5)
	await teleport(scene.player, scene.suspect.position + Vector2(-25, 0))
	await tap("catch")
	check("Turno 3: alcançar e segurar prende o suspeito", scene.suspect_caught)
	await expect_done("Turno 3")


func _pit(car: PlayerCar, target: EnemyCar) -> bool:
	target.speed = 0.0
	car.position = target.position - Vector2.RIGHT.rotated(target.rotation) * 70.0
	car.rotation = target.rotation
	car.speed = 0.0
	ib().press("handbrake")
	ib().press("accelerate")
	var ok := await wait_until(func(): return target.is_disabled, 4.0)
	ib().reset()
	return ok


func _turno4() -> void:
	gs().reset()
	await load_scene("res://missions/ato2_turno4_semaforo.tscn")
	await skip_story()
	check("Turno 4: perseguição começa depois do diálogo", scene._phase == "chase" and scene.chase.active, scene._phase)
	check("Turno 4: PIT encostando atrás com freio de mão para o carro", await _pit(scene.car, scene.fleeing_car))
	await wait(2.0)
	check("Turno 4: o Ghost passa e fica registrado", gs().ghost_spotted)
	await expect_done("Turno 4")


func _turno4_fuga() -> void:
	await load_scene("res://missions/ato2_turno4_semaforo.tscn")
	await skip_story()
	scene.chase.escape_distance = 0.0
	scene.chase.escape_time = 0.3
	var down := await wait_until(func(): return scene._phase == "down", 3.0)
	check("Turno 4: ficar longe deixa o suspeito escapar", down)
	check("Turno 4: suspeito escapou recomeça a missão", await wait_reload() and scene._phase == "intro")


func _turno5() -> void:
	gs().reset()
	await load_scene("res://missions/ato2_turno5_fora_de_servico.tscn")
	await skip_story()
	await teleport(scene.player, scene.table_zone.position)
	await skip_story()
	check("Turno 5: conversa no bar termina numa escolha", scene._phase == "choice" and scene.choice.visible, scene._phase)
	scene.choice._on_chosen(0)
	await frames(2)
	check("Turno 5: perguntar da vida dele sobe a relação com o Doyle", gs().doyle_relationship == 1)
	await expect_done("Turno 5")


func _turno6() -> void:
	await load_scene("res://missions/ato2_turno6_incidente.tscn")
	await skip_story()
	scene.player.position = scene.door_body.position + Vector2(-35, 0)
	ib().set_move_vector(Vector2.RIGHT)
	await wait(0.4)
	ib().set_move_vector(Vector2.ZERO)
	check("Turno 6: porta fechada bloqueia", scene.player.position.x < scene.door_body.position.x)
	await hold("breach", 0.3)
	check("Turno 6: arrombar dispara a emboscada", scene._phase == "ambush", scene._phase)
	await skip_story()
	check("Turno 6: o atirador já começa em combate", scene.shooter.state == EnemyGuard.State.COMBAT)
	expect_ammo("Turno 6", 8, 8)
	await clear_guards(scene.player, scene.combat)
	expect_drops("Turno 6")
	await skip_story()
	check("Turno 6: derrubar os dois libera examinar a cena", scene._phase == "examine", scene._phase)
	await teleport(scene.player, scene.clue_obj.position + Vector2(-35, 0))
	await tap("examine")
	await expect_done("Turno 6")


func _turno6_queda() -> void:
	await load_scene("res://missions/ato2_turno6_incidente.tscn")
	await skip_story()
	await teleport(scene.player, scene.door_body.position + Vector2(-35, 0))
	await hold("breach", 0.3)
	await skip_story()
	await tap("shoot")
	check("Turno 6: depois de um tiro, RECARGA aparece", scene.reload_btn.visible and scene.player.mag == scene.MAG_SIZE - 1)
	scene.player.take_shot()
	check("Turno 6: colete de patrulha segura 1 tiro", not scene.player.is_down and scene.player.vest_hp == 0)
	scene.player.take_shot()
	check("Turno 6: sem colete, um tiro derruba", scene.player.is_down and scene._phase == "down")
	check("Turno 6: cair recomeça a missão do início", await wait_reload() and scene._phase == "intro")
