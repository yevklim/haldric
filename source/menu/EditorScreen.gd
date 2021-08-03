extends Panel


func _on_Back_pressed() -> void:
	Scene.change("TitleScreen")


func _on_UnitEditor_pressed() -> void:
	Scene.change("Editor/UnitEditor")


func _on_MapEditor_pressed() -> void:
	Scene.change("Editor/MapEditor")


func _on_ScenarioEditor_pressed() -> void:
	Scene.change("Editor/ScenarioEditor")


func _on_CampaignEditor_pressed() -> void:
	Scene.change("Editor/CampaignEditor")


func _on_Misc_pressed() -> void:
	Scene.change("Editor/Misc")
