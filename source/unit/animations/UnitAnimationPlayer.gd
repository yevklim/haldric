extends AnimationPlayer
class_name UnitAnimationPlayer


var filters := UnitAnimation.new()

var key_point := ""

var sprite_flip_h_setter: FuncRef = null

var currect_unit_animation: UnitAnimation = null


func _ready():
	pass


func choose_animation(event := -1) -> UnitAnimation:
	if UnitAnimation.Events.values().has(event):
		filters.event.clear()
		filters.event.append(event)

	var options = []
	var max_score = UnitAnimation.MATCH_FAIL
	for anim_name in get_animation_list():
		var anim = get_animation(anim_name) as UnitAnimation
		var matching = anim.matches(filters)
		if matching > UnitAnimation.MATCH_FAIL and matching == max_score:
			options.append(anim)
		elif matching > max_score:
			max_score = matching
			options.clear()
			options.append(anim)

	match options.size():
		0:
			currect_unit_animation = null
		1:
			currect_unit_animation = options[0]
		_:
			randomize()
			currect_unit_animation = options[randi() % options.size()]
	return currect_unit_animation


func play_unit_animation(anim : UnitAnimation = null, custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false) -> void:
	if not anim:
		anim = choose_animation()

	var flip_h = false
	if not anim.directions.size():
		flip_h = filters.directions[0] > 3
	elif not anim.directions.has(filters.directions[0]):
		var anim_directions = anim.directions.duplicate()
		anim_directions.sort()
		flip_h = filters.directions[0] > 3 and anim_directions[anim_directions.size() - 1] <= 3
	if sprite_flip_h_setter != null:
		sprite_flip_h_setter.call_func(flip_h)

	play(anim.name, custom_blend, custom_speed, from_end)


func fill_initial_animations():
	var base := choose_animation(UnitAnimation.Events.default)
	var anim : UnitAnimation
	var track_idx: int
	if base != null:
		anim = base.duplicate_with_name(UnitAnimation.new(), "standing")
		anim.set_event(UnitAnimation.Events.standing)
		add_animation(anim.name, anim)

		anim = base.duplicate_with_name(UnitAnimation.new(), "recruited")
		anim.set_event(UnitAnimation.Events.recruited)
		anim.length = 0.6
		anim.remove_track(anim.find_track(UnitAnimation.Tracks.modulate))
		track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, UnitAnimation.Tracks.modulate)
		anim.track_insert_key(track_idx, 0.0, Color.transparent)
		anim.track_insert_key(track_idx, 0.6, Color.white)
		anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_LINEAR)
		add_animation(anim.name, anim)

		anim = base.duplicate_with_name(UnitAnimation.new(), "poisoned")
		anim.set_event(UnitAnimation.Events.poisoned)
		anim.length = 0.3
		anim.remove_track(anim.find_track(UnitAnimation.Tracks.modulate))
		track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, UnitAnimation.Tracks.modulate)
		
		var poison_green = Color8(0, 255, 0)
		for i in 9:
			if i % 2 == 0:
				anim.track_insert_key(track_idx, i * 0.030, Color.white)
			else:
				anim.track_insert_key(track_idx, i * 0.030, poison_green)
		anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_NEAREST)
		add_animation(anim.name, anim)
