extends ItemBase
class_name ItemBlock

@export var break_time: float = 0.4

@export_group("Lights")
@export var light:bool = false
@export var light_colour:Color
@export var light_energy:float = 1.0
@export var light_size:float = 5.0

@export_group("Sounds")
@export var has_sound:bool = false
@export var sound:AudioStream
@export var sound_distance:float = 10
@export var panning:float = 1
