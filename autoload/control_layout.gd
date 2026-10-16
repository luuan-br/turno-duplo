extends Node
## Disposição dos botões touch, configurável pelo jogador (GDD Seção 8,
## "Layout de controles configurável"). Cada botão de missão pertence a um
## "lugar" (slot) — mudar o lugar vale pra todas as fases. Os manches são
## flutuantes (aparecem onde o dedo toca), então não têm posição a guardar.
##
## Posição = centro do botão medido a partir do canto inferior DIREITO da
## tela (em pixels da tela base), mais o diâmetro. Os padrões são a
## disposição validada no celular (8 rodadas de teste de controle).
## Sobrevive a fechar o jogo: salvo em `save_path`.

const MIN_GAP := 8.0
const SIZE_MIN := 56.0
const SIZE_MAX := 150.0
## "< Menu" (canto inferior esquerdo, em toda missão) — nenhum botão pode
## ficar em cima dele. Retângulo a partir do canto inferior ESQUERDO.
const MENU_RECT := Rect2(16, 10, 114, 50)

const SLOTS := {
	"acao_principal": {"mode": "pe", "label": "ATIRAR / AÇÃO", "center": Vector2(80, 230), "size": 100.0},
	"acao_secundaria": {"mode": "pe", "label": "RECARGA", "center": Vector2(80, 110), "size": 72.0},
	"carro_acelerar": {"mode": "carro", "label": "ACELERAR", "center": Vector2(85, 85), "size": 110.0},
	"carro_frear": {"mode": "carro", "label": "FREAR", "center": Vector2(210, 90), "size": 100.0},
	"carro_extra": {"mode": "carro", "label": "FREIO / TIRO", "center": Vector2(85, 215), "size": 110.0},
}

var save_path := "user://controles.cfg"
var _custom := {}


func _ready() -> void:
	load_layout()


## Lugar padrão de cada ação. Exceção conhecida: "shoot" dirigindo (tiro no
## pneu, Ato 4 Fase 2) é "carro_extra" — a missão define na mão.
func slot_for_action(action: String) -> String:
	match action:
		"accelerate":
			return "carro_acelerar"
		"brake":
			return "carro_frear"
		"handbrake", "rear_shoot":
			return "carro_extra"
		"reload":
			return "acao_secundaria"
	return "acao_principal"


func slots_for_mode(mode: String) -> Array:
	var out: Array = []
	for s in SLOTS:
		if SLOTS[s]["mode"] == mode:
			out.append(s)
	return out


func center_of(slot: String) -> Vector2:
	return _custom[slot]["center"] if _custom.has(slot) else SLOTS[slot]["center"]


func size_of(slot: String) -> float:
	return _custom[slot]["size"] if _custom.has(slot) else SLOTS[slot]["size"]


func set_placement(slot: String, center: Vector2, diameter: float) -> void:
	_custom[slot] = {"center": center, "size": clampf(diameter, SIZE_MIN, SIZE_MAX)}


func is_custom() -> bool:
	return not _custom.is_empty()


func reset_defaults() -> void:
	_custom.clear()


## Posiciona um botão (`ui/contextual_button.gd`) no lugar dele.
func apply(btn: Control, slot: String) -> void:
	if not SLOTS.has(slot):
		return
	var c := center_of(slot)
	var d := size_of(slot)
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left = -c.x - d * 0.5
	btn.offset_right = -c.x + d * 0.5
	btn.offset_top = -c.y - d * 0.5
	btn.offset_bottom = -c.y + d * 0.5
	btn.radius = d * 0.5


## Problemas que impedem salvar uma disposição de um modo, numa tela de
## `screen` pixels: botões encostados (disputariam o mesmo dedo — bug real
## no celular, 3 vezes) ou em cima do "< Menu". Vazio = pode salvar.
func problems(mode: String, screen: Vector2) -> Array[String]:
	var out: Array[String] = []
	for p in _check(mode, screen):
		out.append(p["msg"])
	return out


## Lugares envolvidos em algum problema (o editor pinta de vermelho).
func conflicting_slots(mode: String, screen: Vector2) -> Array:
	var out: Array = []
	for p in _check(mode, screen):
		for s in p["slots"]:
			if not s in out:
				out.append(s)
	return out


func _check(mode: String, screen: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var slots := slots_for_mode(mode)
	for i in slots.size():
		for j in range(i + 1, slots.size()):
			var a: String = slots[i]
			var b: String = slots[j]
			if center_of(a).distance_to(center_of(b)) < (size_of(a) + size_of(b)) * 0.5 + MIN_GAP:
				out.append({"slots": [a, b], "msg": tr("%s e %s estão encostados — disputariam o mesmo dedo.") % [tr(SLOTS[a]["label"]), tr(SLOTS[b]["label"])]})
	# O "< Menu" fica no canto inferior esquerdo: convertido pra medida a
	# partir do canto inferior direito, como os centros.
	var menu := Rect2(Vector2(screen.x - MENU_RECT.position.x - MENU_RECT.size.x, MENU_RECT.position.y), MENU_RECT.size)
	for s in slots:
		var c := center_of(s)
		var nearest := Vector2(clampf(c.x, menu.position.x, menu.end.x), clampf(c.y, menu.position.y, menu.end.y))
		if nearest.distance_to(c) < size_of(s) * 0.5 + MIN_GAP:
			out.append({"slots": [s], "msg": tr("%s está em cima do \"< Menu\".") % tr(SLOTS[s]["label"])})
	return out


func save_layout() -> void:
	var cfg := ConfigFile.new()
	for s in _custom:
		cfg.set_value(s, "center", _custom[s]["center"])
		cfg.set_value(s, "size", _custom[s]["size"])
	cfg.save(save_path)


func load_layout() -> void:
	_custom.clear()
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	for s in cfg.get_sections():
		if SLOTS.has(s):
			set_placement(s, cfg.get_value(s, "center", SLOTS[s]["center"]), cfg.get_value(s, "size", SLOTS[s]["size"]))
