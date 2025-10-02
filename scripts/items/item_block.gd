extends ItemBase
class_name ItemBlock

@export var break_time: float = 0.4

@export_group("Additive")

@export_subgroup("Lights")
@export var light:bool = false
@export var light_colour:Color
@export var light_energy:float = 1.0
@export var light_size:float = 5.0

@export_subgroup("Ambient Sounds")
@export var has_sound:bool = false
@export var sound:AudioStream
@export var sound_distance:float = 10
@export var panning:float = 1

@export_group("Block Sounds")

@export_subgroup("Break")
@export var block_sound:AudioStream
@export_range(-80,80) var volume = 0.0
@export_range(-0.01,4,0.01) var pitch = 1.0
@export_range(0,4096) var max_distance = 20
@export_range(0,3) var panning_strength = 3

@export_subgroup("Walk")
@export var walk_block_sound:AudioStream
@export_range(-80,80) var walk_volume = 0.0
@export_range(-0.01,4,0.01) var walk_pitch = 1.0
@export_range(0,4096) var walk_max_distance = 10
@export_range(0,3) var walk_panning_strength = 3
