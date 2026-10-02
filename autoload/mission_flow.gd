extends Node
## Ordem canônica de toda a campanha — resolve um atrito explícito do
## usuário depois de ter testado o fluxo fase-por-fase do Ato 2/3: ter
## que voltar pro menu e rolar a lista até achar a próxima missão toda
## vez que uma termina. Cada missão, ao chegar no estado concluído,
## mostra um botão "Próxima Fase >" que chama `advance()` — navegação
## em sequência, sem abandonar o menu como jeito de escolher LIVREMENTE
## uma missão específica (ele continua existindo, só deixou de ser
## obrigatório entre uma fase e a seguinte).

const ORDER := [
	"res://missions/ato1_fase1_chegada.tscn",
	"res://missions/ato1_fase2_abordagem.tscn",
	"res://missions/ato1_fase3_direcao.tscn",
	"res://missions/ato1_fase4_formatura.tscn",
	"res://missions/ato2_turno1_a_dupla.tscn",
	"res://missions/ato2_turno2_furto.tscn",
	"res://missions/ato2_turno3_corrida.tscn",
	"res://missions/ato2_turno4_semaforo.tscn",
	"res://missions/ato2_turno5_fora_de_servico.tscn",
	"res://missions/ato2_turno6_incidente.tscn",
	"res://missions/ato3_fase1_cena_revisitada.tscn",
	"res://missions/ato3_fase2_ironside.tscn",
	"res://missions/ato3_fase3_vigilancia.tscn",
	"res://missions/ato3_fase4_quadro.tscn",
	"res://missions/ato3_fase5_jantar.tscn",
	"res://missions/ato3_fase6_ligacao.tscn",
	"res://missions/ato3_fase7_aviso.tscn",
	"res://missions/ato3_fase8_descoberto.tscn",
	"res://missions/ato4_fase1_infiltrar.tscn",
	"res://missions/ato4_fase2_perseguicao.tscn",
	"res://missions/ato4_fase3_extracao.tscn",
	"res://missions/ato4_fase4_luzes.tscn",
	"res://missions/ato4_fase5_cofre.tscn",
	"res://missions/ato4_fase6_arquiteto.tscn",
	"res://missions/ato4_epilogo.tscn",
]

const MENU_PATH := "res://sandbox/menu.tscn"


## Caminho da próxima missão, ou "" se `current_path` for a última (ou
## não estiver na lista — ex.: chamado de dentro do sandbox).
func next_scene_path(current_path: String) -> String:
	var idx := ORDER.find(current_path)
	if idx == -1 or idx + 1 >= ORDER.size():
		return ""
	return ORDER[idx + 1]


## Troca de cena pra próxima missão; se não houver próxima (fim de
## campanha), volta pro menu em vez de travar a tela.
func advance(current_path: String) -> void:
	var next_path := next_scene_path(current_path)
	get_tree().change_scene_to_file(next_path if next_path != "" else MENU_PATH)


## true quando `current_path` é a última entrada da campanha — usado
## pra trocar o texto do botão de "Próxima Fase" pra algo que não
## prometa uma fase que não existe.
func is_last(current_path: String) -> bool:
	return next_scene_path(current_path) == ""
