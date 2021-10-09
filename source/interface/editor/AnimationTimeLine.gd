extends Control

class_name AnimationTimeLine

signal animation_changed()
signal item_activated(track_idx, key_idx)
signal item_rmb_selected(track_idx, key_idx, at_position)
signal item_selected(track_idx, key_idx)
signal multi_selected(track_idx, key_idx, selected)
signal multi_selected_range(track_idx, from_idx, to_idx)
signal nothing_selected()
signal rmb_clicked(at_position)
signal cursor_position_changed(position)
signal cursor_time_changed(time)

enum SelectMode {
	SELECT_SINGLE,
	SELECT_MULTI
}

enum DragAndDropMode {
	DND_REARRANGE,
	DND_MOVING
}

var unknown_unit_texture : Texture = load("res://assets/graphics/images/units/unknown-unit.png")

export var animation: Animation = null setget _set_animation

export var msec_scale: float = 1.0 setget set_scale

export var default_font: Font

export var timeline: StyleBox
export var timeline_font: Font
export var timeline_min_height: int = 16

export var track_min_height: int = 60

export var allow_rmb_select: bool = true
export(SelectMode) var select_mode: int = SelectMode.SELECT_MULTI

export var vseparation: int = 4
export var vseparation_bg: StyleBox

export var guide: StyleBox
export var guide_active: StyleBox
export var guide_active_red: StyleBox
export var guide_width: int = 4
export var guide_width_active: int = 4

export var font: Font
export var font_color: Color = Color(0.63, 0.63, 0.63, 1)
export var font_color_selected: Color = Color(1, 1, 1, 1)

export var cursor: StyleBox
export var cursor_width: int = 4
export var cursor_unfocused: StyleBox

export var selector: StyleBox
export var selector_focus: StyleBox

export var key_point_bg: StyleBox
export var key_point_bg_selected: StyleBox
export var key_point_track_min_height: int = 16

export(DragAndDropMode) var drag_n_drop_mode: int = DragAndDropMode.DND_REARRANGE
export var drag_n_drop_snap_to_steps: bool = false

var cursor_position: float = 0.0


var timeline_rect: Rect2
const Tracks = [
	UnitAnimation.Tracks.key_point,
	UnitAnimation.Tracks.texture,
	UnitAnimation.Tracks.modulate,
	UnitAnimation.Tracks.audio,
]
var _track_rects = {
	UnitAnimation.Tracks.key_point: Rect2(),
	UnitAnimation.Tracks.texture: Rect2(),
	UnitAnimation.Tracks.modulate: Rect2(),
	UnitAnimation.Tracks.audio: Rect2(),
}

var selected_keyframes = {
	UnitAnimation.Tracks.key_point: [],
	UnitAnimation.Tracks.texture: [],
	UnitAnimation.Tracks.modulate: [],
	UnitAnimation.Tracks.audio: [],
}

var copied_keyframes = {
	UnitAnimation.Tracks.key_point: [],
	UnitAnimation.Tracks.texture: [],
	UnitAnimation.Tracks.modulate: [],
	UnitAnimation.Tracks.audio: [],
}


func _init():
	_setup_default_theme_properties()


func _setup_default_theme_properties():
	if not timeline:
		timeline = StyleBoxFlat.new()
		timeline.bg_color = Color(0, 0, 0, 1)
	if not vseparation_bg:
		vseparation_bg = StyleBoxFlat.new()
		vseparation_bg.bg_color = Color8(28, 28, 30, 60)#Color(0, 0, 0, 0.1)
	if not guide:
		guide = StyleBoxFlat.new()
		guide.bg_color = Color8(28, 28, 30, 60)#Color(0, 0, 0, 0.1)
	if not guide_active:
		guide_active = StyleBoxFlat.new()
		guide_active.bg_color = Color8(10, 132, 255)
	if not guide_active_red:
		guide_active_red = StyleBoxFlat.new()
		guide_active_red.bg_color = Color8(255, 69, 58)
	if not cursor:
		cursor = StyleBoxFlat.new()
		cursor.bg_color = Color(1, 1, 1, 1)
	if not cursor_unfocused:
		cursor_unfocused = StyleBoxFlat.new()
		cursor_unfocused.bg_color = Color(1, 1, 1, 0.1)
	if not selector:
		selector = StyleBoxFlat.new()
		selector.set_border_width_all(2)
		selector.bg_color = Color.transparent
		selector.border_color = Color(1, 1, 1, 1)
	if not key_point_bg:
		key_point_bg = StyleBoxFlat.new()
		key_point_bg.bg_color = Color8(28, 28, 30)
	if not key_point_bg_selected:
		key_point_bg_selected = StyleBoxFlat.new()
		key_point_bg_selected.bg_color = Color8(58, 58, 60)


func _ready():
	default_font = Control.new().get_font("font")
	connect("animation_changed", self, "_on_animation_changed")
	if animation:
		update_min_size()
		pass


func get_cursor_time():
	return round(cursor_position * msec_scale) / 1000


func get_cursor_time_msec():
	return round(cursor_position * msec_scale)


func get_snapped_cursor_time():
	return round(cursor_position * msec_scale / (1000 * animation.step)) * animation.step


func _get_timeline_height():
	return timeline_min_height


func set_scale(scale):
	msec_scale = scale
	update()


func set_drag_n_drop_mode(val):
	if val in DragAndDropMode.values():
		drag_n_drop_mode = val


func set_drag_n_drop_snap_to_steps(val: bool):
	drag_n_drop_snap_to_steps = val


func _gui_input(event):
	if not event is InputEventMouse:
		return

	var emit_draw_update = false

	var local_mouse_position = event.position

	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		var new_cursor_position = clamp(local_mouse_position.x, 0, rect_size.x)
		var new_cursor_time_msec = round(new_cursor_position * msec_scale)

		if get_cursor_time_msec() != new_cursor_time_msec:
			emit_signal("cursor_time_changed", new_cursor_time_msec / 1000)
		if cursor_position != new_cursor_position:
			cursor_position = new_cursor_position
			emit_signal("cursor_position_changed", cursor_position)
			emit_draw_update = true

	if event is InputEventMouseMotion:
		if emit_draw_update:
			update()
		return
	
	if not event is InputEventMouseButton:
		if emit_draw_update:
			update()
		return

	var is_dragging = get_viewport().gui_is_dragging()

	var multi_selected = event is InputEventWithModifiers and event.command and select_mode == SelectMode.SELECT_MULTI
	var multi_selected_range = event is InputEventWithModifiers and event.shift and select_mode == SelectMode.SELECT_MULTI
	var lmb_doubleclicked = event.button_index == BUTTON_LEFT and event.doubleclick
	var lmb_pressed = event.button_index == BUTTON_LEFT and not event.pressed and not event.doubleclick and not is_dragging
	var rmb_pressed = event.button_index == BUTTON_RIGHT and not event.pressed

	var frame = find_frame_on_position(local_mouse_position)

	if frame:
		if multi_selected:
			if lmb_pressed:
				_gui_input_multi_selected(frame)
				emit_draw_update = true
		elif multi_selected_range:
			if lmb_pressed:
				_gui_input_multi_selected_range(frame)
				emit_draw_update = true
		else:
			if lmb_doubleclicked:
				_gui_input_item_activated(frame)
				emit_draw_update = true

			if lmb_pressed:
				_gui_input_item_selected(frame)
				emit_draw_update = true

			if rmb_pressed and allow_rmb_select:
				_gui_input_item_rmb_selected(frame, local_mouse_position)
				emit_draw_update = true

		if is_dragging:
			emit_draw_update = true
	else:
		if lmb_pressed:
			_gui_input_nothing_selected()
			emit_draw_update = true

		if rmb_pressed:
			_gui_input_rmb_clicked(local_mouse_position)
			emit_draw_update = true

	if emit_draw_update:
		update()


func _gui_input_multi_selected(frame):
	var not_selected = not selected_keyframes[frame.track_path].has(frame.key_idx)
	if not_selected:
		selected_keyframes[frame.track_path].append(frame.key_idx)
	else:
		selected_keyframes[frame.track_path].erase(frame.key_idx)

	emit_signal("multi_selected", frame.track_idx, frame.key_idx, not_selected)
	print("multi_selected")


func _gui_input_multi_selected_range(frame):
	if selected_keyframes[frame.track_path].size() == 0:
		_gui_input_multi_selected(frame)
	print(selected_keyframes[frame.track_path])
	var prev_key_idx = selected_keyframes[frame.track_path][-1]
	print("start %s %s" % [prev_key_idx, frame.key_idx])
	var increment = sign(frame.key_idx - prev_key_idx)
	for key_idx in range(prev_key_idx, frame.key_idx + increment, increment):
		print(key_idx)
		if key_idx == prev_key_idx:
			continue
		toggle_select(frame.track_idx, key_idx)

	emit_signal("multi_selected_range", frame.track_idx, prev_key_idx, frame.key_idx)
	print("multi_selected_range")


func _gui_input_item_activated(frame):
	unselect_all(false)
	selected_keyframes[frame.track_path].append(frame.key_idx)
	emit_signal("item_activated", frame.track_idx, frame.key_idx)
	print("item_activated")


func _gui_input_item_selected(frame):
	unselect_all(false)
	selected_keyframes[frame.track_path].append(frame.key_idx)
	emit_signal("item_selected", frame.track_idx, frame.key_idx)
	print("item_selected")


func _gui_input_item_rmb_selected(frame, local_mouse_position):
	unselect_all(false)
	selected_keyframes[frame.track_path].append(frame.key_idx)
	emit_signal("item_rmb_selected", frame.track_idx, frame.key_idx, local_mouse_position)
	print("item_rmb_selected")


func _gui_input_nothing_selected():
	unselect_all(false)
	emit_signal("nothing_selected")
	print("nothing_selected")


func _gui_input_rmb_clicked(local_mouse_position):
	emit_signal("rmb_clicked", local_mouse_position)
	print("rmb_clicked")


func _draw():
	if not animation:
		return

	draw_timeline()
	
	draw_tracks(Tracks, get_viewport().gui_is_dragging())

	draw_cursor()


func draw_timeline():
	timeline_rect.position.x = 0
	timeline_rect.position.y = 0
	timeline_rect.size.x = rect_size.x
	timeline_rect.size.y = timeline_min_height
	draw_style_box(timeline, timeline_rect)

	var step_width = animation.step * 1000 / msec_scale
	var steps_count = ceil(rect_size.x / step_width)

	for i in steps_count:
		var time = round(i * animation.step * 1000) as String
		var string_width = font.get_string_size(time).x
		var position = Vector2(i * step_width, 0)
		var size = Vector2(1, timeline_min_height)
		draw_rect(Rect2(position, size), Color(1, 1, 1, 0.6))
		position.x = clamp(i * step_width - string_width * 0.5, 0, rect_size.x - string_width)
		position.y = timeline_rect.position.y + font.get_ascent()
		# position.y = timeline_min_height
		draw_string(font, position, time)

	draw_vseparation(Rect2(timeline_rect.position.x, timeline_rect.end.y, timeline_rect.size.x, vseparation))


func _setup_track_rect_relative_to_prev(track_path: String, prev_rect: Rect2):
	_track_rects[track_path].position.x = prev_rect.position.x
	_track_rects[track_path].position.y = prev_rect.end.y
	if _track_rects[track_path].position.y > 0:
		_track_rects[track_path].position.y += vseparation
	_track_rects[track_path].size.x = prev_rect.size.x
	if track_path != UnitAnimation.Tracks.key_point:
		_track_rects[track_path].size.y = track_min_height
	else:
		_track_rects[track_path].size.y = key_point_track_min_height


func draw_tracks(tracks: Array = [], draw_dragging_guides := false):
	var prev_rect = timeline_rect

	if has_meta("modulate_gradients"):
		get_meta("modulate_gradients").clear()
	else:
		set_meta("modulate_gradients", Array())

	for track_path in tracks:
		var track_idx = animation.find_track(track_path)
		_setup_track_rect_relative_to_prev(track_path, prev_rect)
		draw_keyframes(track_path, track_idx)
		draw_guides(track_path, track_idx)
		if draw_dragging_guides:
			draw_active_guides(track_path, track_idx)
		if not draw_dragging_guides:
			draw_selectors(track_path, track_idx)

		prev_rect = _track_rects[track_path]

		draw_vseparation(Rect2(prev_rect.position.x, prev_rect.end.y, prev_rect.size.x, vseparation))

func draw_keyframes(track_path: String, track_idx := -1):
	if track_idx < 0:
		track_idx = animation.find_track(track_path)

	var key_count = animation.track_get_key_count(track_idx)

	for key_idx in key_count:
		var key_value = animation.track_get_key_value(track_idx, key_idx)
		var time = animation.track_get_key_time(track_idx, key_idx)
		var duration = animation.track_get_key_duration(track_idx, key_idx)
		var next_time = time + duration
		var keyframe_rect = Rect2(_track_rects[track_path].position, Vector2(0, track_min_height))
		var interpolation_type = animation.track_get_interpolation_type(track_idx)

		# if time > animation.length:
		# 	break

		if track_path == UnitAnimation.Tracks.key_point:
			keyframe_rect.size.y = key_point_track_min_height
		if track_path == UnitAnimation.Tracks.texture:
			keyframe_rect.size = key_value.get_size()
			if key_idx == 0 or keyframe_rect.size.y > _track_rects[track_path].size.y:
				_track_rects[track_path].size.y = keyframe_rect.size.y

		keyframe_rect.position.x += round(time * 1000 / msec_scale)
		keyframe_rect.size.x = round(duration * 1000 / msec_scale)

		match track_path:
			UnitAnimation.Tracks.key_point:
				var string_size = default_font.get_string_size(key_value)
				keyframe_rect.size.x = string_size.x
				draw_style_box(key_point_bg if not selected_keyframes[track_path].has(key_idx) else key_point_bg_selected, keyframe_rect)
				# draw_string(default_font, Vector2(keyframe_rect.position.x, keyframe_rect.position.y + (keyframe_rect.size.y + string_size.y) / 2), key_value)
				draw_string(default_font, Vector2(keyframe_rect.position.x, keyframe_rect.position.y + (keyframe_rect.size.y - default_font.get_descent())), key_value)
			UnitAnimation.Tracks.texture:
				draw_texture(key_value, keyframe_rect.position)
			UnitAnimation.Tracks.modulate:
				if interpolation_type == Animation.INTERPOLATION_NEAREST or key_idx == key_count - 1 or next_time > animation.length:
					draw_rect(keyframe_rect, key_value)
				elif interpolation_type == Animation.INTERPOLATION_LINEAR or interpolation_type == Animation.INTERPOLATION_CUBIC:
					var next_value = animation.track_get_key_value(track_idx, key_idx + 1)
					var texture := GradientTexture.new()
					texture.gradient = Gradient.new()
					texture.gradient.set_color(0, key_value)
					texture.gradient.set_color(1, next_value)
					get_meta("modulate_gradients").append(texture)
					draw_texture_rect(texture, keyframe_rect, false)
			UnitAnimation.Tracks.audio:
				var audio_stream = key_value.stream
				var path = audio_stream.resource_path if audio_stream else "Null"

				var string_size = default_font.get_string_size(path)
				draw_string(default_font, Vector2(keyframe_rect.position.x, keyframe_rect.position.y + (keyframe_rect.size.y + string_size.y) / 2), path)

		if key_idx == key_count - 1:
			rect_min_size.x = max(keyframe_rect.end.x, rect_min_size.x)


func draw_selectors(track_path: String, track_idx := -1):
	if not selector:
		return

	if track_path == UnitAnimation.Tracks.key_point:
		return

	if track_idx < 0:
		track_idx = animation.find_track(track_path)

	if track_idx < 0:
		return

	var track_rect = _track_rects[track_path]

	var key_count = animation.track_get_key_count(track_idx)

	var selectors = []
	# selected_keyframes[track_path].sort()

	for key_idx in key_count:
		if selected_keyframes[track_path].has(key_idx):
			if not selectors.size():
				selectors.append(Vector2(-1, -1))

			if selectors[-1].x == -1:
				selectors[-1].x = key_idx
				selectors[-1].y = key_idx

			elif selectors[-1].y < key_idx:
				selectors[-1].y = key_idx

		elif not selectors.size() or selectors[-1].x >= 0:
			selectors.append(Vector2(-1, -1))
	
	if selectors.size() and selectors[-1].x == -1:
		selectors.erase(Vector2(-1, -1))

	# for key_idx in key_count + 1:
	# 	var time
	# 	if key_idx < key_count:
	# 		time = animation.track_get_key_time(track_idx, key_idx)
	# 	else:
	# 		time = animation.track_get_key_time(track_idx, key_idx) + animation.track_get_key_duration(track_idx, key_idx)
		# if time > animation.length:
		# 	break

	for selector in selectors:
		var selector_rect = track_rect

		var time_start = animation.track_get_key_time(track_idx, selector.x)
		var time_end = animation.track_get_key_time(track_idx, selector.y) + animation.track_get_key_duration(track_idx, selector.y)

		selector_rect.position.x = round(time_start * 1000 / msec_scale)
		selector_rect.end.x = round(time_end * 1000 / msec_scale)

		draw_style_box(self.selector, selector_rect)


func draw_guides(track_path: String, track_idx := -1):
	if track_idx < 0:
		track_idx = animation.find_track(track_path)

	if track_idx < 0:
		return

	var key_count = animation.track_get_key_count(track_idx)

	for key_idx in key_count + 1:
		var time
		if key_idx < key_count:
			time = animation.track_get_key_time(track_idx, key_idx)
		else:
			time = animation.length
		# if time > animation.length:
		# 	break

		var guide_rect = get_guide_rect(track_path, time, key_count, key_idx)

		# draw_rect(guide_rect, guide_color)
		draw_style_box(guide, guide_rect)


func draw_active_guides(track_path: String, track_idx := -1):
	if track_idx < 0:
		track_idx = animation.find_track(track_path)

	if track_idx < 0:
		return

	var key_count = animation.track_get_key_count(track_idx)

	var selected = selected_keyframes[track_path].duplicate()
	selected.sort()

	if drag_n_drop_mode == DragAndDropMode.DND_REARRANGE:
		var guide_idx = get_guide_idx_by_time(track_idx, get_cursor_time()) if selected_keyframes[track_path].size() else -1
		if guide_idx == -1:
			return

		var time
		if guide_idx < key_count:
			time = animation.track_get_key_time(track_idx, guide_idx)
		else:
			time = animation.length

		var guide_rect = get_guide_rect(track_path, time, key_count, guide_idx)

		# draw_rect(guide_rect, guide_color_active)
		draw_style_box(guide_active, guide_rect)
	else:
		var base_time = null
		for track_path in Tracks:
			var track_index = animation.find_track(track_path)
			if selected_keyframes[track_path].size():
				var new_time = animation.track_get_key_time(track_index, selected_keyframes[track_path][0])
				if not base_time or new_time < base_time:
					base_time = new_time
		var dest_time
		if drag_n_drop_snap_to_steps:
			dest_time = get_snapped_cursor_time()
		else:
			dest_time = get_cursor_time()
		var delta_time = dest_time - base_time

		for key_idx in selected:
			var time = animation.track_get_key_time(track_idx, key_idx)
			var new_time = max(time + delta_time, 0.0)

			var guide_rect = get_guide_rect(track_path, new_time, key_count, key_idx)

			# draw_rect(guide_rect, guide_color_active if animation.track_find_key(track_idx, new_time, true) == -1 else guide_color_active_red)
			var is_red = animation.track_find_key(track_idx, new_time, true) != -1
			draw_style_box(guide_active_red if is_red else guide_active, guide_rect)


func get_guide_rect(track_path: String, time: float, key_count: int, key_idx: int):
	var guide_rect = _track_rects[track_path]
	guide_rect.position.x += round(time * 1000 / msec_scale)
	if key_idx > 0 and key_idx < key_count:
		guide_rect.position.x -= guide_width / 2
	elif key_idx == key_count:
		guide_rect.position.x -= guide_width
	guide_rect.position.x = max(0, guide_rect.position.x)
	guide_rect.size.x = guide_width

	return guide_rect


func draw_cursor():
	var cursor_rect = Rect2()
	cursor_rect.position.x = cursor_position - cursor_width * 0.5
	cursor_rect.position.x = clamp(cursor_rect.position.x, 0, rect_size.x - cursor_width)
	cursor_rect.position.y = timeline_rect.end.y
	cursor_rect.size.x = cursor_width
	cursor_rect.end.y = rect_size.y
	draw_rect(cursor_rect, Color(1, 1, 1))

	var time = get_cursor_time_msec() as String
	var string_width = font.get_string_size(time).x

	var cursor_tip_rect = Rect2()
	cursor_tip_rect.position.x = cursor_position - (string_width) * 0.5
	cursor_tip_rect.position.x = clamp(cursor_tip_rect.position.x, 0, rect_size.x - string_width)
	cursor_tip_rect.position.y = timeline_rect.position.y
	cursor_tip_rect.size.x = string_width
	cursor_tip_rect.size.y = timeline_rect.size.y
	draw_rect(cursor_tip_rect, Color8(58, 58, 60))
	cursor_tip_rect.position.y += font.get_ascent()
	draw_string(font, cursor_tip_rect.position, time)


func draw_vseparation(rect: Rect2):
	# draw_rect(rect, vseparation_color)
	draw_style_box(vseparation_bg, rect)


func get_guide_idx_by_time(track_idx: int, time: float) -> int:
	var closest_idx = animation.track_find_key(track_idx, time)
	if closest_idx == -1:
		return 0
	var closest_time = animation.track_get_key_time(track_idx, closest_idx)
	var next_closest_time = closest_time
	if closest_idx + 1 < animation.track_get_key_count(track_idx):
		next_closest_time = animation.track_get_key_time(track_idx, closest_idx + 1)
	if next_closest_time == closest_time:
		next_closest_time = animation.length

	var delta_1 = time - closest_time
	var delta_2 = next_closest_time - time

	if delta_1 < delta_2:
		return closest_idx
	else:
		return closest_idx + 1


func find_frame_on_position(position: Vector2):
	var time = position.x * msec_scale / 1000
	var actual_time
	var track_path: String
	var track_idx: int
	var key_idx: int

	for _track_path in _track_rects.keys():
		if _track_rects[_track_path].has_point(position):
			track_idx = animation.find_track(_track_path)
			track_path = _track_path
			break

	key_idx = animation.track_find_key(track_idx, time)

	if not track_path.length() or track_idx == -1 or key_idx == -1:
		return null
	
	actual_time = animation.track_get_key_time(track_idx, key_idx)
	
	# if actual_time < animation.length and time > animation.length + 0.1:
	# 	return null

	return {
		track_path = track_path,
		track_idx = track_idx,
		key_idx = key_idx,
		time = actual_time,
	}


func get_drag_data(position):
	if not is_anything_selected():
		return

	var preview: Control = VBoxContainer.new()

	for track_path in Tracks:
		var track_idx = animation.find_track(track_path)
		if selected_keyframes[track_path].size():
			var hboxcontainer = HBoxContainer.new()
			var selected = selected_keyframes[track_path].duplicate()
			selected.sort()
			for key_idx in selected:
				var preview_variant = animation.track_get_key_value(track_idx, key_idx)
				var preview_item_width = animation.track_get_key_duration_msec(track_idx, key_idx)
				var preview_item: Control
				#TODO: fix key_idx == -1
				match track_path:
					UnitAnimation.Tracks.key_point:
						preview_item = Label.new()
						preview_item.text = preview_variant
					UnitAnimation.Tracks.texture:
						preview_item = TextureRect.new()
						preview_item.texture = preview_variant
					UnitAnimation.Tracks.modulate:
						preview_item = ColorRect.new()
						preview_item.rect_min_size.y = 60
						preview_item.color = preview_variant
					UnitAnimation.Tracks.audio:
						preview_item = Label.new()
						preview_item.text = preview_variant.stream.resource_path if preview_variant.stream else "Null"
				preview_item.rect_min_size.x = preview_item_width
				hboxcontainer.add_child(preview_item)
			preview.add_child(hboxcontainer)

	
	set_drag_preview(preview)

	var dragged_keyframes = {}
	for key in selected_keyframes.keys():
		dragged_keyframes[key] = selected_keyframes[key].duplicate()
		dragged_keyframes[key].sort()
	
	return {
		selected_keyframes = dragged_keyframes,
		position = position
	}


func can_drop_data(_position, data): 
	return typeof(data) == TYPE_DICTIONARY and data.selected_keyframes.keys() == Tracks


func drop_data(position, data):
	drop_data_and_rearrange(position, data)
	drop_data_and_shift(position, data)
	update()


func drop_data_and_rearrange(position, data):
	if drag_n_drop_mode == DragAndDropMode.DND_REARRANGE:
		# var step = animation.step * 1000 / msec_scale
		# var rounded_x = round(position.x / step) * step
		# var clamped_x = clamp(rounded_x, 0, animation.length * 1000 / msec_scale)
		# var dest_time = clamped_x * msec_scale / 1000
		var dest_time = position.x * msec_scale / 1000

		var new_selected_items = {}

		for track_path in data.selected_keyframes.keys():
			var track_idx = animation.find_track(track_path)
			var dest_key = get_guide_idx_by_time(track_idx, dest_time)

			new_selected_items[track_path] = []
			var selected = data.selected_keyframes[track_path]
			var selected_from_left = []
			var selected_from_right = []
			for key in selected:
				if key < dest_key:
					selected_from_left.append(key)
				elif key >= dest_key:
					selected_from_right.append(key)
			var move_pairs = []
			for i in selected_from_left.size():
				var src_idx = selected_from_left[i]
				move_pairs.append(Vector2(
					selected_from_left[i] - i,
					dest_key
				))
			for i in selected_from_right.size():
				move_pairs.append(Vector2(
					selected_from_right[i],
					dest_key + i
				))

			var range_start = dest_key - selected_from_left.size()
			var range_end = dest_key + selected_from_right.size() - 1
			new_selected_items[track_path] = range(range_start, range_end + 1)

			for move_pair in move_pairs:
				animation.track_move_key(track_idx, move_pair.x, move_pair.y)
		selected_keyframes = new_selected_items


func drop_data_and_shift(_position, data):
	if drag_n_drop_mode == DragAndDropMode.DND_MOVING: 
		# var step = animation.step * 1000 / msec_scale
		# var rounded_x = round(position.x / step) * step
		# var clamped_x = clamp(rounded_x, 0, animation.length * 1000 / msec_scale)
		# var dest_time = clamped_x * msec_scale / 1000
		# var src_time = data.position.x * msec_scale / 1000
		# var base_time
		# base_time = animation.track_get_key_time(track_idx, selected[0]) if selected.size() else 0.0
		# var dest_time = position.x * msec_scale / 1000
		# var delta_time = dest_time - base_time

		var src_time = data.position.x * msec_scale / 1000
		var base_time = null
		for track_path in Tracks:
			var track_index = animation.find_track(track_path)
			if selected_keyframes[track_path].size():
				var new_time = animation.track_get_key_time(track_index, selected_keyframes[track_path][0])
				if not base_time or new_time < base_time:
					base_time = new_time
		if base_time == null:
			base_time = src_time
		var dest_time
		if drag_n_drop_snap_to_steps:
			dest_time = get_snapped_cursor_time()
		else:
			dest_time = get_cursor_time()
		var delta_time = dest_time - base_time

		var new_selected_items = {}

		for track_path in data.selected_keyframes.keys():
			var track_idx = animation.find_track(track_path)
			# var dest_key = get_guide_idx_by_time(track_idx, dest_time)

			new_selected_items[track_path] = []
			var selected = data.selected_keyframes[track_path]
			if selected.size() == 0:
				continue

			var times = []
			for key_idx in selected:
				var t = animation.track_get_key_time(track_idx, key_idx)
				var t1 = max(t + delta_time, 0.0)
				var idx_on_t1 = animation.track_find_key(track_idx, t1, true)
				if idx_on_t1 != -1 and not selected.has(idx_on_t1):
					update()
					return
				times.append(t1)

			var selected_range = range(selected.size())
			if delta_time > 0:
				selected_range.invert()

			for i in selected_range:
				var key_idx = selected[i]
				var time = times[i]
				animation.track_set_key_time(track_idx, key_idx, time)

			for time in times:
				var key_idx = animation.track_find_key(track_idx, time, true)
				new_selected_items[track_path].append(key_idx)
			
		selected_keyframes = new_selected_items


func update_min_size():
	if not animation:
		return

	var animation_length_in_pixels = animation.length * 1000 / msec_scale
	rect_min_size.x = max(animation_length_in_pixels, rect_min_size.x)

	var new_min_size = rect_min_size
	var track_idx
	var key_idx
	var time

	for track_path in Tracks:
		track_idx = animation.find_track(track_path)
		key_idx = animation.track_get_key_count(track_idx) - 1
		if key_idx >= 0:
			time = animation.track_get_key_time(track_idx, key_idx)

			new_min_size.x = _track_rects[track_path].position.x
			new_min_size.x += time * 1000 / msec_scale
			new_min_size.x += 100

			rect_min_size.x = max(new_min_size.x, rect_min_size.x)

			new_min_size.y = _track_rects[track_path].end.y

	rect_min_size.y = new_min_size.y


func is_anything_selected() -> bool:
	for array in selected_keyframes.values():
		if array.size():
			return true
	return false


func is_selected(track_idx: int, key_idx: int) -> bool:
	var track_path = animation.track_get_path(track_idx) as String
	return selected_keyframes[track_path].has(key_idx)


func get_selected_tracks():
	var selected_tracks = []
	for track_path in Tracks:
		if selected_keyframes[track_path].size() > 0:
			selected_tracks.append(track_path)
	return selected_tracks


func toggle_select(track_idx: int, key_idx) -> void:
	var track_path = animation.track_get_path(track_idx) as String
	var not_selected = not selected_keyframes[track_path].has(key_idx)
	if not_selected:
		selected_keyframes[track_path].append(key_idx)
	else:
		selected_keyframes[track_path].erase(key_idx)


func select(track_idx: int, key_idx: int, single := true) -> void:
	if single:
		unselect_all(false)

	var track_path = animation.track_get_path(track_idx) as String
	if single or not is_selected(track_idx, key_idx):
		selected_keyframes[track_path].append(key_idx)

	update()


func unselect(track_idx: int, key_idx: int) -> void:
	var track_path = animation.track_get_path(track_idx) as String
	selected_keyframes[track_path].erase(key_idx)
	update()


func unselect_all(update := true):
	for track_path in Tracks:
		selected_keyframes[track_path].clear()

	if update:
		self.update()
	

func copy_selected_keyframes():
	var new_copied_keyframes := {}

	for track_path in Tracks:
		new_copied_keyframes[track_path] = []
		var track_idx = animation.find_track(track_path)

		var selected = selected_keyframes[track_path].duplicate()
		selected.sort()

		for key_idx in selected:
			new_copied_keyframes[track_path].append({
				value = animation.track_get_key_value(track_idx, key_idx),
				duration = animation.track_get_key_duration(track_idx, key_idx),
			})

	if is_anything_selected():
		copied_keyframes = new_copied_keyframes


func paste_keyframes():
	var prev_length: float = animation.length
	var max_length: float = prev_length
	for track_path in Tracks:
		var track_idx = animation.find_track(track_path)

		var key_count = animation.track_get_key_count(track_idx)

		var selected = selected_keyframes[track_path].duplicate()
		selected.sort()

		var copied = copied_keyframes[track_path]
		var copied_size = copied.size()

		if not selected.size() and key_count:
			selected = [key_count - 1]
		var selected_size = selected.size()

		for i in selected_size:
			if copied_size <= i:
				break

			var key_idx = selected[i] + i + 1
			if i < selected_size - 1:
				var key_frame = copied[i]
				animation.track_insert_key_with_duration(track_idx, key_idx, key_frame.duration, key_frame.value)
			else:
				var copied_2 = copied.slice(i, copied_size - 1)
				copied_2.invert()
				for key_frame in copied_2:
					animation.track_insert_key_with_duration(track_idx, key_idx, key_frame.duration, key_frame.value)
					
		max_length = max(max_length, animation.length)
		animation.length = prev_length
		
	animation.length = max_length

	update()


func duplicate_selected_keyframes():
	copy_selected_keyframes()
	paste_keyframes()


func new_keyframe(track_path, with_shift := false):
	var track_idx = animation.find_track(track_path)
	var key_count = animation.track_get_key_count(track_idx)
	var selected = selected_keyframes[track_path]
	var dest_idx = selected[-1] + 1 if selected.size() else key_count
	var duration = 0.1
	var time = get_cursor_time()
	var value
	match track_path:
		UnitAnimation.Tracks.key_point:
			value = "key_point"
		UnitAnimation.Tracks.texture:
			value = unknown_unit_texture
		UnitAnimation.Tracks.modulate:
			value = Color(1, 1, 1, 1)
		UnitAnimation.Tracks.audio:
			value = null
	if with_shift:
		animation.track_insert_key_with_duration(track_idx, dest_idx, duration, value)
	else:
		if animation.length < time + duration:
			animation.length = time + duration
		if animation.track_find_key(track_idx, time, true) == -1:
			if track_path == UnitAnimation.Tracks.audio:
				animation.audio_track_insert_key(track_idx, time, value)
			else:
				animation.track_insert_key(track_idx, time, value)
	update()


func remove_keyframe(with_shift := false):
	for track_path in Tracks:
		var track_idx = animation.find_track(track_path)
		
		var selected = selected_keyframes[track_path]
		selected.sort()

		for i in selected.size():
			var key_idx = selected[i] - i
			if with_shift:
				animation.track_remove_key_with_duration(track_idx, key_idx)
			else:
				animation.track_remove_key(track_idx, key_idx)
				
		selected.clear()

	update()


func _set_animation(new_animation: UnitAnimation):
	animation = new_animation
	emit_signal("animation_changed")
	update()


func _on_animation_changed():
	update_min_size()
