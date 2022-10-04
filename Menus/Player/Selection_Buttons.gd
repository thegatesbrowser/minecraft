extends CenterContainer

onready var grass = $HBoxContainer/Grass
onready var dirt = $HBoxContainer/Dirt
onready var stone = $HBoxContainer/Stone
onready var glass = $HBoxContainer/Glass
onready var log1 = $HBoxContainer/Log1
onready var log2 = $HBoxContainer/Log2
onready var wood1 = $HBoxContainer/Wood
onready var wood2 = $HBoxContainer/Wood2
onready var leaf1 = $HBoxContainer/Leaf1
onready var leaf2 = $HBoxContainer/Leaf2

enum {GRASS, DIRT, STONE, GLASS, LOG1, WOOD1, LOG2, WOOD2, LEAF1, LEAF2}

var current_key = WOOD1
var buttons
var keys


func _ready():
	buttons = [grass, dirt, stone, glass, log1, wood1, log2, wood2, leaf1, leaf2]
	keys = [WorldGen.GRASS, WorldGen.DIRT, WorldGen.STONE, WorldGen.GLASS, WorldGen.LOG1, \
		WorldGen.WOOD1, WorldGen.LOG2, WorldGen.WOOD2, WorldGen.LEAVES1, WorldGen.LEAVES2]


func _input(_event):
	if Input.is_action_just_pressed("Scroll_Up"):
		if current_key == GRASS:
			current_key = LEAF2
		else:
			current_key -= 1
		_unpress_all()
		_press_key(current_key)
	
	elif Input.is_action_just_pressed("Scroll_Down"):
		if current_key == LEAF2:
			current_key = GRASS
		else:
			current_key += 1
		_unpress_all()
		_press_key(current_key)


func _unpress_all():
	grass.pressed = false
	dirt.pressed = false
	stone.pressed = false
	glass.pressed = false
	log1.pressed = false
	log2.pressed = false
	wood1.pressed = false
	wood2.pressed = false
	leaf1.pressed = false
	leaf2.pressed = false


func _press_key(i):
	buttons[i].pressed = true
	Globals.current_block = keys[i]
	current_key = i


func _on_Grass_pressed():
	_unpress_all()
	_press_key(GRASS)


func _on_Dirt_pressed():
	_unpress_all()
	_press_key(DIRT)


func _on_Stone_pressed():
	_unpress_all()
	_press_key(STONE)


func _on_Glass_pressed():
	_unpress_all()
	_press_key(GLASS)


func _on_Log1_pressed():
	_unpress_all()
	_press_key(LOG1)


func _on_Log2_pressed():
	_unpress_all()
	_press_key(LOG2)


func _on_Wood_pressed():
	_unpress_all()
	_press_key(WOOD1)


func _on_Wood2_pressed():
	_unpress_all()
	_press_key(WOOD2)


func _on_Leaf1_pressed():
	_unpress_all()
	_press_key(LEAF1)


func _on_Leaf2_pressed():
	_unpress_all()
	_press_key(LEAF2)
