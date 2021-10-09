extends Container

signal current_animation_changed
var current_animation: UnitAnimation
export(Array, Animation) var animations = []

var copied_keyframes = {}

var unknown_unit_texture : Texture = load("res://assets/graphics/images/units/unknown-unit.png")

onready var LeftContainer = $LeftContainer
onready var RightContainer = $RightContainer

onready var AnimationsList = $LeftContainer/AnimationsList as ItemList
onready var AddAnimationBtn = $LeftContainer/ButtonsContainer/AddAnimationBtn
onready var RemoveAnimationBtn = $LeftContainer/ButtonsContainer/RemoveAnimationBtn

onready var AnimationNameEdit = $RightContainer/HBoxContainer/VBoxContainer/AnimationNameEdit
onready var AnimationLengthEdit = $RightContainer/HBoxContainer/VBoxContainer2/AnimationLengthEdit

onready var FramesAddBtn = $RightContainer/ButtonsContainer/FramesAddBtn
onready var FramesAddPopup = FramesAddBtn.get_popup()
onready var FramesAddPopup_Properties := { track_path = UnitAnimation.Tracks.texture, with_shift = true }

onready var FramesRemoveBtn = $RightContainer/ButtonsContainer/FramesRemoveBtn
onready var FramesRemovePopup = FramesRemoveBtn.get_popup()

onready var EventsMenuBtn = $RightContainer/HBoxContainer/EventsMenuBtn as MenuButton
onready var EventsPopup = EventsMenuBtn.get_popup()

onready var TerrainTypesMenuBtn = $RightContainer/HBoxContainer/TerrainTypesMenuBtn as MenuButton
onready var TerrainTypesPopup = TerrainTypesMenuBtn.get_popup()

onready var FrequencySpinBox = $RightContainer/HBoxContainer/VBoxContainer4/FrequencySpinBox as SpinBox
onready var HitsOptionBtn = $RightContainer/HBoxContainer/VBoxContainer5/HitsOptionBtn as OptionButton

onready var AnimationTrackEditor = $RightContainer/ScrollContainer/AnimationTrackEditor

onready var FrameTextureDialog = $FrameTextureDialog
onready var FrameSoundDialog = $FrameSoundDialog

onready var FramePropertiesEditor = $RightContainer/FramePropertiesEditor
onready var FrameTextureChooserBtn = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/TextureChooserBtn
onready var FrameColorPickerBtn = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/ColorPickerButton
onready var FrameSoundChooserBtn = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/SoundChooserBtn
onready var FrameKeyPointContainer = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/KeyPointContainer
onready var FrameKeyPointLineEdit = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/KeyPointContainer/LineEdit
onready var FrameTimeContainer = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/TimeContainer
onready var FrameTimeSpinBox = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/TimeContainer/SpinBox
onready var FrameDurationContainer = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/DurationContainer
onready var FrameDurationSpinBox = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/DurationContainer/SpinBox
onready var FrameInterpolationTypeContainer = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/InterpolationTypeContainer
onready var FrameInterpolationTypeOptionBtn = $RightContainer/FramePropertiesEditor/VBoxContainer/HBoxContainer/InterpolationTypeContainer/OptionButton

onready var HexDirectionPicker = $LeftContainer/HexDirectionPicker


func _ready():
	connect("current_animation_changed", self, "_on_current_animation_changed")
	resetAnimationsList()
	_gui_setup()


func _gui_setup():
	if not current_animation:
		RightContainer.visible = false

	if not AnimationTrackEditor.is_connected("nothing_selected", self, "_show_frame_properties"):
		AnimationTrackEditor.connect("nothing_selected", self, "_show_frame_properties")

	if not AnimationTrackEditor.is_connected("animation_changed", self, "_show_frame_properties"):
		AnimationTrackEditor.connect("animation_changed", self, "_show_frame_properties")

	if not AnimationLengthEdit.get_line_edit().is_connected("text_entered", self, "_on_AnimationLengthEdit_text_entered"):
		AnimationLengthEdit.get_line_edit().connect("text_entered", self, "_on_AnimationLengthEdit_text_entered")
	
	if not FramesAddPopup.is_connected("index_pressed", self, "_on_FramesAddPopup_index_pressed"):
		FramesAddPopup.connect("index_pressed", self, "_on_FramesAddPopup_index_pressed")
		FramesAddPopup.hide_on_checkable_item_selection = false

	if not FramesRemovePopup.is_connected("index_pressed", self, "_on_FramesRemovePopup_index_pressed"):
		FramesRemovePopup.connect("index_pressed", self, "_on_FramesRemovePopup_index_pressed")

	EventsPopup.hide_on_checkable_item_selection = false
	EventsPopup.clear()
	for event in UnitAnimation.Events.keys():
		EventsPopup.add_check_item(event, UnitAnimation.Events[event])
	if not EventsPopup.is_connected("index_pressed", self, "_gui_triggers"):
		EventsPopup.connect("index_pressed", self, "_gui_triggers")

	HitsOptionBtn.clear()
	for hit in UnitAnimation.Hits.keys():
		HitsOptionBtn.add_item(hit, UnitAnimation.Hits[hit])

	if not FrequencySpinBox.get_line_edit().is_connected("text_entered", self, "_on_FrameDurationSpinBox_text_entered"):
		FrequencySpinBox.get_line_edit().connect("text_entered", self, "_on_FrameDurationSpinBox_text_entered")

	if not FrameDurationSpinBox.get_line_edit().is_connected("text_entered", self, "_on_FrameDurationSpinBox_value_changed"):
		FrameDurationSpinBox.get_line_edit().connect("text_entered", self, "_on_FrameDurationSpinBox_value_changed")

	if not FrameTimeSpinBox.get_line_edit().is_connected("text_entered", self, "_on_FrameTimeSpinBox_value_changed"):
		FrameTimeSpinBox.get_line_edit().connect("text_entered", self, "_on_FrameTimeSpinBox_value_changed")

	_show_frame_properties()


func _gui_clear():
	RightContainer.visible = false
	_gui_setup()
	_gui_reset_triggers()


func _gui_reset_triggers():
	var id
	var checked = false
	for idx in EventsPopup.get_item_count():
		if current_animation:
			id = EventsPopup.get_item_id(idx)
			checked = current_animation.event.has(id)
		EventsPopup.set_item_checked(idx, checked)


func _gui_triggers(idx: int):
	if not current_animation:
		return

	var checked = not EventsPopup.is_item_checked(idx)
	var id = EventsPopup.get_item_id(idx)
	EventsPopup.set_item_checked(idx, checked)
	if checked and not current_animation.event.has(id):
		current_animation.event.append(id)
	elif not checked and current_animation.event.has(id):
		current_animation.event.erase(id)


func new_animation():
	var new_anim = UnitAnimation.new()
	new_anim.name = "Animation %s" % (animations.size() + 1)
	new_anim.resource_name = new_anim.name
	new_anim.length = 0
	animations.append(new_anim)
	AnimationsList.add_item(new_anim.name)


func remove_animation():
	if not current_animation:
		return

	var idx = animations.find(current_animation)
	AnimationsList.remove_item(idx)
	animations.remove(idx)
	if animations.size():
		idx = clamp(idx, 0, animations.size() - 1)
		current_animation = animations[idx]
		emit_signal("current_animation_changed")
		AnimationsList.select(idx)
		_on_AnimationsList_item_activated(idx)
	else:
		current_animation = null
		_gui_clear()


func resetAnimationsList(selected := -1):
	if selected < 0:
		var selected_items = AnimationsList.get_selected_items()
		if selected_items.size():
			selected = selected_items[0]
	AnimationsList.clear()
	for anim in animations:
		if anim is UnitAnimation:
			AnimationsList.add_item(anim.name)
	if selected >= 0:
		AnimationsList.select(selected)


func _on_current_animation_changed():
	AnimationNameEdit.text = current_animation.name
	_animation_length_changed()
	FrequencySpinBox.value = current_animation.frequency
	HitsOptionBtn.selected = current_animation.hits[0]
	_gui_reset_triggers()
	RightContainer.visible = true
	AnimationTrackEditor.animation = current_animation


func _animation_length_changed():
	if current_animation:
		AnimationLengthEdit.value = round(current_animation.length * 1000)


func _on_AnimationsList_item_activated(idx: int):
	var activated_animation = animations[idx]
	if current_animation != activated_animation:
		current_animation = animations[idx]
		emit_signal("current_animation_changed")
	preview_animation(0.0, true)


func preview_animation(time_offset := 0.0, play := false):
	if not HexDirectionPicker.animation_player.has_animation(current_animation.name):
		HexDirectionPicker.animation_player.add_animation(current_animation.name, current_animation)

	HexDirectionPicker.current_animation = current_animation

	HexDirectionPicker.animation_player.play(current_animation.name)
	if not play:
		HexDirectionPicker.animation_player.stop(false)
	HexDirectionPicker.animation_player.seek(time_offset, true)


func _on_AnimationTrackEditor_multi_selected(track_idx, key_idx, selected = true):
	var track_path = current_animation.track_get_path(track_idx) as String
	if selected == false:
		if AnimationTrackEditor.selected_keyframes[track_path].size():
			key_idx = AnimationTrackEditor.selected_keyframes[track_path][-1]
		else:
			_show_frame_properties()
			return
	#REWORK

	set_meta("dont_accept_value_changed", true)

	match track_path:
		UnitAnimation.Tracks.key_point:
			var key_point_name = current_animation.track_get_key_value(track_idx, key_idx)
			FrameKeyPointLineEdit.text = key_point_name
		UnitAnimation.Tracks.texture:
			var icon = current_animation.track_get_key_value(track_idx, key_idx)
			FrameTextureDialog.current_path = icon.resource_path
			FrameTextureChooserBtn.icon = icon
			FrameTextureChooserBtn.hint_tooltip = icon.resource_path
		UnitAnimation.Tracks.modulate:
			var modulate = current_animation.track_get_key_value(track_idx, key_idx)
			FrameColorPickerBtn.color = modulate
			FrameInterpolationTypeOptionBtn.select(current_animation.track_get_interpolation_type(track_idx))
		UnitAnimation.Tracks.audio:
			var stream = current_animation.track_get_key_value(track_idx, key_idx).stream
			FrameSoundChooserBtn.text = stream.resource_path if stream else "res://"
		_:
			pass

	FrameTimeSpinBox.value = current_animation.track_get_key_time_msec(track_idx, key_idx)
	FrameDurationSpinBox.value = current_animation.track_get_key_duration_msec(track_idx, key_idx)

	_show_frame_properties()

	preview_animation(current_animation.track_get_key_time(track_idx, key_idx))

	remove_meta("dont_accept_value_changed")


func _on_AnimationTrackEditor_cursor_time_changed(time):
	preview_animation(time)


func _on_AddAnimationBtn_pressed():
	new_animation()
	var idx = animations.size() - 1
	AnimationsList.select(idx)
	current_animation = animations[idx]
	emit_signal("current_animation_changed") 


func _on_RemoveAnimationBtn_pressed():
	remove_animation()


func _on_FramesAddPopup_index_pressed(idx):
	var item_text = FramesAddPopup.get_item_text(idx)
	match item_text:
		"Key point":
			FramesAddPopup.set_item_checked(idx, true)
			FramesAddPopup.set_item_checked(idx + 1, false)
			FramesAddPopup.set_item_checked(idx + 2, false)
			FramesAddPopup.set_item_checked(idx + 3, false)
			FramesAddPopup_Properties["track_path"] = UnitAnimation.Tracks.key_point
		"Texture":
			FramesAddPopup.set_item_checked(idx - 1, false)
			FramesAddPopup.set_item_checked(idx, true)
			FramesAddPopup.set_item_checked(idx + 1, false)
			FramesAddPopup.set_item_checked(idx + 2, false)
			FramesAddPopup_Properties["track_path"] = UnitAnimation.Tracks.texture
		"Modulate":
			FramesAddPopup.set_item_checked(idx - 2, false)
			FramesAddPopup.set_item_checked(idx - 1, false)
			FramesAddPopup.set_item_checked(idx, true)
			FramesAddPopup.set_item_checked(idx + 1, false)
			FramesAddPopup_Properties["track_path"] = UnitAnimation.Tracks.modulate
		"Sound":
			FramesAddPopup.set_item_checked(idx - 3, false)
			FramesAddPopup.set_item_checked(idx - 2, false)
			FramesAddPopup.set_item_checked(idx - 1, false)
			FramesAddPopup.set_item_checked(idx, true)
			FramesAddPopup_Properties["track_path"] = UnitAnimation.Tracks.audio
		"With Shift":
			FramesAddPopup.set_item_checked(idx, true)
			FramesAddPopup.set_item_checked(idx + 1, false)
			FramesAddPopup_Properties["with_shift"] = true
		"Without Shift":
			FramesAddPopup.set_item_checked(idx - 1, false)
			FramesAddPopup.set_item_checked(idx, true)
			FramesAddPopup_Properties["with_shift"] = false
			
	if idx == FramesAddPopup.get_item_count() - 1:
		AnimationTrackEditor.new_keyframe(FramesAddPopup_Properties["track_path"], FramesAddPopup_Properties["with_shift"])


func _on_FramesRemovePopup_index_pressed(idx):
	var with_shift = idx == 0
	AnimationTrackEditor.remove_keyframe(with_shift)


func _on_AnimationNameEdit_text_entered(new_text):
	if not current_animation or new_text == current_animation.name:
		return

	var new_name = new_text.strip_edges()
	if new_name.length() > 0:
		current_animation.name = new_name
		current_animation.resource_name = new_name
	resetAnimationsList()


func _on_AnimationLengthEdit_value_changed(value: float):
	if not current_animation:
		return

	var new_length = value / 1000
	if not is_equal_approx(new_length, current_animation.length):
		current_animation.length = new_length
		AnimationTrackEditor.update()


func _on_AnimationLengthEdit_text_entered(value):
	_on_AnimationLengthEdit_value_changed(value as float)


func _on_FrequencySpinBox_value_changed(value):
	if not current_animation:
		return

	if current_animation.frequency != value:
		current_animation.frequency = value


func _on_HitsOptionBtn_item_selected(index):
	if not current_animation:
		return
	var id = HitsOptionBtn.get_item_id(index)
	print("current_animation.hits = %s" % id)
	current_animation.hits = id


func _show_frame_properties(_track_path: String = "") -> void:
	var selected_tracks = AnimationTrackEditor.get_selected_tracks()
	if selected_tracks.size() == 0:
		FramePropertiesEditor.visible = false
	else:
		var track_path = selected_tracks[0] if selected_tracks.size() == 1 else ""
		FramePropertiesEditor.visible = true

		FrameKeyPointContainer.visible = track_path == UnitAnimation.Tracks.key_point
		FrameTextureChooserBtn.visible = track_path == UnitAnimation.Tracks.texture
		FrameColorPickerBtn.visible = track_path == UnitAnimation.Tracks.modulate
		FrameSoundChooserBtn.visible = track_path == UnitAnimation.Tracks.audio

		FrameTimeContainer.visible = selected_tracks.size() == 1 and AnimationTrackEditor.selected_keyframes[track_path].size() == 1
		FrameDurationContainer.visible = true
		FrameInterpolationTypeContainer.visible = track_path == UnitAnimation.Tracks.modulate


func _FrameTextureDialog_show():
	FrameTextureDialog.popup_centered()


func _FrameSoundDialog_show():
	FrameSoundDialog.popup_centered()


func _on_FrameTextureDialog_file_selected(path):
	if not current_animation:
		return

	var track_path = UnitAnimation.Tracks.texture
	var track_idx = current_animation.find_track(track_path)

	var texture = load(path) as Texture
	FrameTextureChooserBtn.icon = texture
	FrameTextureChooserBtn.hint_tooltip = path

	for key_idx in AnimationTrackEditor.selected_keyframes[track_path]:
		current_animation.track_set_key_value(track_idx, key_idx, texture)
	AnimationTrackEditor.update()
	pass


func _on_FrameSoundDialog_file_selected(path):
	if not current_animation:
		return

	var track_path = UnitAnimation.Tracks.audio
	var track_idx = current_animation.find_track(track_path)

	var audio_stream = load(path) as AudioStream
	FrameSoundChooserBtn.text = path

	for key_idx in AnimationTrackEditor.selected_keyframes[track_path]:
		current_animation.audio_track_set_key_stream(track_idx, key_idx, audio_stream)
	AnimationTrackEditor.update()


func _on_FrameKeyPointLineEdit_text_entered(new_text):
	if not current_animation or not new_text.length():
		return

	var track_path = UnitAnimation.Tracks.key_point
	var track_idx = current_animation.find_track(track_path)

	if not AnimationTrackEditor.selected_keyframes[track_path].size():
		return

	var key_idx = AnimationTrackEditor.selected_keyframes[track_path][0]
	current_animation.track_set_key_value(track_idx, key_idx, new_text)
	AnimationTrackEditor.update()


func _on_ColorPickerButton_color_changed(color):
	if not current_animation:
		return

	var track_path = UnitAnimation.Tracks.modulate
	var track_idx = current_animation.find_track(track_path)
	for key_idx in AnimationTrackEditor.selected_keyframes[track_path]:
		current_animation.track_set_key_value(track_idx, key_idx, color)
	AnimationTrackEditor.update()


func _keyframe_set_time(value: float):
	if not current_animation or has_meta("dont_accept_value_changed"):
		return

	var track_idx = -1
	var selected
	for track in AnimationTrackEditor.Tracks:
		if AnimationTrackEditor.selected_keyframes[track].size() == 1:
			if track_idx >= 0:
				return
			track_idx = current_animation.find_track(track)
			selected = AnimationTrackEditor.selected_keyframes[track]
	if track_idx == -1:
		return

	var dest_idx = current_animation.track_find_key(track_idx, value, true)
	if dest_idx == -1:	
		current_animation.track_set_key_time(track_idx, selected[0], value)

	var key_idx = current_animation.track_find_key(track_idx, value)
	if key_idx != -1:
		set_meta("dont_accept_value_changed", true)
		FrameDurationSpinBox.value = current_animation.track_get_key_duration_msec(track_idx, key_idx)
		remove_meta("dont_accept_value_changed")

	AnimationTrackEditor.update()

	
func _keyframes_set_duration(value: float):
	if not current_animation or has_meta("dont_accept_value_changed"):
		return

	for track_path in AnimationTrackEditor.Tracks:
		var track_idx = current_animation.find_track(track_path)
		for key_idx in AnimationTrackEditor.selected_keyframes[track_path]:
			current_animation.track_set_key_duration(track_idx, key_idx, value)
	AnimationTrackEditor.update()


func _on_FrameDurationSpinBox_value_changed(value):
	_keyframes_set_duration((value as float) / 1000)


func _on_FrameTimeSpinBox_value_changed(value):
	_keyframe_set_time((value as float) / 1000)


func _on_FrameInterpolationTypeOptionBtn_item_selected(index):
	if not current_animation:
		return

	var track_path = UnitAnimation.Tracks.modulate
	var track_idx = current_animation.find_track(track_path)
	current_animation.track_set_interpolation_type(track_idx, index)
	AnimationTrackEditor.update()

	preview_animation(AnimationTrackEditor.get_cursor_time(), false)
