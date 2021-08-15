extends HBoxContainer

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_resort()


func set_some_setting():
	queue_sort()


func _resort():
	var children = get_children()

	var sep = get_constant("separation", "HBoxContainer")

	var min_width := 0.0
	var min_ratio := 0.0
	var min_weight := 0.0

	for c in children:
		var width = c.get_combined_minimum_size().x
		var ratio = c.size_flags_stretch_ratio
		var weight = width * c.size_flags_stretch_ratio

		if min_weight == 0 || weight < min_weight:
			min_width = width
			min_ratio = ratio
			min_weight = weight
	
	var child_count = get_child_count()
	for c_idx in child_count:
		var c = get_child(c_idx)

		var position := Vector2()
		var size = c.get_combined_minimum_size()
		var ratio = c.size_flags_stretch_ratio

		if c_idx > 0:
			var prev = get_child(c_idx - 1)
			position.x = prev.rect_position.x + prev.rect_size.x
			size.x = min_width * ratio / min_ratio

			position.x += sep
		
		if c_idx == child_count - 1:
			rect_min_size.x = position.x + size.x
			rect_min_size.y = size.y

		fit_child_in_rect( c, Rect2( position, size ) )
