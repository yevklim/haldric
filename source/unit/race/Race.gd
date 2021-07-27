extends Resource
class_name Race

export var id := ""

enum Gender {MALE, FEMALE}

export var male_singular := ""
export var female_singular := ""
export var singular := ""

export var plural := ""

export(String, MULTILINE) var description := ""

export(String, MULTILINE) var male_names := ""
export(String, MULTILINE) var female_names := ""

export var trait_count := 2

export(Array, PackedScene) var traits := []


func get_random_name(gender : int = Gender.MALE) -> String:
	randomize()
	var list
	match gender:
		Gender.MALE:
			list = male_names.split(",")
		Gender.FEMALE:
			list = female_names.split(",")
		_:
			list = [""]
	var name : String = list[randi() % list.size()]
	return name.strip_edges()


func get_random_traits() -> Array:
	var a := []

	while a.size() < trait_count and a.size() < traits.size():
		var trait = traits[randi() % traits.size()]
		if not a.has(trait):
			a.append(trait)

	return a
