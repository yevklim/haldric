extends Node


var scenes := {
	"TitleScreen": "res://source/menu/TitleScreen.tscn",
	"Game": "res://source/game/Game.tscn",
	"Editor": "res://source/menu/EditorScreen.tscn",
	"Editor/MapEditor": "res://source/editor/MapEditor.tscn",
	"Editor/UnitEditor": "res://source/interface/editor/UnitEditorUI.tscn",
	"Editor/ScenarioEditor": "",
	"Editor/CampaignEditor": "",
	"Editor/Misc": "",
	"ScenarioSelectionMenu": "res://source/menu/ScenarioSelectionMenu.tscn",
	"FactionSelectionMenu": "res://source/menu/FactionSelectionMenu.tscn",
}


func change(scene_name: String) -> void:
	if not scenes.has(scene_name):
		print("cannot change to scene %s" % scene_name)
		return

	get_tree().change_scene(scenes[scene_name])
