extends Node


var file_name = "preferences"
var user_path := "user://data/%s.dat"
var res_path := "res://data/%s.dat"

var properties: Dictionary = {}
var default_properties: Dictionary = {}


func _ready():
	_load()


func _exit_tree():
	_save_to_user()


func _set(property_name: String, value) -> bool:
	properties[property_name] = value

	_add_signals(property_name)
	emit_signal(property_name + "_changed", value)

	return true


func set_property_enabled(property_name: String, enabled: bool) -> bool:
	if properties.has(property_name) or default_properties.has(property_name):
		properties[property_name + "_enabled"] = enabled
		emit_signal(property_name + "_changed", get(property_name))
		return true

	return false


func _get(property_name: String):
	if properties.has(property_name):
		if get_enabled(property_name):
			return properties[property_name]

	if default_properties.has(property_name):
		return default_properties[property_name]
	
	return null


func get_enabled(property_name: String) -> bool:
	var enabled_name = property_name + "_enabled"

	if properties.has(enabled_name):
		return properties[enabled_name]

	if default_properties.has(enabled_name):
		return default_properties[enabled_name]
	
	return false


func _add_signals(property_names) -> void:
	if property_names is String:
		if property_names.ends_with("_enabled"):
			return
		var signal_name = property_names + "_changed"
		if not has_user_signal(signal_name):
			add_user_signal(signal_name, [{name: property_names}])

	if property_names is Array:
		for property in property_names:
			_add_signals(property as String)

	if property_names is Dictionary:
		_add_signals(property_names.keys())


func _load() -> void:
	_load_from_user()
	_load_from_res()


func _load_from_user() -> void:
	properties = _load_from(user_path % file_name)


func _load_from_res() -> void:
	default_properties = _load_from(res_path % file_name)


func _load_from(file_path: String) -> Dictionary:
	var file = File.new()
	if file.open(file_path, File.READ) != OK:
		return {}
	var file_content = file.get_as_text()
	file.close()

	var json_result := JSON.parse(file_content)
	if json_result.error != OK or typeof(json_result.result) != TYPE_DICTIONARY:
		return {}
	
	var loaded_properties = json_result.result as Dictionary

	_add_signals(loaded_properties)

	return loaded_properties


func _save_to_user() -> void:
	_save_to(user_path % file_name, properties)


func _save_to_res() -> void:
	_save_to(res_path % file_name, default_properties)


func _save_to(file_path: String, props: Dictionary) -> void:
	var file = File.new()
	if file.open(file_path, File.WRITE) != OK:
		return
	file.store_string(JSON.print(props))
	file.close()
