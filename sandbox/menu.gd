extends Control
## Menu do protótipo: escolhe qual sandbox/missão abrir.


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var title := Label.new()
	title.text = "TURNO DUPLO — protótipo"
	title.position = Vector2(40, 40)
	title.add_theme_font_size_override("font_size", 24)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Teste num celular Android real sempre que possível (touch no emulador/mouse não é confiável)."
	subtitle.position = Vector2(40, 80)
	add_child(subtitle)

	var mission1_btn := Button.new()
	mission1_btn.text = "Missão: Ato 1, Fase 1 — Chegada (conteúdo real)"
	mission1_btn.position = Vector2(40, 160)
	mission1_btn.custom_minimum_size = Vector2(500, 60)
	mission1_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://missions/ato1_fase1_chegada.tscn"))
	add_child(mission1_btn)

	var mission2_btn := Button.new()
	mission2_btn.text = "Missão: Ato 1, Fase 2 — Abordagem Tática (conteúdo real)"
	mission2_btn.position = Vector2(40, 240)
	mission2_btn.custom_minimum_size = Vector2(500, 60)
	mission2_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://missions/ato1_fase2_abordagem.tscn"))
	add_child(mission2_btn)

	var mission3_btn := Button.new()
	mission3_btn.text = "Missão: Ato 1, Fase 3 — Direção Defensiva (conteúdo real)"
	mission3_btn.position = Vector2(40, 320)
	mission3_btn.custom_minimum_size = Vector2(500, 60)
	mission3_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://missions/ato1_fase3_direcao.tscn"))
	add_child(mission3_btn)

	var tatico_btn := Button.new()
	tatico_btn.text = "Sandbox Tático (mover, cobertura, espiar, arrombar, mirar/atirar)"
	tatico_btn.position = Vector2(40, 400)
	tatico_btn.custom_minimum_size = Vector2(500, 60)
	tatico_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://sandbox/tatico.tscn"))
	add_child(tatico_btn)

	var chase_btn := Button.new()
	chase_btn.text = "Sandbox Perseguição (dirigir, freio de mão, PIT maneuver)"
	chase_btn.position = Vector2(40, 480)
	chase_btn.custom_minimum_size = Vector2(500, 60)
	chase_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://sandbox/perseguicao.tscn"))
	add_child(chase_btn)
