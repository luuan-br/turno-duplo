extends Node
## Estado que atravessa cenas — autoload, então sobrevive a troca de cena
## (diferente de variável normal de script, que morre com a cena).
## Necessário a partir do Ato 2: GDD Seção 9 define medidores (reputação,
## relação com o Doyle) que se acumulam ao longo de vários turnos, não
## só dentro de uma missão isolada como no Ato 1.
##
## Deliberadamente simples — não é um sistema de save em disco (isso é
## pendência separada, pra quando o jogo precisar persistir entre
## sessões de verdade). Por ora só precisa sobreviver dentro da mesma
## sessão de jogo, trocando de cena.

var reputation: int = 0        ## força vs. de-escalação (Ato 2 Turno 1+)
var doyle_relationship: int = 0 ## medidor opcional (Ato 2 Turno 5)
var ghost_spotted: bool = false ## Turno 4 — plantou a pista do wheelman sem nome

var family_meter: int = 0       ## Ato 3 Fase 5 — jantar vs. ficar no caso
var informant_chosen: String = "" ## Ato 3 Fase 2 — "lou" ou "miko"
var doyle_fate: String = ""     ## Ato 3 Fase 6 — "entregue", "saida" ou "confronto"
var ghost_named: bool = false   ## Ato 3 Fase 4 — matrícula vira nome no quadro


func add_reputation(amount: int) -> void:
	reputation += amount


func add_doyle_relationship(amount: int) -> void:
	doyle_relationship += amount


func add_family_meter(amount: int) -> void:
	family_meter += amount
