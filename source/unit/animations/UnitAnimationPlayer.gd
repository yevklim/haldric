extends AnimationPlayer
class_name UnitAnimationPlayer


var filters := UnitAnimation.new()

var sprite_flip_h_setter: FuncRef = null


func _ready():
	pass


func get_unit_animation(trigger := -1) -> UnitAnimation:
	var filtered_anims = []
	var max_score := 0

	var filters = self.filters.duplicate()
	if trigger != -1:
		filters.apply_to = [trigger]

	for anim_name in get_animation_list():
		var anim = get_animation(anim_name) as UnitAnimation
		var anim_score = anim.pass_filter(filters)
		if anim_score > 0:
			if max_score == anim_score:
				filtered_anims.append(anim)
			elif max_score < anim_score:
				max_score = anim_score
				filtered_anims = [anim]

	match filtered_anims.size():
		0:
			if trigger != UnitAnimation.Triggers.default:
				return _get_default()
			else:
				return null
		1:
			return filtered_anims[0]
		_:
			return filtered_anims[randi() % filtered_anims.size()]


func play_unit_animation(anim : UnitAnimation = null, custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false) -> void:
	if not anim:
		anim = get_unit_animation()

	var flip_h = false
	if not anim.direction.size():
		flip_h = filters.direction[0] > 3
	elif not anim.direction.has(filters.direction[0]):
		var anim_directions = anim.direction.duplicate()
		anim_directions.sort()
		flip_h = filters.direction[0] > 3 and anim_directions[anim_directions.size() - 1] <= 3
	if sprite_flip_h_setter != null:
		sprite_flip_h_setter.call_func(flip_h)

	play(anim.name, custom_blend, custom_speed, from_end)


func _get_default(trigger: int = -1) -> UnitAnimation:
	if trigger == -1:
		if filters.apply_to.size() > 0:
			trigger = filters.apply_to[0]
		else:
			trigger = UnitAnimation.Triggers.default
	match trigger:
		_:
			return get_unit_animation(UnitAnimation.Triggers.default)
