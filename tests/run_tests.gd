extends SceneTree
## Executor dos testes automatizados. Roda todos os `tests/test_*.gd` (ou
## só os que tiverem um dos nomes passados depois de `--`), imprime OK/FALHA
## de cada verificação e sai com código 1 se alguma falhar.
##   godot --headless --path . --script res://tests/run_tests.gd
##   godot --headless --path . --script res://tests/run_tests.gd -- ato2 combate

const DIR := "res://tests/"


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var filters := Array(OS.get_cmdline_user_args())
	var files: Array = []
	for f in DirAccess.get_files_at(DIR):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			if filters.is_empty() or filters.any(func(x): return x in f):
				files.append(f)
	files.sort()

	# Disposição de controles: arquivo próprio dos testes e padrão de fábrica,
	# pra nunca gravar por cima da disposição salva de quem joga no PC.
	var layout = root.get_node("ControlLayout")
	layout.save_path = "user://controles_teste.cfg"
	layout.reset_defaults()

	var total := 0
	var failed := 0
	var start := Time.get_ticks_msec()
	for f in files:
		print("\n== %s" % f)
		# Sem tipo TestCase aqui de propósito: citar o tipo faz o Godot
		# compilar a cadeia TestCase → TacticalPlayer → InputBridge antes do
		# autoload existir (só no modo --script), e as missões quebram.
		var t = load(DIR + f).new()
		root.add_child(t)
		root.get_node("GameState").reset()
		layout.reset_defaults()
		await t.run()
		for r in t.results:
			total += 1
			if not r["ok"]:
				failed += 1
			print(("  OK     " if r["ok"] else "  FALHA  ") + str(r["name"]) + ("   (" + str(r["extra"]) + ")" if str(r["extra"]) != "" else ""))
		t.cleanup()
		t.queue_free()
		await process_frame

	print("\n%d verificações, %d falharam (%.0fs)" % [total, failed, (Time.get_ticks_msec() - start) / 1000.0])
	quit(1 if failed > 0 else 0)
