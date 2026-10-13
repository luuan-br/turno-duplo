extends TestCase
## Ato 1 (Academia) do começo ao fim de cada fase. Usa o controlador
## tático/carro antigo (a Academia fica sem risco de propósito), então a
## mira é `scene._facing` e o carro é `scene.player_car`.


func run() -> void:
	await _fase1()
	await _fase2()
	await _fase3()
	await _fase4()


## Atira com o controlador antigo: chega perto do alvo, mira, aperta.
func _shoot_old(target: Area2D) -> void:
	var ignore: Array[RID] = [scene.player.get_rid()]
	scene.player.position = free_spot_near(target.position, 45.0, ignore)
	scene._facing = (target.position - scene.player.position).normalized()
	await frames(2)
	await tap("shoot")


func _fase1() -> void:
	await load_scene("res://missions/ato1_fase1_chegada.tscn")
	await skip_story()
	await teleport(scene.player, scene.greet_zone.position)
	check("Fase 1: Okafor e Theo cumprimentam ao chegar perto", scene._phase == "greet", scene._phase)
	await skip_story()
	await teleport(scene.player, scene.range_zone.position)
	await skip_story()
	var theo_done := await wait_until(func(): return scene._phase == "theo_result", 6.0)
	check("Fase 1: Theo atira primeiro nos 4 alvos", theo_done)
	await skip_story()
	await skip_story()
	check("Fase 1: vez do Mark", scene._phase == "shooting", scene._phase)
	await teleport(scene.player, scene.weapon_rack.position + Vector2(30, 0))
	await tap("pickup")
	check("Fase 1: pega a arma na bancada", scene.has_weapon)
	for t in scene.targets:
		await _shoot_old(t)
	check("Fase 1: acerta os 4 alvos sem errar", scene._phase == "reaction" and not scene._player_any_miss, "fase=%s" % scene._phase)
	await expect_done("Fase 1")


func _fase2() -> void:
	await load_scene("res://missions/ato1_fase2_abordagem.tscn")
	await skip_story()
	await teleport(scene.player, scene.briefing_zone.position)
	await skip_story()
	check("Fase 2: briefing libera a porta", scene._phase == "approach_door", scene._phase)
	await teleport(scene.player, scene.door_body.position + Vector2(-35, 0))
	await hold("breach", 0.8)
	check("Fase 2: arrombar segurando entra em silêncio", scene._phase == "clearing" and not scene._breached_loud)
	for t in scene.threats:
		await _shoot_old(t)
	check("Fase 2: neutraliza as 3 ameaças sem acertar civil", scene._phase == "evaluation" and scene._non_threats_hit == 0, "fase=%s civis=%d" % [scene._phase, scene._non_threats_hit])
	await expect_done("Fase 2")


func _fase3() -> void:
	await load_scene("res://missions/ato1_fase3_direcao.tscn")
	await skip_story()
	await teleport(scene.player_car, scene.briefing_zone.position)
	await skip_story()
	check("Fase 3: briefing libera o circuito", scene._phase == "circuit", scene._phase)
	for cp in scene.checkpoints:
		await teleport(scene.player_car, cp.position)
	check("Fase 3: 3 checkpoints em ordem abrem o PIT", scene._phase == "pit_test", scene._phase)
	ib().press("handbrake")
	ib().press("accelerate")
	var pit := await wait_until(func():
		var t: CharacterBody2D = scene.target_car
		var fwd := Vector2.RIGHT.rotated(t.rotation)
		scene.player_car.position = t.position - fwd * 27.0
		scene.player_car.rotation = t.rotation
		scene.player_speed = 100.0
		return scene.pit_landed, 4.0)
	ib().reset()
	check("Fase 3: PIT por contato faz o alvo rodar", pit)
	await expect_done("Fase 3")


func _fase4() -> void:
	await load_scene("res://missions/ato1_fase4_formatura.tscn")
	await skip_story()
	await teleport(scene.player, scene.ceremony_zone.position)
	check("Fase 4: chegar na formatura começa a cerimônia", scene._phase == "ceremony", scene._phase)
	await expect_done("Fase 4")
