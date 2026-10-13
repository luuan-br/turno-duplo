extends TestCase
## Ato 3 (Emblema de Detetive) do começo ao fim de cada fase, e o
## encadeamento do interrogatório: o que o informante revela (Fase 2) muda
## a Vigilância (Fase 3) e o Quadro (Fase 4); a confissão do Doyle (Fase 6)
## chega ao Epílogo.


func run() -> void:
	gs().reset()
	await _fase1()
	await _fase2_lou_perfeito()
	await _fase3_com_rotina()
	await _fase4_com_pista_extra()
	await _fase5()
	await _fase6_doyle()
	await _fase7()
	await _fase8()
	await _fase2_miko_fechado()
	await _fase3_vigia_avisado()


func _fase1() -> void:
	await load_scene("res://missions/ato3_fase1_cena_revisitada.tscn")
	await skip_story()
	await teleport(scene.player, scene.clue_obj.position + Vector2(-35, 0))
	await tap("examine")
	check("Fase 1: examinar o roteador de novo", scene._examined)
	await expect_done("Fase 1")


func _fase2_lou_perfeito() -> void:
	gs().leads = []
	gs().informant_warned = false
	await load_scene("res://missions/ato3_fase2_ironside.tscn")
	await skip_story()
	await teleport(scene.player, scene.lou_marker.position)
	check("Fase 2: chegar no Lou escolhe o Lou", gs().informant_chosen == "lou")
	await skip_story()
	check("Fase 2: interrogatório do Lou abre", scene.interrogation.visible)
	await answer_interrogation(scene.interrogation, true)
	check("Fase 2: leitura perfeita arranca rotina e pista extra", "rotina_vigia" in gs().leads and "pista_extra" in gs().leads and not gs().informant_warned, str(gs().leads))
	await expect_done("Fase 2 (Lou)")


func _fase3_com_rotina() -> void:
	await load_scene("res://missions/ato3_fase3_vigilancia.tscn")
	check("Fase 3: com a rotina, o vigia faz pausa pra fumar", scene.smoke_breaks)
	await skip_story()
	# Vigia andando pra direita, Mark logo à frente dele (fora das sombras).
	scene.guard.position = scene.guard_from
	scene.guard_dir = 1
	scene._smoke_timer = 0.0
	await teleport(scene.player, scene.guard.position + Vector2(60, 0))
	check("Fase 3: ser visto fora da sombra faz o Mark recuar", scene._phase == "spotted_warning", scene._phase)
	await skip_story()
	check("Fase 3: ...e volta pro começo do beco", scene.player.position.distance_to(scene.start_pos) < 5.0 and scene._phase == "sneak")
	# Chegou na ponta: vira e para pra fumar, olhando pro muro.
	scene.guard.position = scene.guard_from
	scene.guard_dir = -1
	await wait(1.6)
	await teleport(scene.player, scene.guard.position + Vector2(60, 0))
	check("Fase 3: fumando, o vigia não vê o Mark bem na frente dele", scene._smoke_timer > 0.0 and scene._phase == "sneak", scene._phase)
	await teleport(scene.player, scene.vantage_zone.position)
	check("Fase 3: chegar no ponto de observação", scene._phase == "vantage", scene._phase)
	await expect_done("Fase 3")


func _fase4_com_pista_extra() -> void:
	await load_scene("res://missions/ato3_fase4_quadro.tscn")
	await skip_story()
	check("Fase 4: pista extra do informante vira um 5º par", scene.board._pairs.size() == 5, "pares=%d" % scene.board._pairs.size())
	check("Fase 4: ligar todos os pares fecha o quadro", await solve_board(scene.board))
	check("Fase 4: o Ghost ganha nome", gs().ghost_named)
	await expect_done("Fase 4")


func _fase5() -> void:
	gs().family_meter = 0
	await load_scene("res://missions/ato3_fase5_jantar.tscn")
	await skip_story()
	check("Fase 5: jantar termina numa escolha", scene.choice.visible)
	scene.choice._on_chosen(0)
	await frames(2)
	check("Fase 5: ficar pro jantar sobe o medidor de família", gs().family_meter == 1)
	await expect_done("Fase 5")


func _fase6_doyle() -> void:
	gs().doyle_relationship = 1
	gs().doyle_confessed = false
	await load_scene("res://missions/ato3_fase6_ligacao.tscn")
	await skip_story()
	check("Fase 6: relação 1 no Ato 2 dá paciência 2 pro Doyle", scene.interrogation._patience == 2, "paciência=%d" % scene.interrogation._patience)
	await answer_interrogation(scene.interrogation, true)
	check("Fase 6: ler certo faz o Doyle confessar a dívida", gs().doyle_confessed)
	await skip_story()
	check("Fase 6: escolha de 3 vias depois da conversa", scene.choice.visible and scene._phase == "choice")
	scene.choice._on_chosen(2)
	await frames(2)
	check("Fase 6: exigir que ele se entregue = destino confronto", gs().doyle_fate == "confronto")
	await expect_done("Fase 6")


func _fase7() -> void:
	await load_scene("res://missions/ato3_fase7_aviso.tscn")
	await skip_story()
	await teleport(scene.player, scene.envelope.position + Vector2(-35, 0))
	await tap("examine")
	check("Fase 7: examinar o envelope", scene._examined)
	await expect_done("Fase 7")


func _fase8() -> void:
	await load_scene("res://missions/ato3_fase8_descoberto.tscn")
	await skip_story()
	check("Fase 8: corrida pra casa começa", scene._phase == "run", scene._phase)
	await teleport(scene.player, scene.home_marker.position + Vector2(-30, 0))
	check("Fase 8: chegar em casa encontra o Theo", scene._phase == "arrived", scene._phase)
	await expect_done("Fase 8")


func _fase2_miko_fechado() -> void:
	gs().leads = []
	gs().informant_warned = false
	await load_scene("res://missions/ato3_fase2_ironside.tscn")
	await skip_story()
	await teleport(scene.player, scene.miko_marker.position)
	await skip_story()
	await answer_interrogation(scene.interrogation, false)
	check("Fase 2: errar tudo com o Miko faz ele se fechar e avisar o grupo", gs().informant_warned and gs().leads.is_empty(), str(gs().leads))
	await expect_done("Fase 2 (Miko fechado)")


func _fase3_vigia_avisado() -> void:
	await load_scene("res://missions/ato3_fase3_vigilancia.tscn")
	check("Fase 3: avisado, o vigia enxerga mais longe, anda mais rápido e não pausa", scene.cone_range > scene.CONE_RANGE and scene.guard_speed > scene.GUARD_SPEED and not scene.smoke_breaks)
