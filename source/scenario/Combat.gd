extends Node
class_name Combat

signal finished()

signal attacker_hit(attacker, defender)
signal attacker_missed(attacker, defender)
signal defender_hit(attacker, defender)
signal defender_missed(attacker, defender)

export var min_death_xp := 4
export var death_xp := 8

export var combat_speed := 1.0
export var combat_default_length := 0.6

onready var tween := Tween.new()


func _ready() -> void:
	tween.name = "Tween"
	add_child(tween)


func start(attacker: CombatContext, defender: CombatContext) -> void:
	randomize()

	var opponent := {}

	opponent[attacker] = defender
	opponent[defender] = attacker

	attacker.unit.look_toward_cell(defender.location.cell)
	defender.unit.look_toward_cell(attacker.location.cell)

	var queue := _make_attack_queue(attacker, defender)

	while queue:
		var current = queue.pop_front()
		var other = opponent[current]
		var origin = current.unit.global_position

		current.unit.type.anim.filters.set_event(UnitAnimation.Events.attack)
		other.unit.type.anim.filters.set_event(UnitAnimation.Events.defend)

		if current == attacker:
			current.unit.type.anim.filters.set_primary_attack_filter(current._attack)
			other.unit.type.anim.filters.set_secondary_attack_filter(other._attack)

		elif current == defender:
			current.unit.type.anim.filters.set_secondary_attack_filter(current._attack)
			other.unit.type.anim.filters.set_primary_attack_filter(other._attack)

		var strike = _strike(current, other, attacker, defender)

		var current_anim = current.unit.type.anim.choose_animation()
		var other_anim = other.unit.type.anim.choose_animation()

		current.unit.type.anim.play_unit_animation(current_anim)

		var zero_point: float = current_anim.get_key_point("zero_point")
		var missile_start: float = current_anim.get_key_point("missile_start")

		if zero_point == 0:
			zero_point = combat_default_length

		if current.category == "melee":
			other.unit.type.anim.play_unit_animation(other_anim)

			_tween_attack(current.unit, other.unit)

			yield(get_tree().create_timer(zero_point), "timeout")

			strike.resume()

			if tween.is_active():
				yield(tween, "tween_completed")

			_tween_retreat(current.unit, origin)
			yield(tween, "tween_completed")

		else:
			if missile_start > 0:
				current._attack.projectile_travel_time = missile_start
			else:
				missile_start = current._attack.projectile_travel_time

			yield(get_tree().create_timer(zero_point - missile_start), "timeout")

			other.unit.type.anim.play_unit_animation(other_anim)

			current.fire(other.location)

			yield(get_tree().create_timer(missile_start), "timeout")

			strike.resume()

			yield(get_tree().create_timer(max(missile_start, combat_default_length)), "timeout")
		
		current.unit.type.anim.filters.event.clear()
		other.unit.type.anim.filters.event.clear()

		current.unit.type.anim.filters.primary_attack_filter.clear()
		other.unit.type.anim.filters.primary_attack_filter.clear()

		current.unit.type.anim.filters.secondary_attack_filter.clear()
		other.unit.type.anim.filters.secondary_attack_filter.clear()

		if other.unit.is_dead():
			current.unit.grant_experience(max(min_death_xp, death_xp * other.unit.type.level))
			current.unit.type.anim.play_unit_animation()
			other.unit.kill()
			emit_signal("finished")
			queue_free()
			return

	attacker.unit.grant_experience(defender.unit.type.level)
	defender.unit.grant_experience(attacker.unit.type.level)

	attacker.unit.type.anim.play_unit_animation()
	defender.unit.type.anim.play_unit_animation()

	emit_signal("finished")
	queue_free()


func _strike(current: CombatContext, other: CombatContext, attacker: CombatContext, defender: CombatContext) -> void:

	var accuracy = 1.0 - other.get_defense_modifier()

	if current.has_attack():
		current.apply_specials(current, other, attacker, defender)
		accuracy = max(accuracy, current.get_accuracy_modifier())

	print(current.to_string())

	if randf() < accuracy:
		var other_will_survive = other.unit.health.value - other.unit.calculate_damage(current.damage, current.damage_type) > 0
		current.unit.type.anim.filters.set_hits(UnitAnimation.Hits.hit if other_will_survive else UnitAnimation.Hits.kill)

		yield()

		other.unit.hurt(current.damage, current.damage_type)
		if current == attacker:
			emit_signal("attacker_hit", attacker, defender)
		else:
			emit_signal("defender_hit", attacker, defender)
	else:
		current.unit.type.anim.filters.set_hits(UnitAnimation.Hits.miss)

		yield()

		get_tree().call_group("GameUI", "spawn_popup_label", other.unit.global_position + Vector2(0, -48), "Miss!", 16, Color.gray, 100, 0.2)
		if current == attacker:
			emit_signal("attacker_missed", attacker, defender)
		else:
			emit_signal("defender_missed", attacker, defender)

	current.reset()


func _tween_attack(attacker: Unit, defender: Unit) -> void:
	var attack_vector = defender.global_position - attacker.global_position
	var target_position = attacker.global_position + attack_vector * 0.6
	tween.interpolate_property(attacker.type.sprite, "global_position", attacker.type.global_position, target_position, combat_default_length, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()


func _tween_retreat(unit: Unit, origin: Vector2) -> void:
	tween.interpolate_property(unit.type.sprite, "global_position", unit.type.sprite.global_position, unit.global_position, combat_default_length, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()


func _make_attack_queue(attacker: CombatContext, defender: CombatContext) -> Array:
	var queue = []

	for i in max(attacker.strikes, defender.strikes):
		if attacker.strikes > i:
			queue.append(attacker)
		if defender.strikes > i:
			queue.append(defender)

	return queue
