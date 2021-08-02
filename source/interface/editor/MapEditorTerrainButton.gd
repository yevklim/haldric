extends Button
class_name MapEditorTerrainButton

var texture : Texture = null setget _set_texture

onready var rect := $TextureRect


static func instance() -> MapEditorTerrainButton:
	return load("res://source/interface/editor/MapEditorTerrainButton.tscn").instance() as MapEditorTerrainButton


func _ready() -> void:
	_set_texture(texture)


func _set_texture(tex: Texture) -> void:
	texture = tex
	if rect:
		rect.texture = tex
