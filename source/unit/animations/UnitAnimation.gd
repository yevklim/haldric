extends Animation
class_name UnitAnimation


enum Triggers {
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
	hit, miss, kill, hit_or_kill
}

export var name := ""
export var key_points = {
	times = [],
	values = [],
}

export(Array, Triggers) var apply_to := []
export var value := []
export var value_second := []
export(Array, String) var terrain_type := []
export(Array, Hex.Direction) var direction := []
export var frequency := -1
export(PackedScene) var attack = null # : Attack
export(PackedScene) var second_attack = null # : Attack
export(Hits) var hits := -1 # Hits
export var base_score := 0


func _ready():
	pass


# to be finished
func pass_filter(filters: UnitAnimation) -> int:
	var score: int = base_score
	if not filters.apply_to.size():
		filters.apply_to = [Triggers.default]
	for idx in filters.apply_to.size():
		var trigger = filters.apply_to[idx]
		if not apply_to.has(trigger):
			return -1
		score += 1
		
		var _idx := apply_to.find(trigger)

		if _idx >= value.size():
			continue

		var _value
		if _idx < value.size():
			_value = value[_idx]

		var filter_value
		if idx < filters.value.size():
			filter_value = filters.value[idx]

		var _value_second
		if _idx < value_second.size():
			_value_second = value_second[_idx]

		var filter_value_second
		if idx < filters.value_second.size():
			filter_value_second = filters.value_second[idx]

		match trigger:
			Triggers.movement, \
			Triggers.healing, \
			Triggers.healed, \
			Triggers.poisoned, \
			Triggers.defend, \
			Triggers.attack:
				if _value and filter_value and _value is Vector2:
					if _value.x != -1 and filter_value < _value.x:
						return -1
					if _value.y != -1 and filter_value > _value.y:
						return -1
					score += 1
				continue
			Triggers.movement, \
			Triggers.defend, \
			Triggers.attack, \
			Triggers.leading, \
			Triggers.resistance:
				if _value_second and filter_value_second and _value_second is Vector2:
					if _value_second.x != -1 and filter_value_second < _value_second.x:
						return -1
					if _value_second.y != -1 and filter_value_second > _value_second.y:
						return -1
					score += 1
			Triggers.draw_weapon:
				pass
			_:
				pass

	if terrain_type.size() > 0:
		var terrain_score := 0
		for t in filters.terrain_type:
			if terrain_type.has(t):
				terrain_score += 1
		if terrain_score == 0:
			return -1
		score += terrain_score

	if direction.size() > 0:
		for d in filters.direction:
			if direction.has(d):
				score += 1

	# to be finished
	if attack and not second_attack and filters.second_attack:
		second_attack = attack
	for _attack in ["attack", "second_attack"]:
		if get(_attack) != null and filters.get(_attack) != null:
			for _param in ["alias", "category", "damage_type"]:
				if get(_attack).get(_param).length():
					if get(_attack).get(_param) != filters.get(_attack).get(_param):
						return -1
					score += 1

	if hits != -1:
		if (hits != filters.hits) and (hits == Hits.hit_or_kill and filters.hits == Hits.miss):
			return -1
		else:
			score += 1

	return score


func get_key_point(val: String) -> float:
	var idx = key_points.values.find(val)
	if idx != -1:
		return key_points.times[idx]
	return 0.0


func get_key_points_diff(val1: String, val2: String) -> float:
	var idx1 = key_points.values.find(val1)
	var idx2 = key_points.values.find(val2)
	if idx1 != -1 and idx2 != -1:
		return abs(key_points.times[idx1] - key_points.times[idx2])
	return 0.0
	
