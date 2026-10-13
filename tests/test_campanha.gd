extends TestCase
## Estrutura da campanha: toda cena da ordem existe e abre, todo item do
## menu aponta pra uma cena que existe, e nenhuma fala ficou com texto de
## "ainda não foi construído" (já aconteceu: sobrou isso no Ato 1 depois
## que o resto foi construído).

const STALE := ["ainda não foi construíd", "ainda não existe"]


func run() -> void:
	var mf := get_node("/root/MissionFlow")
	for path in mf.ORDER:
		var ok: bool = ResourceLoader.exists(path)
		if ok:
			await load_scene(path)
			ok = scene != null and scene.get("_phase") != null
		check("abre: " + path.get_file(), ok)

	var menu: GDScript = load("res://sandbox/menu.gd")
	for entry in menu.get_script_constant_map()["ENTRIES"]:
		check("menu aponta pra cena que existe: " + str(entry[1]).get_file(), ResourceLoader.exists(str(entry[1])))

	for f in DirAccess.get_files_at("res://missions/"):
		if not f.ends_with(".gd"):
			continue
		var text := FileAccess.get_file_as_string("res://missions/" + f)
		var stale := ""
		for line in text.split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			for s in STALE:
				if s in line:
					stale = line.strip_edges()
		check("sem fala desatualizada: " + f, stale == "", stale)
