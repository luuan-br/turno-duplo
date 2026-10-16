class_name TestCase
extends Node
## Base dos testes automatizados (`tests/`). Cada arquivo `tests/test_*.gd`
## estende TestCase e implementa `run()` (pode usar await). O executor é
## `tests/run_tests.gd` — ver CLAUDE.md, seção Comandos.
##
## Os testes jogam as fases "por dentro": pulam diálogo, teleportam o
## jogador até zonas, apertam ações do InputBridge e conferem o estado.
## Pegam fase que não termina, flag que não grava, sistema que quebrou —
## NÃO pegam sensação de toque nem dificuldade (isso é teste no celular).

var results: Array[Dictionary] = []
var scene: Node
var _picks := 0


func run() -> void:
	pass


func check(name: String, ok: bool, extra := "") -> void:
	results.append({"name": name, "ok": ok, "extra": extra})


func ib() -> Node:
	return get_node("/root/InputBridge")


func gs() -> Node:
	return get_node("/root/GameState")


# ---------- tempo ----------

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func frames(n := 2) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame


func wait_until(cond: Callable, timeout := 5.0) -> bool:
	var end := Time.get_ticks_msec() + int(timeout * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await get_tree().process_frame
	return cond.call()


# ---------- cenas ----------

func load_scene(path: String) -> Node:
	if scene and is_instance_valid(scene):
		scene.queue_free()
		await frames(1)
	ib().reset()
	scene = load(path).instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await frames(3)
	return scene


## Depois de `restart_mission()`: espera a cena recarregar e passa a
## apontar pra nova.
func wait_reload(timeout := 4.0) -> bool:
	# Guarda o id, não o nó: a cena antiga é apagada no recomeço.
	var old_id := scene.get_instance_id()
	var ok := await wait_until(func(): return get_tree().current_scene != null and get_tree().current_scene.get_instance_id() != old_id, timeout)
	if ok:
		scene = get_tree().current_scene
		await frames(3)
	return ok


func cleanup() -> void:
	if scene and is_instance_valid(scene):
		scene.queue_free()
	scene = null
	ib().reset()


# ---------- interface ----------

## Pula a caixa de diálogo, se estiver aberta.
func skip_story() -> void:
	if scene.story and scene.story.visible:
		scene.story.skip()
	await frames(2)


## Pula diálogos em sequência até a fase sair de `phase` (ou acabar o tempo).
func skip_until_not(phase: String, timeout := 3.0) -> void:
	var end := Time.get_ticks_msec() + int(timeout * 1000.0)
	while scene._phase == phase and Time.get_ticks_msec() < end:
		await skip_story()


## Toque rápido numa ação, como um botão.
func tap(action: String) -> void:
	ib().press(action)
	ib().release(action)
	await frames(2)


## Segura uma ação (ARROMBAR devagar, LIBERTAR, ABRIR COFRE...).
func hold(action: String, seconds: float) -> void:
	ib().press(action)
	await wait(seconds)
	ib().release(action)
	await frames(2)


## Teleporta e espera a física rodar (zonas `body_entered` disparam).
func teleport(node: Node2D, pos: Vector2) -> void:
	node.position = pos
	await frames(3)


## Responde o interrogatório inteiro. `correct=false` erra de propósito.
func answer_interrogation(it: Control, correct := true) -> void:
	var guard := 0
	while it.visible and guard < 20:
		guard += 1
		var r: Dictionary = it._rounds[it._round]
		if correct:
			it._resolve(str(r["answer"]), str(r.get("evidence_id", "")))
		else:
			it._resolve("support" if r["answer"] == "press" else "press", "")
		it._on_continue()
		await frames(1)


## Liga todos os pares do Quadro de Evidências.
func solve_board(board: Control) -> bool:
	for i in board._pairs.size():
		var pair: Array = []
		for b in board._nodes:
			if board._node_pair_index[b] == i:
				pair.append(b)
		board._on_node_pressed(pair[0])
		board._on_node_pressed(pair[1])
	return await wait_until(func(): return not board.visible, 3.0)


# ---------- combate ----------

## Um ponto livre perto de `target` com linha de tiro limpa até ele.
func free_spot_near(target: Vector2, dist := 45.0, ignore: Array[RID] = []) -> Vector2:
	var space: PhysicsDirectSpaceState2D = scene.get_world_2d().direct_space_state
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	for i in 16:
		var dir := Vector2.RIGHT.rotated(TAU * i / 16.0)
		var p := target + dir * dist
		var q := PhysicsShapeQueryParameters2D.new()
		q.shape = circle
		q.transform = Transform2D(0.0, p)
		q.collide_with_areas = false
		q.exclude = ignore
		if not space.intersect_shape(q, 1).is_empty():
			continue
		var ray := PhysicsRayQueryParameters2D.create(p, target)
		ray.collide_with_areas = false
		ray.exclude = ignore
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or hit.collider is EnemyGuard:
			return p
	return target + Vector2(dist, 0)


## Derruba um guarda com o TacticalPlayer: chega perto, mira, atira.
func shoot_guard(player: TacticalPlayer, g: EnemyGuard) -> void:
	var ignore: Array[RID] = [player.get_rid(), g.get_rid()]
	player.position = free_spot_near(g.global_position, 45.0, ignore)
	player.facing = (g.global_position - player.position).normalized()
	await frames(2)
	await tap("shoot")


## Derruba todos os guardas vivos de uma CombatLayer.
func clear_guards(player: TacticalPlayer, combat: CombatLayer) -> void:
	for g in combat.guards:
		if not g.is_dead():
			await shoot_guard(player, g)
	await frames(2)


## Começo do combate: munição do ato ligada, pente cheio, RECARGA escondido.
func expect_ammo(label: String, mag: int, spare: int) -> void:
	var p: TacticalPlayer = scene.player
	check(label + ": munição do ato (%d no pente, %d de reserva)" % [mag, spare], p.uses_ammo() and p.mag_size == mag and p.mag == mag and p.reserve == spare, "%d/%d +%d" % [p.mag, p.mag_size, p.reserve])
	check(label + ": RECARGA escondido com pente cheio", not scene.reload_btn.visible)
	_picks = 0
	scene.combat.weapon_picked.connect(func(_n): _picks += 1)


## Depois de derrubar todos: cada guarda largou a arma. `clear_guards` pode
## encostar o Mark em cima da arma de um anterior — essas contam como pegas.
func expect_drops(label: String) -> void:
	var c: CombatLayer = scene.combat
	check(label + ": cada guarda derrubado largou a arma", c.drops.size() + _picks == c.guards.size(), "%d no chão, %d pegas" % [c.drops.size(), _picks])


# ---------- fim de fase ----------

## Pula diálogo até a fase chegar em "done" e confere o botão "Próxima Fase".
func expect_done(label: String) -> void:
	var end := Time.get_ticks_msec() + 4000
	while scene._phase != "done" and Time.get_ticks_msec() < end:
		await skip_story()
	check(label + ": chega ao fim com \"Próxima Fase\"", scene._phase == "done" and scene.next_btn.visible, "fase=%s" % scene._phase)
