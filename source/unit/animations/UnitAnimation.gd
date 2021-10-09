extends Animation
class_name UnitAnimation


const Tracks = {
	key_point = "AnimationPlayer:key_point",
	texture = "Sprite:texture",
	modulate = "Sprite:modulate",
	audio = "AudioStreamPlayer2D",
}

var _track_paths = [
	Tracks.key_point,
	Tracks.texture,
	Tracks.modulate,
	Tracks.audio,
]

enum Events {
	default, standing, idling, selected,
	recruited, recruiting, levelout, levelin, 
	movement, pre_movement, post_movement, 
	pre_teleport, post_teleport,
	healing, healed, poisoned, 
	defend, attack, death, victory,
	leading, resistance,
	draw_weapon, sheath_weapon
}

enum Hits {
	hit, miss, kill, invalid
}

enum {
	MATCH_FAIL = -10,
	DEFAULT_ANIM = -9
}

export var name := ""

export(Array, String) var terrain_types: Array
# export(Array) var unit_filter: Array
# export(Array) var secondary_unit_filter: Array
export(Array, Hex.Direction) var directions: Array
export var frequency : int
export var base_score : int
export(Array, Events) var event: Array = []
export(Array, int) var value: Array
export(Array, int) var value2: Array
export(Array, PackedScene) var primary_attack_filter: Array # Attack
export(Array, PackedScene) var secondary_attack_filter: Array# Attack
export(Array, Hits) var hits: Array = [Hits.invalid]

#var src_loc: Resource # Location
#var dst_loc: Resource # Location


func _ready():
	pass


func _init():
	var tracks = [
		{
			path = Tracks.key_point,
			type = TYPE_VALUE
		},
		{
			path = Tracks.texture,
			type = TYPE_VALUE
		},
		{
			path = Tracks.modulate,
			type = TYPE_VALUE
		},
		{
			path = Tracks.audio,
			type = TYPE_AUDIO
		},
	]

	for track in tracks:
		var track_idx = find_track(track.path)
		if track_idx < 0:
			track_idx = add_track(track.type)
			track_set_path(track_idx, track.path)
		if track.path == Tracks.modulate:
			value_track_set_update_mode(track_idx, Animation.UPDATE_CONTINUOUS)


func matches(filters: UnitAnimation) -> int:
	var result = base_score

	if event.size():
		for ev in filters.event:
			if event.has(ev):
				result += 1
			else:
				return MATCH_FAIL

	if terrain_types.size():
		for ter in filters.terrain_types:
			if terrain_types.has(ter):
				result += 1
			else:
				return MATCH_FAIL

	if value.size():
		for val in filters.value:
			if value.has(val):
				result += 1
			else:
				return MATCH_FAIL

	if directions.size():
		for d in filters.directions:
			if directions.has(d):
				result += 1
			else:
				return MATCH_FAIL

	#
	#unit_filter
	#
	#secondary_unit_filter
	#

	if frequency > 0:
		randomize()
		if not randi() % frequency:
			return MATCH_FAIL

	if hits.size() and hits[0] != Hits.invalid:
		for hit in filters.hits:
			if hits.has(hit):
				result += 1
			else:
				return MATCH_FAIL

	if value2.size():
		for val2 in filters.value2:
			if value2.has(val2):
				result += 1
			else:
				return MATCH_FAIL

	if not filters.primary_attack_filter.size() and primary_attack_filter.size():
		return MATCH_FAIL

	for attack in filters.primary_attack_filter:
		var matches = false
		for attack_filter in primary_attack_filter:
			if attack.matches_filter(attack_filter):
				matches = true
		if not matches:
			return MATCH_FAIL
		result += 1

	if not filters.secondary_attack_filter.size() and secondary_attack_filter.size():
		return MATCH_FAIL

	for attack2 in filters.secondary_attack_filter:
		var matches = false
		for attack2_filter in secondary_attack_filter:
			if attack2.matches_filter(attack2_filter):
				matches = true
		if not matches:
			return MATCH_FAIL
		result += 1

	return result


func set_event(val: int):
	if Events.values().has(val):
		event.clear()
		event.append(val)


func set_primary_attack_filter(val: Attack):
	primary_attack_filter.clear()
	primary_attack_filter.append(val)


func set_secondary_attack_filter(val: Attack):
	secondary_attack_filter.clear()
	secondary_attack_filter.append(val)


func set_hits(val: int):
	if Hits.values().has(val):
		hits.clear()
		hits.append(val)


func set_direction(val: int):
	if Hex.Direction.values().has(val):
		directions.clear()
		directions.append(val)


func track_insert_key_with_duration(track_idx: int, idx: int, duration: float, key, transition: float = 1) -> void:
	var track_type = track_get_type(track_idx)
	var key_count = track_get_key_count(track_idx)
	var key_time
	if idx == 0:
		key_time = 0.0
	elif idx < key_count:
		key_time = track_get_key_time(track_idx, idx)
	else:
		key_time = length

	if key_count == 0:
		if duration > length:
			length = duration
	else:
		length += duration

	var toright_range = range(idx, key_count)
	toright_range.invert()
	for key_idx in toright_range:
		var new_time = track_get_key_time(track_idx, key_idx) + duration
		track_set_key_time(track_idx, key_idx, new_time)
	
	if track_type == TYPE_AUDIO:
		audio_track_insert_key(track_idx, key_time, key)
	else:
		track_insert_key(track_idx, key_time, key, transition)


func track_remove_key_with_duration(track_idx: int, key_idx: int):
	var key_duration = track_get_key_duration(track_idx, key_idx)
	track_remove_key(track_idx, key_idx)
	var key_count = track_get_key_count(track_idx)

	for idx in range(key_idx, key_count):
		var new_time = track_get_key_time(track_idx, idx) - key_duration
		track_set_key_time(track_idx, idx, new_time)

	# length -= key_duration


func track_get_key_duration(track_idx: int, key_idx: int) -> float:
	var key_count = track_get_key_count(track_idx)

	var this = track_get_key_time(track_idx, key_idx)
	if this < 0:
		return -1.0

	var next
	if key_idx + 1 == key_count:
		next = length
	else:
		next = track_get_key_time(track_idx, key_idx + 1)
	var duration = 0.0

	if next > this:
		duration = next - this
	else:
		duration = 0.1

	return duration


func track_get_key_duration_msec(track_idx: int, key_idx: int) -> float:
	return round(track_get_key_duration(track_idx, key_idx) * 1000)


func track_get_key_time_msec(track_idx: int, key_idx: int) -> float:
	return round(track_get_key_time(track_idx, key_idx) * 1000)


func track_get_key_values(track_idx: int) -> Array:
	var key_count = track_get_key_count(track_idx)
	var values = []

	for key_idx in key_count:
		values.append(track_get_key_value(track_idx, key_idx))

	return values


func track_get_key_times(track_idx: int) -> Array:
	var key_count = track_get_key_count(track_idx)
	var times = []

	for key_idx in key_count:
		times.append(track_get_key_time(track_idx, key_idx))

	return times


func track_get_key_durations(track_idx: int) -> Array:
	var key_count = track_get_key_count(track_idx)
	var durations = []

	for key_idx in key_count:
		var this = track_get_key_time(track_idx, key_idx)
		var next
		if key_idx + 1 == key_count:
			next = length
		else:
			next = track_get_key_time(track_idx, key_idx + 1)
		durations.append(next - this)

	return durations


func track_move_key(track_idx: int, key_idx: int, to_idx: int):
	var key_count = track_get_key_count(track_idx)
	if key_idx < 0 or key_idx >= key_count or key_idx == to_idx:
		return
	# to_idx = clamp(to_idx + int(to_idx > key_idx), 0, key_count)
	to_idx = clamp(to_idx, 0, key_count)

	var key_duration = track_get_key_duration(track_idx, key_idx)
	var new_key_time
	if to_idx == key_count:
		new_key_time = length
	else:
		new_key_time = track_get_key_time(track_idx, to_idx)
	

	var toright_range = range(to_idx, key_count)
	toright_range.invert()
	for idx in toright_range:
		var new_time = track_get_key_time(track_idx, idx) + key_duration
		track_set_key_time(track_idx, idx, new_time)

	track_set_key_time(track_idx, key_idx, new_key_time)

	for idx in range(key_idx + int(to_idx < key_idx), key_count):
		var new_time = track_get_key_time(track_idx, idx) - key_duration
		track_set_key_time(track_idx, idx, new_time)

	
func track_set_key_duration(track_idx: int, key_idx: int, duration: float):
	var key_time = track_get_key_time(track_idx, key_idx)
	var key_count = track_get_key_count(track_idx)
	var key_duration = track_get_key_duration(track_idx, key_idx)
	var delta = duration - key_duration
	var change_length = key_time < length

	if is_zero_approx(delta) or duration < 0.001:
		return

	for idx in range(key_idx + 1, key_count):
		var new_time = track_get_key_time(track_idx, idx) + delta
		change_length = new_time < length
		track_set_key_time(track_idx, idx, new_time)
	
	if change_length:
		length += duration - key_duration


func duplicate_with_name(other_anim : UnitAnimation, name: String):
	other_anim.length = length
	other_anim.loop = loop
	other_anim.step = step

	other_anim.name = name
	other_anim.terrain_types = terrain_types.duplicate()
	other_anim.directions = directions.duplicate()
	other_anim.frequency = frequency
	other_anim.base_score = base_score
	other_anim.event = event.duplicate()
	other_anim.value = value.duplicate()
	other_anim.value2 = value2.duplicate()
	other_anim.primary_attack_filter = primary_attack_filter.duplicate()
	other_anim.secondary_attack_filter = secondary_attack_filter.duplicate()
	other_anim.hits = hits.duplicate()
	
	for track_path in Tracks.values():
		var track_idx = find_track(track_path)
		var other_track_idx = other_anim.find_track(track_path)
		for key_idx in track_get_key_count(track_idx):
			var time = track_get_key_time(track_idx, key_idx)
			var key = track_get_key_value(track_idx, key_idx)
			var transition = track_get_key_transition(track_idx, key_idx)
			other_anim.track_insert_key(other_track_idx, time, key, transition)

	return other_anim
