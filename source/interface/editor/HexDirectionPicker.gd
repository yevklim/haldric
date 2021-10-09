extends Control

onready var animation_player := $NoDirection/AnimationPlayer as UnitAnimationPlayer
var current_animation: UnitAnimation = null

onready var sprite = $NoDirection/Sprite

onready var BtnNW = $NW
onready var BtnN = $N
onready var BtnNE = $NE
onready var NoDirectionBtn = $NoDirection
onready var BtnSW = $SW
onready var BtnS = $S
onready var BtnSE = $SE


func _ready():
	animation_player.sprite_flip_h_setter = funcref(sprite, "set_flip_h")


func pick_direction(direction: String):
	if not current_animation:
		return

	var ctrl = Input.is_key_pressed(KEY_CONTROL)
	var d = Hex.Direction.keys().find(direction)
	if d == -1:
		current_animation.directions.clear()
	elif ctrl:
		if not current_animation.directions.has(d):
			current_animation.directions.append(d)
		else:
			current_animation.directions.erase(d)
		current_animation.directions.sort()
	else:
		current_animation.set_direction(d)

	BtnNW.pressed = current_animation.directions.has(Hex.Direction.NW)
	BtnN.pressed = current_animation.directions.has(Hex.Direction.N)
	BtnNE.pressed = current_animation.directions.has(Hex.Direction.NE)
	NoDirectionBtn.pressed = current_animation.directions.empty()
	BtnSW.pressed = current_animation.directions.has(Hex.Direction.SW)
	BtnS.pressed = current_animation.directions.has(Hex.Direction.S)
	BtnSE.pressed = current_animation.directions.has(Hex.Direction.SE)
