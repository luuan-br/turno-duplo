extends Control
## Menu do protótipo: escolhe qual sandbox/missão abrir. Lista rolável
## (ScrollContainer) — virou necessário a partir do Ato 2, são muitos
## botões pra caber numa tela de celular sem rolar.

## Cada entrada: [texto do botão, caminho da cena]. Adicionar missão
## nova = acrescentar uma linha aqui, nada mais.
const ENTRIES := [
	["Missão: Ato 1, Fase 1 — Chegada", "res://missions/ato1_fase1_chegada.tscn"],
	["Missão: Ato 1, Fase 2 — Abordagem Tática", "res://missions/ato1_fase2_abordagem.tscn"],
	["Missão: Ato 1, Fase 3 — Direção Defensiva", "res://missions/ato1_fase3_direcao.tscn"],
	["Missão: Ato 1, Fase 4 — Avaliação Final / Formatura", "res://missions/ato1_fase4_formatura.tscn"],
	["Missão: Ato 2, Turno 1 — A Dupla", "res://missions/ato2_turno1_a_dupla.tscn"],
	["Missão: Ato 2, Turno 2 — O Furto que Não Era Nada", "res://missions/ato2_turno2_furto.tscn"],
	["Missão: Ato 2, Turno 3 — Corrida a Pé", "res://missions/ato2_turno3_corrida.tscn"],
	["Missão: Ato 2, Turno 4 — Semáforo Cego", "res://missions/ato2_turno4_semaforo.tscn"],
	["Missão: Ato 2, Turno 5 — Fora de Serviço", "res://missions/ato2_turno5_fora_de_servico.tscn"],
	["Missão: Ato 2, Turno 6 — O Incidente", "res://missions/ato2_turno6_incidente.tscn"],
	["Missão: Ato 3, Fase 1 — A Cena Revisitada", "res://missions/ato3_fase1_cena_revisitada.tscn"],
	["Missão: Ato 3, Fase 2 — Ironside, de Novo", "res://missions/ato3_fase2_ironside.tscn"],
	["Missão: Ato 3, Fase 3 — Vigilância", "res://missions/ato3_fase3_vigilancia.tscn"],
	["Missão: Ato 3, Fase 4 — O Quadro de Evidências", "res://missions/ato3_fase4_quadro.tscn"],
	["Missão: Ato 3, Fase 5 — Jantar Perdido", "res://missions/ato3_fase5_jantar.tscn"],
	["Missão: Ato 3, Fase 6 — A Ligação Impossível", "res://missions/ato3_fase6_ligacao.tscn"],
	["Missão: Ato 3, Fase 7 — O Aviso", "res://missions/ato3_fase7_aviso.tscn"],
	["Missão: Ato 3, Fase 8 — Descoberto", "res://missions/ato3_fase8_descoberto.tscn"],
	["Sandbox Tático (mover, cobertura, espiar, arrombar, mirar/atirar)", "res://sandbox/tatico.tscn"],
	["Sandbox Perseguição (dirigir, freio de mão, PIT maneuver)", "res://sandbox/perseguicao.tscn"],
]


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var title := Label.new()
	title.text = "TURNO DUPLO — protótipo"
	title.position = Vector2(40, 24)
	title.add_theme_font_size_override("font_size", 24)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Teste num celular Android real sempre que possível (touch no emulador/mouse não é confiável)."
	subtitle.position = Vector2(40, 60)
	subtitle.size = Vector2(880, 40)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.anchor_left = 0.0
	scroll.anchor_right = 1.0
	scroll.anchor_top = 0.0
	scroll.anchor_bottom = 1.0
	scroll.offset_top = 110
	scroll.offset_bottom = -10
	scroll.offset_left = 30
	scroll.offset_right = -30
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for entry in ENTRIES:
		var label: String = entry[0]
		var path: String = entry[1]
		var btn := Button.new()
		btn.text = label
		btn.custom_minimum_size = Vector2(0, 60)
		btn.pressed.connect(func(): get_tree().change_scene_to_file(path))
		list.add_child(btn)

	# Espaço no fim pra não cortar o último botão colado na borda.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	list.add_child(spacer)
